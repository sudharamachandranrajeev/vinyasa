/// Fit before you buy: where a new piece would go in a room, what each
/// place costs the room's score, and whether the piece gets through the
/// door at all. Every place is checked by the same rules as the analysis.
library;

import 'dart:isolate';
import 'dart:math' as math;

import 'analysis.dart';
import 'catalog.dart';
import 'space.dart';

/// Clear height assumed for a door; rooms do not record their doors' heights.
const doorHeight = 2000;

/// One place the new piece could go.
class FitSpot {
  const FitSpot(this.report, this.item, this.delta);

  /// The room with the piece in this place, analysed.
  final Report report;
  final Item item;

  /// How much worse the room scores with it here (cost, lower is better).
  final double delta;

  Room get room => report.room;

  /// What the rules found about the new piece itself.
  List<Finding> get own => [
    for (final f in report.findings)
      if (f.items.contains(item.id)) f,
  ];
}

class FitResult {
  const FitResult(this.before, this.spots, this.door);
  final Report before;

  /// Best first; empty when it does not fit anywhere.
  final List<FitSpot> spots;
  final DoorFit door;
}

/// Whether a piece gets into the room through its widest doorway.
class DoorFit {
  const DoorFit(this.fits, this.text);
  final bool fits;
  final String text;
}

/// The door check for a piece of [w]×[d]×[h]: it goes through on its
/// narrowest side, so its smallest size must pass the door's width and its
/// middle size the height (or the diagonal, tilted).
DoorFit throughDoor(Room room, int w, int d, int h) {
  final ways = [
    for (final o in room.openings)
      if (o.kind.passable) o.width,
  ];
  if (ways.isEmpty) return const DoorFit(true, 'The room has no door on the plan, so this was not checked.');
  final door = ways.reduce(math.max);
  final sizes = [w, d, h]..sort();
  final (a, b) = (sizes[0], sizes[1]);
  final diagonal = math.sqrt(door * door + doorHeight * doorHeight).floor();
  if (a > door) {
    return DoorFit(
      false,
      'Its narrowest side is $a mm, wider than the widest doorway ($door mm). It will not go through unless '
      'it comes apart.',
    );
  }
  if (b <= doorHeight) {
    return DoorFit(
      true,
      'Goes through the $door mm doorway on its $a mm side. Measure halls, stairs and turns on the way too.',
    );
  }
  if (b <= diagonal) {
    return DoorFit(
      true,
      'Goes through the $door mm doorway on its $a mm side if tilted: $b mm is taller than a $doorHeight mm '
      'door but within its diagonal. Measure halls, stairs and turns on the way too.',
    );
  }
  return DoorFit(false, 'At $b mm it is too long to tilt through a $door × $doorHeight mm doorway.');
}

/// Runs [findFit] off the UI thread.
Future<FitResult> findFitInBackground(Room room, Item item) => Isolate.run(() => findFit(room, item));

/// Up to [count] good places for [item] in [room], at least 700 mm apart.
FitResult findFit(Room room, Item item, {int count = 3}) {
  final before = analyse(room);
  final door = throughDoor(room, item.w, item.d, item.h > 0 ? item.h : item.spec.h);
  final taken = [
    if (item.spec.blocks)
      for (final i in room.items)
        if (i.spec.blocks) i.box,
    for (final o in room.openings) ?doorSwing(room, o),
  ];

  bool free(Item c) =>
      c.x >= 0 &&
      c.y >= 0 &&
      c.box.right <= room.width &&
      c.box.bottom <= room.depth &&
      !taken.any((b) => b.overlaps(c.box));

  final candidates = <Item>[];
  // Back against each wall, facing into the room.
  for (final wall in Wall.values) {
    final turned = item.copyWith(rot: wall.index);
    final along = wall.horizontal ? room.width - turned.footW : room.depth - turned.footD;
    for (var at = 0; at <= along; at += 100) {
      final (x, y) = switch (wall) {
        Wall.top => (at, 0),
        Wall.bottom => (at, room.depth - turned.footD),
        Wall.left => (0, at),
        Wall.right => (room.width - turned.footW, at),
      };
      candidates.add(turned.copyWith(x: x, y: y));
    }
  }
  // Out in the room, for pieces that need no wall.
  if (item.spec.wall == WallNeed.none) {
    for (var rot = 0; rot < 4; rot++) {
      final turned = item.copyWith(rot: rot);
      for (var y = 300; y + turned.footD <= room.depth - 300; y += 300) {
        for (var x = 300; x + turned.footW <= room.width - 300; x += 300) {
          candidates.add(turned.copyWith(x: x, y: y));
        }
      }
    }
  }

  final spots = <FitSpot>[
    for (final c in candidates)
      if (free(c))
        () {
          final report = analyse(room.copyWith(items: [...room.items, c]));
          return FitSpot(report, c, report.cost - before.cost);
        }(),
  ]..sort((a, b) => a.delta.compareTo(b.delta));

  final best = <FitSpot>[];
  for (final s in spots) {
    if (best.length == count) break;
    final apart = best.every(
      (b) =>
          math.sqrt(
            math.pow(b.item.box.cx - s.item.box.cx, 2) + math.pow(b.item.box.cy - s.item.box.cy, 2),
          ) >=
          700,
    );
    if (apart) best.add(s);
  }
  return FitResult(before, best, door);
}
