/// The planner: finds a better arrangement of a room by simulated annealing
/// over the rules. A move is kept when it lowers the weighted penalty of the
/// findings plus a small cost for every piece moved, so the plan changes
/// only what earns its keep. Things that belong together (a bed and its
/// bedside tables, a desk and its chair) move as one group.
library;

import 'dart:isolate';
import 'dart:math' as math;

import 'analysis.dart';
import 'catalog.dart';
import 'space.dart';

class PlanResult {
  const PlanResult(this.before, this.after);
  final Report before, after;

  Room get room => after.room;
  bool get improved => after.overall > before.overall || after.cost < before.cost - 0.5;
}

/// Runs [arrange] off the UI thread.
Future<PlanResult> arrangeInBackground(Room room, {int seed = 7}) =>
    Isolate.run(() => arrange(room, seed: seed));

/// Cost of having moved things from [from] to [to]: a little for each piece
/// moved, more for longer moves and turns.
double moveCost(Room from, Room to) {
  var cost = 0.0;
  for (final a in from.items) {
    final b = to.item(a.id);
    if (b == null) continue;
    final d = math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
    if (d < 1 && a.rot == b.rot) continue;
    cost += 1.5 + d / 1500 + (a.rot == b.rot ? 0 : 0.8) + (a.spec.heavy ? 1 : 0);
  }
  return cost;
}

/// Which items travel with which: bedside tables with the nearest bed, a
/// desk chair with its desk, dining chairs with the table, and a rug with
/// what stands on it.
Map<String, List<String>> groupsOf(Room room) {
  final groups = <String, List<String>>{};
  final anchors = room.items
      .where((i) => i.spec.has('bed') || i.spec.has('desk') || i.spec.has('dining') || i.spec.has('sofa'))
      .toList();
  for (final i in room.items) {
    if (anchors.contains(i)) continue;
    final reach = switch (i.kind) {
      'nightstand' => 300,
      'office_chair' || 'chair' => 900,
      'rug' => 0,
      'coffee_table' => 700,
      _ => -1,
    };
    if (reach < 0) continue;
    Item? best;
    var bestGap = 1 << 30;
    for (final a in anchors) {
      final gap = a.box.gap(i.box);
      final fits = switch (i.kind) {
        'nightstand' => a.spec.has('bed'),
        'office_chair' => a.spec.has('desk'),
        'chair' => a.spec.has('dining') || a.spec.has('desk'),
        'coffee_table' => a.spec.has('sofa'),
        _ => true,
      };
      if (!fits) continue;
      // A rug goes with what stands on it; anything else only when it is
      // beside its anchor, not overlapping it (that needs fixing first).
      if ((i.kind == 'rug') != (a.box.overlapArea(i.box) > 2500)) continue;
      if (gap <= reach && gap < bestGap) {
        best = a;
        bestGap = gap;
      }
    }
    if (best != null) (groups[best.id] ??= []).add(i.id);
  }
  return groups;
}

/// The room with [anchor] moved to ([x], [y]) turned to [rot], its group
/// moving and turning with it about its centre.
Room moveGroup(Room room, Map<String, List<String>> groups, Item anchor, int x, int y, int rot) {
  final turns = (rot - anchor.rot) % 4;
  final moved = anchor.copyWith(x: x, y: y, rot: rot);
  final oldC = (anchor.box.cx, anchor.box.cy), newC = (moved.box.cx, moved.box.cy);
  final out = <String, Item>{anchor.id: moved};
  for (final id in groups[anchor.id] ?? const <String>[]) {
    final m = room.item(id);
    if (m == null || m.fixed) continue;
    var dx = m.box.cx - oldC.$1, dy = m.box.cy - oldC.$2;
    for (var t = 0; t < turns; t++) {
      (dx, dy) = (-dy, dx); // a quarter turn clockwise, y pointing down
    }
    final turned = m.copyWith(rot: m.rot + turns);
    out[id] = turned.copyWith(
      x: (newC.$1 + dx - turned.footW / 2).round(),
      y: (newC.$2 + dy - turned.footD / 2).round(),
    );
  }
  return room.copyWith(items: [for (final i in room.items) out[i.id] ?? i]);
}

/// Whether every moved piece of a group still stands inside the walls.
bool _fits(Room room) => room.items.every(
  (i) => !i.spec.blocks || (i.x >= 0 && i.y >= 0 && i.box.right <= room.width && i.box.bottom <= room.depth),
);

bool _similar(int a, int b) => a >= b * 0.4 && a <= b * 2.5;

int _snap(num v) => (v / 50).round() * 50;

/// Keeps a placed item inside the walls.
(int, int) _inside(Room room, int x, int y, int fw, int fd) =>
    (x.clamp(0, math.max(0, room.width - fw)), y.clamp(0, math.max(0, room.depth - fd)));

/// A better arrangement of [room]. Deterministic for a given [seed].
PlanResult arrange(Room room, {int seed = 7, int iterations = 1800}) {
  final rnd = math.Random(seed);
  final before = analyse(room);
  final groups = groupsOf(room);
  final grouped = {for (final g in groups.values) ...g};
  // Items placed on their own: not fixed and not carried by an anchor.
  final movable = [
    for (final i in room.items)
      if (!i.fixed && !grouped.contains(i.id)) i.id,
  ];
  if (movable.isEmpty) return PlanResult(before, before);

  double costOfRoom(Room r) => analyse(r).cost + moveCost(room, r);

  var current = room, currentCost = costOfRoom(room);
  var best = current, bestCost = currentCost;
  const t0 = 18.0, t1 = 0.25;

  for (var k = 0; k < iterations; k++) {
    final t = t0 * math.pow(t1 / t0, k / iterations);
    final item = current.item(movable[rnd.nextInt(movable.length)])!;
    final candidate = _neighbour(current, groups, grouped, item, rnd);
    if (candidate == null || !_fits(candidate)) continue;
    final cost = costOfRoom(candidate);
    final delta = cost - currentCost;
    if (delta < 0 || rnd.nextDouble() < math.exp(-delta / t)) {
      current = candidate;
      currentCost = cost;
      if (cost < bestCost) {
        best = candidate;
        bestCost = cost;
      }
    }
  }

  // Put back whatever moved without helping, so the plan stays short.
  for (final id in movable) {
    final was = room.item(id)!, now = best.item(id)!;
    if (was.x == now.x && was.y == now.y && was.rot == now.rot) continue;
    final back = moveGroup(best, groups, now, was.x, was.y, was.rot);
    final cost = costOfRoom(back);
    if (cost <= bestCost + 0.01) {
      best = back;
      bestCost = cost;
    }
  }
  final after = analyse(best);
  return after.cost < before.cost ? PlanResult(before, after) : PlanResult(before, before);
}

Room? _neighbour(
  Room room,
  Map<String, List<String>> groups,
  Set<String> grouped,
  Item item,
  math.Random rnd,
) {
  final spec = item.spec;
  switch (rnd.nextInt(spec.wall == WallNeed.none ? 4 : 6)) {
    case 0: // nudge
      final step = 100 + rnd.nextInt(700);
      final (x, y) = _inside(
        room,
        _snap(item.x + (rnd.nextBool() ? step : -step) * rnd.nextInt(2)),
        _snap(item.y + (rnd.nextBool() ? step : -step) * rnd.nextInt(2)),
        item.footW,
        item.footD,
      );
      return moveGroup(room, groups, item, x, y, item.rot);
    case 1: // turn in place
      final rot = (item.rot + (rnd.nextBool() ? 1 : 3)) % 4;
      final turned = item.copyWith(rot: rot);
      final (x, y) = _inside(
        room,
        _snap(item.box.cx - turned.footW / 2),
        _snap(item.box.cy - turned.footD / 2),
        turned.footW,
        turned.footD,
      );
      return moveGroup(room, groups, item, x, y, rot);
    case 2: // swap with a similar piece
      final others = [
        for (final o in room.items)
          if (o.id != item.id && !o.fixed && !grouped.contains(o.id) && _similar(o.box.area, item.box.area))
            o,
      ];
      if (others.isEmpty) return null;
      final o = others[rnd.nextInt(others.length)];
      final (ax, ay) = _inside(
        room,
        _snap(o.box.cx - item.footW / 2),
        _snap(o.box.cy - item.footD / 2),
        item.footW,
        item.footD,
      );
      final (bx, by) = _inside(
        room,
        _snap(item.box.cx - o.footW / 2),
        _snap(item.box.cy - o.footD / 2),
        o.footW,
        o.footD,
      );
      final r1 = moveGroup(room, groups, item, ax, ay, item.rot);
      return moveGroup(r1, groups, r1.item(o.id)!, bx, by, o.rot);
    case 3: // somewhere else entirely, any way round
      final rot = rnd.nextInt(4);
      final turned = item.copyWith(rot: rot);
      final (x, y) = _inside(
        room,
        _snap(rnd.nextInt(math.max(1, room.width - turned.footW + 1))),
        _snap(rnd.nextInt(math.max(1, room.depth - turned.footD + 1))),
        turned.footW,
        turned.footD,
      );
      return moveGroup(room, groups, item, x, y, rot);
    default: // back against a wall, facing into the room
      final wall = Wall.values[rnd.nextInt(4)];
      final rot = wall.index; // rot n puts the back on wall n
      final turned = item.copyWith(rot: rot);
      final along = wall.horizontal ? room.width - turned.footW : room.depth - turned.footD;
      // Corners are popular: a third of the time, go to one end.
      final at = switch (rnd.nextInt(3)) {
        0 => 0,
        1 => math.max(0, along),
        _ => _snap(rnd.nextInt(math.max(1, along + 1))),
      };
      final (x, y) = switch (wall) {
        Wall.top => (at, 0),
        Wall.bottom => (at, room.depth - turned.footD),
        Wall.left => (0, at),
        Wall.right => (room.width - turned.footW, at),
      };
      final (cx, cy) = _inside(room, x, y, turned.footW, turned.footD);
      return moveGroup(room, groups, item, cx, cy, rot);
  }
}
