/// Vinyasa's rules. Each looks at one thing in a room and says what is wrong
/// and how to fix it. The numbers are gathered in [Limits], with where each
/// comes from in docs/rules.md, so a better source changes one line.
///
/// Policy when rules disagree: safety and access first, then comfort, then
/// looks, then Vaastu. In practice that is the categories' weights and the
/// severities: access rules are "must", Vaastu is "nice" in Gentle mode and
/// "should" in Strict mode, never "must".
library;

import 'dart:math' as math;

import 'analysis.dart';
import 'catalog.dart';
import 'space.dart';

abstract final class Limits {
  /// Main circulation path, and the narrowest usable one.
  static const pathMain = 900;
  static const pathMin = 600;

  /// Wheelchair: clear path (ADA 403.5.1) and turning circle (UK 1500;
  /// ADA 304.3 asks 1525, which the 50 mm grid cannot tell apart).
  static const pathWheelchair = 915;
  static const turning = 1500;

  /// Clear opening of a door a wheelchair passes (ADA 404.2.3: 32 in).
  static const doorWheelchair = 815;

  /// Beside a bed to get in and make it; beside one for a wheelchair transfer.
  static const bedSide = 600;
  static const bedSideWheelchair = 915;

  /// A wall-hugging item counts as against the wall within this gap.
  static const againstWall = 150;

  /// Gap between the sofa's front and the coffee table (12 to 18 in).
  static const coffeeMin = 300, coffeeMax = 460;

  /// Farthest two seats in a group can be and still talk (8 ft).
  static const talkMax = 2440;

  /// A lamp or nightstand counts as within reach of a bed this far out.
  static const bedReach = 600;

  /// Viewing distance as multiples of the screen diagonal (THX 40° to
  /// SMPTE 30°, with slack either side).
  static const tvNear = 1.0, tvFar = 2.6;

  /// Kitchen work triangle (NKBA): each leg 4 to 9 ft, all three at most 26 ft.
  static const legMin = 1220, legMax = 2740, triangleMax = 7920;

  /// Counter between hob and sink: the sink's smaller landing (NKBA 18 in).
  static const hobSinkGap = 460;

  /// Floor that should stay free in rooms people live in.
  static const freeFloor = 0.35;

  /// Shop entrance decompression zone (Underhill: 1.5 to 4.5 m).
  static const decompression = 1500;

  /// Office floor area per person below which it feels cramped (high-density
  /// offices run 8 to 10 m², standard ones 10 to 15).
  static const officePerPerson = 8.0;

  /// Tall furniture that can tip over.
  static const tall = 1500;
}

// ---- wording ----

/// "450 mm" under a metre, "1.2 m" above.
String mm(num v) =>
    v.abs() < 1000 ? '${v.round()} mm' : '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)} m';

String zoneName(Dir8? d) => d == null ? 'the centre' : 'the ${d.label.toLowerCase()}';

Dir8? zoneOf(Room r, Item i) => r.dirOf(i.box.cx, i.box.cy);

Severity _vaastu(Room r) => r.vaastu == VaastuMode.strict ? Severity.should : Severity.nice;

/// The distance from an item's back to the wall behind it.
int backGap(Room r, Item i) {
  final b = i.box;
  return switch (i.backWall) {
    Wall.top => b.y,
    Wall.right => r.width - b.right,
    Wall.bottom => r.depth - b.bottom,
    Wall.left => b.x,
  };
}

/// Distance from the box to the nearest wall, and which wall.
(int, Wall) nearestWall(Room r, Box b) {
  final gaps = {
    Wall.top: b.y,
    Wall.right: r.width - b.right,
    Wall.bottom: r.depth - b.bottom,
    Wall.left: b.x,
  };
  final best = gaps.entries.reduce((a, c) => c.value < a.value ? c : a);
  return (best.value, best.key);
}

double _dist(Box a, Box b) => math.sqrt(math.pow(a.cx - b.cx, 2) + math.pow(a.cy - b.cy, 2));

const _living = {RoomType.living, RoomType.studio};
const _sleeping = {RoomType.bedroom, RoomType.kidsRoom, RoomType.guest, RoomType.studio};
const _homeRooms = {
  RoomType.bedroom,
  RoomType.kidsRoom,
  RoomType.living,
  RoomType.study,
  RoomType.guest,
  RoomType.studio,
  RoomType.dining,
};

/// Items whose use matters most: they must be reachable on the main path.
const anchorTags = {'bed', 'sofa', 'desk', 'counter', 'dining', 'storage', 'cook', 'water', 'worship'};

bool _anchor(Item i) => i.spec.tags.any(anchorTags.contains);

// ---- the rules ----

final allRules = <Rule>[
  // Space
  Rule('inside-room', Category.efficiency, (ctx) sync* {
    final r = ctx.room;
    for (final i in ctx.blocking) {
      final b = i.box;
      if (b.x < 0 || b.y < 0 || b.right > r.width || b.bottom > r.depth) {
        yield Finding(
          rule: 'inside-room',
          category: Category.efficiency,
          severity: Severity.must,
          title: '${i.name} does not fit where it is',
          detail: 'Part of it is beyond the walls on the plan.',
          fix: 'Move it inside the room, or check the room’s and the item’s measurements.',
          items: [i.id],
        );
      }
    }
  }),
  Rule('no-overlap', Category.efficiency, (ctx) sync* {
    final list = ctx.blocking.toList();
    for (var a = 0; a < list.length; a++) {
      for (var b = a + 1; b < list.length; b++) {
        final shared = list[a].box.overlapArea(list[b].box);
        if (shared <= 2500) continue; // 50 × 50 mm: drawing slack
        yield Finding(
          rule: 'no-overlap',
          category: Category.efficiency,
          severity: Severity.must,
          title: '${list[a].name} and ${list[b].name} overlap',
          detail: 'Two things cannot stand in the same place.',
          fix: 'Move one of them.',
          items: [list[a].id, list[b].id],
        );
      }
    }
  }),
  Rule('door-swing-clear', Category.efficiency, (ctx) sync* {
    final r = ctx.room;
    for (final o in r.openings) {
      final swing = doorSwing(r, o);
      if (swing == null) continue;
      for (final i in ctx.blocking) {
        if (i.box.overlapArea(swing) <= 2500) continue;
        yield Finding(
          rule: 'door-swing-clear',
          category: Category.efficiency,
          severity: Severity.must,
          title: '${i.name} is in the way of the door',
          detail: 'The door cannot open fully: its leaf sweeps ${mm(o.width)} into the room.',
          fix: 'Move it out of the door’s swing, or rehang the door to open the other way.',
          items: [i.id],
        );
      }
    }
  }),
  Rule('window-not-blocked', Category.efficiency, (ctx) sync* {
    final r = ctx.room;
    for (final o in r.openings.where((o) => o.kind == OpeningKind.window)) {
      final strip = openingBox(r, o, thick: 300);
      for (final i in ctx.blocking.where((i) => i.h > math.max(o.sill, 900) + 100)) {
        if (i.box.overlapArea(strip) == 0) continue;
        yield Finding(
          rule: 'window-not-blocked',
          category: Category.efficiency,
          severity: Severity.should,
          title: '${i.name} covers a window',
          detail: 'At ${mm(i.h)} tall it stands above the ${mm(o.sill)} sill and cuts daylight and air.',
          fix: 'Keep tall pieces off window walls; put low furniture (under the sill) there instead.',
          items: [i.id],
        );
      }
    }
  }),
  Rule('clear-front', Category.efficiency, (ctx) sync* {
    for (final i in ctx.room.items.where((i) => i.spec.front > 0 && !i.spec.has('bed'))) {
      final zone = i.frontZone(i.spec.front);
      final share = ctx.grid.clearShare(zone);
      if (share >= 0.85) continue;
      final heavy = i.spec.has('storage') || i.spec.has('kitchen') || i.spec.has('appliance');
      yield Finding(
        rule: 'clear-front',
        category: Category.efficiency,
        severity: heavy ? Severity.must : Severity.should,
        title: 'Not enough room in front of the ${i.name.toLowerCase()}',
        detail:
            'It needs ${mm(i.spec.front)} clear in front to be used (doors, drawers, a chair or a person); '
            'only ${(share * 100).round()}% of that is free.',
        fix: 'Turn it to face open floor, or move what is in front of it.',
        items: [i.id],
        weight: 1 - share,
      );
    }
  }),
  Rule('clear-sides', Category.efficiency, (ctx) sync* {
    for (final i in ctx.room.items.where((i) => i.spec.side > 0 && !i.spec.has('bed'))) {
      final shares = [for (final z in i.sideZones(i.spec.side)) ctx.grid.clearShare(z)];
      final worst = shares.reduce(math.min);
      if (worst >= 0.7) continue;
      yield Finding(
        rule: 'clear-sides',
        category: Category.efficiency,
        severity: Severity.should,
        title: 'Chairs at the ${i.name.toLowerCase()} cannot pull out',
        detail: 'Sitting down and getting up needs about ${mm(i.spec.side)} behind each chair.',
        fix: 'Bring the table away from the wall, or use a bench on the wall side.',
        items: [i.id],
        weight: 1 - worst,
      );
    }
  }),
  Rule('against-wall', Category.efficiency, (ctx) sync* {
    final r = ctx.room;
    for (final i in r.items.where((i) => i.spec.wall != WallNeed.none)) {
      final gap = backGap(r, i);
      if (gap <= Limits.againstWall) continue;
      final must = i.spec.wall == WallNeed.must;
      yield Finding(
        rule: 'against-wall',
        category: Category.efficiency,
        severity: must ? Severity.should : Severity.nice,
        title: '${i.name} stands away from the wall',
        detail: must
            ? 'Its back is ${mm(gap)} from the wall, so the floor behind it is wasted and it may tip.'
            : 'A bed’s headboard or a sofa’s back against a wall feels settled; this one is ${mm(gap)} out.',
        fix: 'Push it back against the wall it backs on to.',
        items: [i.id],
        weight: math.min(1, gap / 1000),
      );
    }
  }),
  Rule('free-floor', Category.efficiency, types: _homeRooms, (ctx) sync* {
    final share = ctx.grid.freeShare;
    if (share >= Limits.freeFloor) return;
    yield Finding(
      rule: 'free-floor',
      category: Category.efficiency,
      severity: Severity.should,
      title: 'The floor is crowded',
      detail:
          'Only ${(share * 100).round()}% of the floor is open. Rooms feel calm with about a third or more left free.',
      fix: 'Take out what is rarely used, go vertical with tall storage on one wall, or choose smaller pieces.',
      weight: (Limits.freeFloor - share) / Limits.freeFloor + 0.3,
    );
  }),
  Rule('clear-entrance', Category.efficiency, (ctx) sync* {
    final r = ctx.room;
    for (final o in r.openings.where((o) => o.kind.passable)) {
      final strip = openingBox(r, o, thick: 900);
      final share = ctx.grid.clearShare(strip);
      if (share >= 0.8) continue;
      yield Finding(
        rule: 'clear-entrance',
        category: Category.efficiency,
        severity: Severity.should,
        title:
            'Something crowds the ${o.kind.label.toLowerCase()} on the ${r.wallDir(o.wall).label.toLowerCase()} wall',
        detail: 'The first ${mm(900)} inside a doorway should stay clear for stepping in and turning.',
        fix: 'Move furniture out of the doorway’s landing.',
        items: [
          for (final i in ctx.blocking)
            if (i.box.overlaps(strip)) i.id,
        ],
        weight: 1 - share,
      );
    }
  }),

  // Access
  Rule('path-main', Category.accessibility, (ctx) sync* {
    if (ctx.room.openings.every((o) => !o.kind.passable)) return;
    final wide = ctx.grid.reachable(Limits.pathMain);
    final narrow = ctx.grid.reachable(Limits.pathMin);
    final half = Limits.pathMain ~/ 2;
    for (final i in ctx.room.items.where(_anchor)) {
      final zone = i.frontZone(math.max(i.spec.front, 300)).inflate(half);
      if (ctx.grid.touches(wide, zone)) continue;
      final some = ctx.grid.touches(
        narrow,
        i.frontZone(math.max(i.spec.front, 300)).inflate(Limits.pathMin ~/ 2),
      );
      yield Finding(
        rule: some ? 'path-main' : 'path-min',
        category: Category.accessibility,
        severity: some ? Severity.should : Severity.must,
        title: some
            ? 'The way to the ${i.name.toLowerCase()} is tight'
            : 'The ${i.name.toLowerCase()} cannot be reached',
        detail: some
            ? 'The route from the door narrows below ${mm(Limits.pathMain)}, the width of a comfortable walkway.'
            : 'No route at least ${mm(Limits.pathMin)} wide leads from the door to it.',
        fix: 'Open a straight walkway from the door to it: move or shrink what pinches the route.',
        items: [i.id],
      );
    }
  }),
  Rule('wheelchair-path', Category.accessibility, (ctx) sync* {
    final r = ctx.room;
    if (!r.occupants.wheelchair || r.openings.every((o) => !o.kind.passable)) return;
    final mask = ctx.grid.reachable(Limits.pathWheelchair);
    for (final i in r.items.where(_anchor)) {
      final zone = i.frontZone(math.max(i.spec.front, 300)).inflate(Limits.pathWheelchair ~/ 2);
      if (ctx.grid.touches(mask, zone)) continue;
      yield Finding(
        rule: 'wheelchair-path',
        category: Category.accessibility,
        severity: Severity.must,
        title: 'A wheelchair cannot reach the ${i.name.toLowerCase()}',
        detail: 'A wheelchair needs a clear route of ${mm(Limits.pathWheelchair)} from the door.',
        fix: 'Widen the route: move furniture to the walls and keep the middle open.',
        items: [i.id],
      );
    }
  }),
  Rule('turning-space', Category.accessibility, (ctx) sync* {
    final r = ctx.room;
    if (!r.occupants.wheelchair) return;
    final spot = ctx.grid.widestSpot(within: ctx.grid.reachable(Limits.pathWheelchair));
    if (spot.diameter >= Limits.turning) return;
    yield Finding(
      rule: 'turning-space',
      category: Category.accessibility,
      severity: Severity.must,
      title: 'No room to turn a wheelchair',
      detail:
          'The widest open spot is ${mm(spot.diameter)} across; turning needs a ${mm(Limits.turning)} circle.',
      fix: 'Clear a ${mm(Limits.turning)} circle, usually in the middle or by the bed or desk.',
      weight: (Limits.turning - spot.diameter) / Limits.turning + 0.3,
    );
  }),
  Rule('door-width', Category.accessibility, (ctx) sync* {
    final r = ctx.room;
    if (!r.occupants.wheelchair) return;
    for (final o in r.openings.where((o) => o.kind.passable && o.width < Limits.doorWheelchair + 50)) {
      yield Finding(
        rule: 'door-width',
        category: Category.accessibility,
        severity: Severity.should,
        title: 'The ${o.kind.label.toLowerCase()} is narrow for a wheelchair',
        detail:
            'Its ${mm(o.width)} frame leaves less than the ${mm(Limits.doorWheelchair)} clear a wheelchair needs.',
        fix: 'Swing-clear (offset) hinges add about 50 mm; removing the door or a wider frame adds more.',
      );
    }
  }),
  Rule('bed-side', Category.accessibility, (ctx) sync* {
    final r = ctx.room;
    for (final bed in ctx.tagged('bed')) {
      final sides = bed.sideZones(r.occupants.wheelchair ? Limits.bedSideWheelchair : Limits.bedSide);
      final open = [for (final z in sides) ctx.grid.clearShare(z) >= 0.8];
      final wide = bed.w >= 1300;
      if (r.occupants.wheelchair && !open.contains(true)) {
        yield Finding(
          rule: 'bed-side',
          category: Category.accessibility,
          severity: Severity.must,
          title: 'No wheelchair transfer space beside the ${bed.name.toLowerCase()}',
          detail: 'One side of the bed needs ${mm(Limits.bedSideWheelchair)} clear along its length.',
          fix: 'Move the bed so one long side faces open floor.',
          items: [bed.id],
        );
      } else if (!open.contains(true)) {
        yield Finding(
          rule: 'bed-side',
          category: Category.accessibility,
          severity: Severity.should,
          title: 'The ${bed.name.toLowerCase()} is boxed in',
          detail: 'Neither side has ${mm(Limits.bedSide)} clear to get in and make the bed.',
          fix: 'Leave at least one long side open.',
          items: [bed.id],
        );
      } else if (wide && open.contains(false) && r.occupants.people > 1) {
        yield Finding(
          rule: 'bed-side',
          category: Category.accessibility,
          severity: Severity.nice,
          title: 'Only one side of the ${bed.name.toLowerCase()} is open',
          detail: 'Two sleepers each like their own way in: ${mm(Limits.bedSide)} on both sides.',
          fix: 'Centre the bed on its wall if the room allows.',
          items: [bed.id],
        );
      }
    }
  }),
  Rule('tip-over', Category.accessibility, (ctx) sync* {
    final r = ctx.room;
    for (final i in r.items.where((i) => i.h >= Limits.tall && i.spec.blocks)) {
      if (backGap(r, i) <= Limits.againstWall && !r.occupants.children) continue;
      yield Finding(
        rule: 'tip-over',
        category: Category.accessibility,
        severity: r.occupants.children ? Severity.must : Severity.should,
        title: 'Anchor the ${i.name.toLowerCase()} to the wall',
        detail: 'At ${mm(i.h)} tall it can tip over${r.occupants.children ? ', and children climb' : ''}.',
        fix: 'Stand it against a wall and fix it with an anti-tip strap or bracket.',
        items: [i.id],
      );
    }
  }),
  Rule('trip-rug', Category.accessibility, (ctx) sync* {
    final r = ctx.room;
    if (!r.occupants.elderly && !r.occupants.wheelchair) return;
    for (final rug in ctx.tagged('rug')) {
      yield Finding(
        rule: 'trip-rug',
        category: Category.accessibility,
        severity: Severity.must,
        title: 'Secure or remove the ${rug.name.toLowerCase()}',
        detail: 'Loose rug edges are a leading cause of falls at home and catch wheels.',
        fix: 'Use a low-pile rug with a non-slip underlay and taped edges, or none on walking routes.',
        items: [rug.id],
      );
    }
  }),
  Rule('bed-lamp-reach', Category.accessibility, types: _sleeping, (ctx) sync* {
    final r = ctx.room;
    final lights = [...ctx.tagged('beside-bed'), ...ctx.tagged('light')];
    for (final bed in ctx.tagged('bed')) {
      final lit = [
        for (final z in bed.sideZones(Limits.bedReach)) lights.any((l) => l.box.overlapArea(z) > 0),
      ];
      final needed = bed.w >= 1300 && r.occupants.people > 1 ? lit.every((x) => x) : lit.any((x) => x);
      if (needed) continue;
      yield Finding(
        rule: 'bed-lamp-reach',
        category: Category.accessibility,
        severity: r.occupants.elderly ? Severity.must : Severity.should,
        title: 'No light within reach of the ${bed.name.toLowerCase()}',
        detail: 'Getting up in the dark to find a switch is how many falls at night begin.',
        fix: 'Put a nightstand with a lamp, or a wall light, beside each sleeper, and a night-light on the way out.',
        items: [bed.id],
      );
    }
  }),

  // Comfort
  Rule('desk-window', Category.ergonomics, (ctx) sync* {
    final r = ctx.room;
    final windows = r.openings.where((o) => o.kind == OpeningKind.window).toList();
    if (windows.isEmpty) return;
    for (final desk in ctx.tagged('desk')) {
      // The person sits in front, looking towards the desk's back.
      for (final w in windows) {
        if (w.wall == desk.facesWall) {
          yield Finding(
            rule: 'desk-window',
            category: Category.ergonomics,
            severity: Severity.should,
            title: 'The window is behind you at the ${desk.name.toLowerCase()}',
            detail: 'Daylight from behind reflects off the screen and you shade your own work.',
            fix: 'Turn the desk so the window is to your side (on the left if you write right-handed).',
            items: [desk.id],
          );
          break;
        }
        if (w.wall == desk.backWall) {
          yield Finding(
            rule: 'desk-window',
            category: Category.ergonomics,
            severity: Severity.nice,
            title: 'You face the window at the ${desk.name.toLowerCase()}',
            detail: 'A bright window behind the screen strains the eyes (high contrast), though the view is pleasant.',
            fix: 'Best is the window to one side; otherwise use a sheer blind to soften it.',
            items: [desk.id],
          );
          break;
        }
      }
    }
  }),
  Rule('tv-distance', Category.ergonomics, (ctx) sync* {
    final screens = ctx.tagged('screen').toList();
    if (screens.isEmpty) return;
    for (final seat in ctx.tagged('sofa')) {
      final tv = screens.reduce((a, b) => _dist(seat.box, a.box) < _dist(seat.box, b.box) ? a : b);
      final diagonal = tv.w / 0.87; // a 16:9 screen is 0.87 of its diagonal wide
      final d = _dist(seat.box, tv.box);
      final ratio = d / diagonal;
      if (ratio >= Limits.tvNear && ratio <= Limits.tvFar) continue;
      final near = ratio < Limits.tvNear;
      yield Finding(
        rule: 'tv-distance',
        category: Category.ergonomics,
        severity: Severity.should,
        title: near
            ? 'The ${seat.name.toLowerCase()} is too close to the TV'
            : 'The TV is far from the ${seat.name.toLowerCase()}',
        detail:
            'For a ${(diagonal / 25.4).round()}-inch screen sit about ${mm(diagonal * 1.2)} to ${mm(diagonal * 2.5)} away; '
            'this is ${mm(d)}.',
        fix: near
            ? 'Move the seating back or mount the TV on the far wall.'
            : 'Float the seating forward, off the wall, towards the TV.',
        items: [seat.id, tv.id],
        weight: near ? (Limits.tvNear - ratio) + 0.3 : (ratio - Limits.tvFar) / 2 + 0.3,
      );
    }
  }),
  Rule('seat-faces-focal', Category.ergonomics, types: _living, (ctx) sync* {
    final focal = ctx.tagged('focal').toList();
    if (focal.isEmpty) return;
    for (final seat in ctx.tagged('sofa')) {
      final f = focal.reduce((a, b) => _dist(seat.box, a.box) < _dist(seat.box, b.box) ? a : b);
      final dx = f.box.cx - seat.box.cx, dy = f.box.cy - seat.box.cy;
      final looking = switch (seat.facesWall) {
        Wall.bottom => dy > 0 && dy.abs() >= dx.abs() * 0.6,
        Wall.top => dy < 0 && dy.abs() >= dx.abs() * 0.6,
        Wall.left => dx < 0 && dx.abs() >= dy.abs() * 0.6,
        Wall.right => dx > 0 && dx.abs() >= dy.abs() * 0.6,
      };
      if (looking) continue;
      yield Finding(
        rule: 'seat-faces-focal',
        category: Category.ergonomics,
        severity: Severity.should,
        title: 'The ${seat.name.toLowerCase()} does not face the ${f.name.toLowerCase()}',
        detail: 'Watching sideways strains the neck.',
        fix: 'Turn the main seating to face the focal point; side chairs can angle in.',
        items: [seat.id, f.id],
      );
    }
  }),
  Rule('coffee-gap', Category.ergonomics, (ctx) sync* {
    final tables = ctx.tagged('coffee-table').toList();
    if (tables.isEmpty) return;
    for (final sofa in ctx.tagged('sofa')) {
      final t = tables.reduce((a, b) => _dist(sofa.box, a.box) < _dist(sofa.box, b.box) ? a : b);
      final gap = sofa.box.gap(t.box);
      if (gap >= Limits.coffeeMin && gap <= Limits.coffeeMax) continue;
      yield Finding(
        rule: 'coffee-gap',
        category: Category.ergonomics,
        severity: Severity.nice,
        title: gap < Limits.coffeeMin ? 'The coffee table is too close' : 'The coffee table is out of reach',
        detail:
            'About ${mm(Limits.coffeeMin)} to ${mm(Limits.coffeeMax)} lets you reach a cup and still pass your knees; this is ${mm(gap)}.',
        fix: 'Set it ${mm(400)} from the sofa’s front.',
        items: [sofa.id, t.id],
      );
    }
  }),
  Rule('talk-distance', Category.ergonomics, types: _living, (ctx) sync* {
    final seats = ctx.tagged('seat').where((i) => !i.spec.has('desk-chair') && i.w >= 700).toList();
    (Item, Item, int)? worst;
    for (var a = 0; a < seats.length; a++) {
      for (var b = a + 1; b < seats.length; b++) {
        final gap = seats[a].box.gap(seats[b].box);
        if (gap > Limits.talkMax && gap > (worst?.$3 ?? 0)) worst = (seats[a], seats[b], gap);
      }
    }
    if (worst == null) return;
    final (x, y, gap) = worst;
    yield Finding(
      rule: 'talk-distance',
      category: Category.ergonomics,
      severity: Severity.should,
      title: '${x.name} and ${y.name} are too far apart to talk',
      detail:
          'They are ${mm(gap)} apart; past about ${mm(Limits.talkMax)} people start raising their voices.',
      fix: 'Bring the seats into one group, with facing seats about 1.2–1.5 m apart.',
      items: [x.id, y.id],
      weight: (gap - Limits.talkMax) / Limits.talkMax + 0.3,
    );
  }),
  Rule('work-triangle', Category.ergonomics, types: {RoomType.kitchen, RoomType.studio}, (ctx) sync* {
    final hob = ctx.tagged('fire').firstOrNull,
        sink = ctx.kinds({'sink'}).firstOrNull,
        fridge = ctx.tagged('cold').firstOrNull;
    if (hob == null || sink == null || fridge == null) return;
    final legs = [_dist(hob.box, sink.box), _dist(sink.box, fridge.box), _dist(fridge.box, hob.box)];
    final total = legs.fold(0.0, (a, b) => a + b);
    final bad = legs.where((l) => l < Limits.legMin || l > Limits.legMax).length;
    if (bad == 0 && total <= Limits.triangleMax) return;
    yield Finding(
      rule: 'work-triangle',
      category: Category.ergonomics,
      severity: Severity.should,
      title: 'Hob, sink and fridge are ${total > Limits.triangleMax ? 'far apart' : 'cramped'}',
      detail:
          'The work triangle’s legs are ${legs.map(mm).join(', ')} (${mm(total)} in all). Each leg works best at '
          '${mm(Limits.legMin)}–${mm(Limits.legMax)}, and all three at most ${mm(Limits.triangleMax)}.',
      fix:
          'Bring the three closer (or apart) and keep the walkway between them free of the island’s corners.',
      items: [hob.id, sink.id, fridge.id],
    );
  }),
  Rule('hob-sink-gap', Category.ergonomics, (ctx) sync* {
    for (final hob in ctx.tagged('fire')) {
      for (final sink in ctx.kinds({'sink'})) {
        final gap = hob.box.gap(sink.box);
        if (gap >= Limits.hobSinkGap) continue;
        yield Finding(
          rule: 'hob-sink-gap',
          category: Category.ergonomics,
          severity: Severity.should,
          title: 'No landing space between hob and sink',
          detail: 'Hot pans need ${mm(Limits.hobSinkGap)} of counter between them; there is ${mm(gap)}.',
          fix: 'Separate them by at least a drawer unit.',
          items: [hob.id, sink.id],
        );
      }
    }
  }),
  Rule('bed-commanding', Category.ergonomics, types: _sleeping, (ctx) sync* {
    final r = ctx.room;
    final doors = r.openings.where((o) => o.kind == OpeningKind.door).toList();
    if (doors.isEmpty) return;
    for (final bed in ctx.tagged('bed')) {
      for (final door in doors) {
        final d = openingBox(r, door, thick: 1);
        // Feet straight at the door: the door's span overlaps the bed's, on the wall the foot faces.
        final inLine =
            door.wall == bed.facesWall &&
            (door.wall.horizontal
                ? (d.x < bed.box.right && bed.box.x < d.right)
                : (d.y < bed.box.bottom && bed.box.y < d.bottom));
        final behind = door.wall == bed.backWall;
        if (!inLine && !behind) continue;
        yield Finding(
          rule: 'bed-commanding',
          category: Category.ergonomics,
          severity: Severity.nice,
          title: behind ? 'The door is behind the bed’s head' : 'The bed lines up with the door',
          detail: 'People rest easier seeing the door from bed without lying in line with it (the "commanding position").',
          fix: 'Put the bed on a wall where the door is in view but off to one side.',
          items: [bed.id],
        );
        break;
      }
    }
  }),
  Rule('desk-door', Category.ergonomics, (ctx) sync* {
    final r = ctx.room;
    final doors = r.openings.where((o) => o.kind == OpeningKind.door);
    for (final desk in ctx.tagged('desk')) {
      if (!doors.any((d) => d.wall == desk.facesWall)) continue;
      yield Finding(
        rule: 'desk-door',
        category: Category.ergonomics,
        severity: Severity.nice,
        title: 'You sit with your back to the door',
        detail: 'Being approached from behind is distracting; most people focus better seeing the door.',
        fix: 'Turn the desk so the door is in view, to the side.',
        items: [desk.id],
      );
    }
  }),
  Rule('bed-window', Category.ergonomics, types: _sleeping, (ctx) sync* {
    final r = ctx.room;
    for (final bed in ctx.tagged('bed')) {
      for (final w in r.openings.where((o) => o.kind == OpeningKind.window && o.wall == bed.backWall)) {
        final strip = openingBox(r, w, thick: 400);
        if (!bed.box.overlaps(strip)) continue;
        yield Finding(
          rule: 'bed-window',
          category: Category.ergonomics,
          severity: Severity.nice,
          title: 'The bed’s head is under a window',
          detail: 'Draughts, street noise and early light fall right on the pillow.',
          fix: 'Use a solid wall for the headboard, or a heavy curtain and a tall headboard.',
          items: [bed.id],
        );
      }
    }
  }),
  Rule('office-density', Category.ergonomics, types: {RoomType.office, RoomType.meeting}, (ctx) sync* {
    final r = ctx.room;
    final per = r.area / 1e6 / r.occupants.people;
    if (r.occupants.people < 2 || per >= Limits.officePerPerson) return;
    yield Finding(
      rule: 'office-density',
      category: Category.ergonomics,
      severity: Severity.should,
      title: 'Too many people for the room',
      detail:
          '${per.toStringAsFixed(1)} m² each; offices feel cramped below about ${Limits.officePerPerson.round()} m² a person.',
      fix: 'Use benching or hot desks, or move storage out to free floor.',
    );
  }),

  // Look
  Rule('focal-point', Category.aesthetics, types: {..._living, RoomType.bedroom}, (ctx) sync* {
    if (ctx.tagged('focal').isNotEmpty) return;
    yield Finding(
      rule: 'focal-point',
      category: Category.aesthetics,
      severity: Severity.nice,
      title: 'The room has no focal point',
      detail: 'A room reads as calm when the eye has one place to land.',
      fix: 'Choose one wall for art, a statement headboard or the TV, and arrange seating towards it.',
    );
  }),
  Rule('visual-balance', Category.aesthetics, (ctx) sync* {
    final r = ctx.room;
    var mass = 0.0, mx = 0.0, my = 0.0;
    for (final i in ctx.blocking) {
      final m = i.box.area * math.max(i.h, 300).toDouble();
      mass += m;
      mx += i.box.cx * m;
      my += i.box.cy * m;
    }
    if (mass == 0 || ctx.blocking.length < 3) return;
    final ox = (mx / mass - r.width / 2) / r.width, oy = (my / mass - r.depth / 2) / r.depth;
    final off = math.sqrt(ox * ox + oy * oy);
    if (off < 0.22) return;
    final side = r.dirOf(r.width / 2 + ox * r.width, r.depth / 2 + oy * r.depth);
    yield Finding(
      rule: 'visual-balance',
      category: Category.aesthetics,
      severity: Severity.nice,
      title: 'The room leans to ${zoneName(side)}',
      detail: 'Most of the bulk sits on one side, so the room feels lopsided.',
      fix: 'Balance it: move a tall or heavy piece across, or add one on the light side.',
      weight: off,
    );
  }),
  Rule('rug-size', Category.aesthetics, (ctx) sync* {
    for (final rug in ctx.tagged('rug')) {
      for (final sofa in ctx.tagged('sofa')) {
        if (_dist(sofa.box, rug.box) > 3000) continue;
        // At least the front legs on the rug.
        if (rug.box.overlapArea(sofa.box) > 0) continue;
        yield Finding(
          rule: 'rug-size',
          category: Category.aesthetics,
          severity: Severity.nice,
          title: 'The rug floats apart from the ${sofa.name.toLowerCase()}',
          detail: 'A rug ties a seating group together when at least the front legs stand on it.',
          fix: 'Use a larger rug, or slide it under the sofa’s front legs.',
          items: [rug.id, sofa.id],
        );
      }
      for (final bed in ctx.tagged('bed')) {
        if (rug.box.overlapArea(bed.box) == 0) continue;
        final b = bed.box, g = rug.box;
        final reach = bed.rot.isEven
            ? math.min(b.x - g.x, g.right - b.right)
            : math.min(b.y - g.y, g.bottom - b.bottom);
        if (reach >= 450) continue;
        yield Finding(
          rule: 'rug-size',
          category: Category.aesthetics,
          severity: Severity.nice,
          title: 'The rug is small for the bed',
          detail: 'Under a bed, a rug looks right showing about ${mm(450)} or more on each side.',
          fix: 'Choose a rug about ${mm(b.w + 900)} wide, or use runners on each side.',
          items: [rug.id, bed.id],
        );
      }
    }
  }),
  Rule('float-sofa', Category.aesthetics, types: _living, (ctx) sync* {
    final r = ctx.room;
    if (r.area < 18e6) return;
    for (final sofa in ctx.tagged('sofa')) {
      if (backGap(r, sofa) > Limits.againstWall) continue;
      final screen = ctx.tagged('focal').firstOrNull;
      if (screen != null && _dist(sofa.box, screen.box) < 3500) continue;
      yield Finding(
        rule: 'float-sofa',
        category: Category.aesthetics,
        severity: Severity.nice,
        title: 'Float the ${sofa.name.toLowerCase()} off the wall',
        detail: 'In a room this size, seating pushed to the walls leaves an empty middle and a long talking distance.',
        fix:
            'Pull it forward into a conversation group of about ${mm(3000)} across. Leave 300–450 mm behind it, '
            'or ${mm(Limits.pathMain)} if people will walk there.',
        items: [sofa.id],
      );
    }
  }),
  Rule('near-miss', Category.aesthetics, (ctx) sync* {
    final r = ctx.room;
    for (final i in ctx.blocking.where((i) => i.spec.wall != WallNeed.none)) {
      final (gap, _) = nearestWall(r, i.box);
      if (gap <= 30 || gap > 120) continue;
      yield Finding(
        rule: 'near-miss',
        category: Category.aesthetics,
        severity: Severity.nice,
        title: '${i.name} almost touches the wall',
        detail: 'A gap of ${mm(gap)} looks accidental and gathers dust.',
        fix: 'Push it right back, leaving only skirting room.',
        items: [i.id],
      );
    }
  }),

  // Vaastu (within the room)
  Rule('vaastu-bed-head', Category.vaastu, (ctx) sync* {
    final r = ctx.room;
    for (final bed in ctx.tagged('bed')) {
      final head = r.wallDir(bed.backWall);
      if (head != Dir8.n && head != Dir8.ne && head != Dir8.nw) continue;
      yield Finding(
        rule: 'vaastu-bed-head',
        category: Category.vaastu,
        severity: _vaastu(r),
        title: 'The bed’s head points ${head.label.toLowerCase()}',
        detail: 'Vaastu advises sleeping with the head to the south (best), east or west, never the north.',
        fix: 'Turn the bed so its headboard is on a south or east wall.',
        items: [bed.id],
      );
    }
  }),
  Rule('vaastu-bed-zone', Category.vaastu, types: {RoomType.bedroom}, (ctx) sync* {
    final r = ctx.room;
    for (final bed in ctx.tagged('bed')) {
      final z = zoneOf(r, bed);
      if (z == null || z == Dir8.sw || z == Dir8.s || z == Dir8.w) continue;
      yield Finding(
        rule: 'vaastu-bed-zone',
        category: Category.vaastu,
        severity: z == Dir8.ne ? _vaastu(r) : Severity.nice,
        title: 'The bed sits in ${zoneName(z)}',
        detail: 'Vaastu places the master bed in the south-west of the room for stability.',
        fix: 'Move the bed towards the south-west corner.',
        items: [bed.id],
      );
    }
  }),
  Rule('vaastu-heavy-sw', Category.vaastu, (ctx) sync* {
    final r = ctx.room;
    for (final i in ctx.tagged('heavy-storage')) {
      final z = zoneOf(r, i);
      if (z != Dir8.ne && z != Dir8.n && z != Dir8.e && z != null) continue;
      yield Finding(
        rule: 'vaastu-heavy-sw',
        category: Category.vaastu,
        severity: _vaastu(r),
        title: 'Heavy ${i.name.toLowerCase()} in ${zoneName(z)}',
        detail: 'Vaastu keeps heavy pieces in the south and west, and the north-east light and open.',
        fix: 'Move it to the south, south-west or west wall.',
        items: [i.id],
      );
    }
  }),
  Rule('vaastu-ne-open', Category.vaastu, (ctx) sync* {
    final r = ctx.room;
    final tall = ctx.blocking.where(
      (i) => i.h >= Limits.tall && zoneOf(r, i) == Dir8.ne && !i.spec.has('heavy-storage'),
    );
    for (final i in tall) {
      yield Finding(
        rule: 'vaastu-ne-open',
        category: Category.vaastu,
        severity: Severity.nice,
        title: 'Keep the north-east light',
        detail:
            'The tall ${i.name.toLowerCase()} blocks the north-east, which Vaastu keeps open for light and calm.',
        fix: 'Swap it for something low, or a plant.',
        items: [i.id],
      );
    }
  }),
  Rule('vaastu-brahmasthan', Category.vaastu, (ctx) sync* {
    final r = ctx.room;
    final centre = Box(r.width ~/ 3, r.depth ~/ 3, r.width ~/ 3, r.depth ~/ 3);
    final heavy = [
      for (final i in ctx.blocking)
        if (i.spec.heavy && i.box.overlapArea(centre) > centre.area * 0.15 && !i.spec.has('dining')) i,
    ];
    if (heavy.isEmpty) return;
    yield Finding(
      rule: 'vaastu-brahmasthan',
      category: Category.vaastu,
      severity: _vaastu(r),
      title: 'The centre of the room is weighed down',
      detail: 'Vaastu keeps the Brahmasthan (the middle ninth) free and open.',
      fix: 'Move ${heavy.map((i) => i.name.toLowerCase()).join(' and ')} towards the walls.',
      items: [for (final i in heavy) i.id],
    );
  }),
  Rule('vaastu-desk-facing', Category.vaastu, (ctx) sync* {
    final r = ctx.room;
    for (final desk in ctx.tagged('desk').where((d) => d.kind != 'reception_desk')) {
      final looks = r.wallDir(desk.backWall);
      if (const {Dir8.n, Dir8.e, Dir8.ne}.contains(looks)) continue;
      yield Finding(
        rule: 'vaastu-desk-facing',
        category: Category.vaastu,
        severity: _vaastu(r),
        title: 'At the ${desk.name.toLowerCase()} you face ${looks.label.toLowerCase()}',
        detail: 'Vaastu suggests facing north (work, money) or east (study, focus).',
        fix: 'Turn the desk so you sit looking north or east.',
        items: [desk.id],
      );
    }
  }),
  Rule('vaastu-hob', Category.vaastu, types: {RoomType.kitchen, RoomType.studio}, (ctx) sync* {
    final r = ctx.room;
    for (final hob in ctx.tagged('fire')) {
      final z = zoneOf(r, hob);
      final looks = r.wallDir(hob.backWall);
      if ((z == Dir8.se || z == Dir8.e || z == Dir8.s) && looks == Dir8.e) continue;
      yield Finding(
        rule: 'vaastu-hob',
        category: Category.vaastu,
        severity: _vaastu(r),
        title: z == Dir8.se ? 'Cook facing east' : 'The hob sits in ${zoneName(z)}',
        detail: 'Vaastu puts fire in the south-east (Agni’s corner), with the cook facing east; north-west is the next best.',
        fix: 'Place the hob on the south-east counter so you face east while cooking.',
        items: [hob.id],
      );
    }
  }),
  Rule('vaastu-water', Category.vaastu, (ctx) sync* {
    final r = ctx.room;
    for (final i in ctx.room.items.where(
      (i) => i.kind == 'sink' || i.kind == 'water_purifier' || i.kind == 'aquarium',
    )) {
      final z = zoneOf(r, i);
      if (z == Dir8.ne || z == Dir8.n || z == Dir8.e) continue;
      yield Finding(
        rule: 'vaastu-water',
        category: Category.vaastu,
        severity: Severity.nice,
        title: '${i.name} sits in ${zoneName(z)}',
        detail: 'Vaastu places water in the north-east, north or east.',
        fix: 'Move it towards the north-east where plumbing allows.',
        items: [i.id],
      );
    }
  }),
  Rule('vaastu-fire-water', Category.vaastu, (ctx) sync* {
    final r = ctx.room;
    for (final hob in ctx.tagged('fire')) {
      for (final w in ctx.room.items.where((i) => i.kind == 'sink' || i.kind == 'fridge')) {
        if (hob.box.gap(w.box) >= 600) continue;
        yield Finding(
          rule: 'vaastu-fire-water',
          category: Category.vaastu,
          severity: _vaastu(r),
          title: 'Fire and water side by side',
          detail: 'Vaastu keeps the hob apart from the ${w.name.toLowerCase()} (fire and water clash).',
          fix: 'Leave at least ${mm(600)} of counter between them.',
          items: [hob.id, w.id],
        );
      }
    }
  }),
  Rule('vaastu-fridge', Category.vaastu, (ctx) sync* {
    final r = ctx.room;
    for (final f in ctx.kinds({'fridge'})) {
      final z = zoneOf(r, f);
      if (z != Dir8.ne) continue;
      yield Finding(
        rule: 'vaastu-fridge',
        category: Category.vaastu,
        severity: Severity.nice,
        title: 'The fridge is in the north-east',
        detail: 'Vaastu prefers heavy appliances in the south-west, south or north-west.',
        fix: 'Move the fridge to the south-west or north-west.',
        items: [f.id],
      );
    }
  }),
  Rule('vaastu-pooja', Category.vaastu, (ctx) sync* {
    final r = ctx.room;
    for (final p in ctx.tagged('worship')) {
      final z = zoneOf(r, p);
      final looks = r.wallDir(p.backWall);
      final goodZone = z == Dir8.ne || z == Dir8.e || z == Dir8.n;
      final goodFace = looks == Dir8.e || looks == Dir8.n;
      if (goodZone && goodFace) continue;
      yield Finding(
        rule: 'vaastu-pooja',
        category: Category.vaastu,
        severity: _vaastu(r),
        title: goodZone ? 'Face east while praying' : 'The pooja unit is in ${zoneName(z)}',
        detail: 'Vaastu places the shrine in the north-east (Ishanya), with you facing east (or north) as you pray.',
        fix: 'Set the unit on the east wall of the north-east, so you face east.',
        items: [p.id],
      );
    }
  }),
  Rule('vaastu-mirror', Category.vaastu, (ctx) sync* {
    final r = ctx.room;
    for (final m in ctx.tagged('mirror')) {
      final wall = r.wallDir(m.backWall);
      final facesBed = ctx
          .tagged('bed')
          .any((b) => m.facesWall == b.backWall || m.frontZone(4000).overlaps(b.box));
      if ((wall == Dir8.n || wall == Dir8.e) && !facesBed) continue;
      yield Finding(
        rule: 'vaastu-mirror',
        category: Category.vaastu,
        severity: Severity.nice,
        title: facesBed
            ? 'The mirror faces the bed'
            : 'The mirror hangs on the ${wall.label.toLowerCase()} wall',
        detail: 'Vaastu hangs mirrors on north or east walls, and never facing the bed.',
        fix: 'Move it to a north or east wall that the bed does not face, or cover it at night.',
        items: [m.id],
      );
    }
  }),
  Rule('vaastu-safe', Category.vaastu, (ctx) sync* {
    final r = ctx.room;
    for (final s in ctx.kinds({'safe'})) {
      final opens = r.wallDir(s.facesWall);
      final z = zoneOf(r, s);
      if (opens == Dir8.n && (z == Dir8.sw || z == Dir8.s || z == Dir8.w)) continue;
      yield Finding(
        rule: 'vaastu-safe',
        category: Category.vaastu,
        severity: _vaastu(r),
        title: 'Turn the safe to open north',
        detail: 'Vaastu keeps the safe in the south-west, opening towards the north (Kubera’s direction).',
        fix: 'Stand it against the south wall of the south-west so its door opens north.',
        items: [s.id],
      );
    }
  }),
  Rule('vaastu-screen', Category.vaastu, types: _living, (ctx) sync* {
    final r = ctx.room;
    for (final tv in ctx.tagged('screen')) {
      final z = zoneOf(r, tv);
      if (z == Dir8.se || z == Dir8.e || z == Dir8.s) continue;
      yield Finding(
        rule: 'vaastu-screen',
        category: Category.vaastu,
        severity: Severity.nice,
        title: 'Electronics sit in ${zoneName(z)}',
        detail: 'Vaastu puts the TV and electronics (fire element) in the south-east.',
        fix: 'Mount the TV on the east or south wall near the south-east.',
        items: [tv.id],
      );
    }
  }),
  Rule('vaastu-toilet', Category.vaastu, types: {RoomType.bathroom}, (ctx) sync* {
    final r = ctx.room;
    for (final t in ctx.tagged('toilet')) {
      final faces = r.facing(t);
      if (faces == Dir8.n || faces == Dir8.s) continue;
      yield Finding(
        rule: 'vaastu-toilet',
        category: Category.vaastu,
        severity: Severity.nice,
        title: 'Seat the toilet on a north–south line',
        detail: 'Vaastu has you face north or south on the toilet, not east or west.',
        fix: 'When refitting, turn the pan to face north or south.',
        items: [t.id],
      );
    }
  }),
  Rule('vaastu-entrance', Category.vaastu, types: {RoomType.entrance}, (ctx) sync* {
    final r = ctx.room;
    for (final o in r.openings.where((o) => o.kind == OpeningKind.door)) {
      final d = r.wallDir(o.wall);
      if (const {Dir8.n, Dir8.ne, Dir8.e, Dir8.nw}.contains(d)) continue;
      yield Finding(
        rule: 'vaastu-entrance',
        category: Category.vaastu,
        severity: Severity.nice,
        title: 'The entrance faces ${d.label.toLowerCase()}',
        detail: 'Vaastu favours north, north-east or east entrances. A door cannot easily move, so remedies are used.',
        fix: 'Keep the entrance bright and uncluttered; a threshold strip and a nameplate are the usual remedies.',
      );
    }
  }),

  // Business
  Rule('retail-decompression', Category.efficiency, types: {RoomType.retail}, (ctx) sync* {
    final r = ctx.room;
    for (final o in r.openings.where((o) => o.kind.passable)) {
      final zone = openingBox(r, o, thick: Limits.decompression);
      final wide = Box(zone.x - 600, zone.y - 600, zone.w + 1200, zone.d + 1200);
      final crowding = ctx.room.items.where((i) => i.spec.has('display') && i.box.overlaps(wide)).toList();
      if (crowding.isEmpty) continue;
      yield Finding(
        rule: 'retail-decompression',
        category: Category.efficiency,
        severity: Severity.should,
        title: 'Displays crowd the entrance',
        detail:
            'Shoppers adjust for the first ${mm(Limits.decompression)} or so inside a shop and miss what is there.',
        fix: 'Keep the entry zone open; put the first display just beyond it, on the right.',
        items: [for (final i in crowding) i.id],
      );
    }
  }),
  Rule('checkout-exit', Category.efficiency, types: {RoomType.retail}, (ctx) sync* {
    final r = ctx.room;
    final door = r.openings.where((o) => o.kind.passable).firstOrNull;
    final till = ctx.tagged('cash').firstOrNull;
    if (door == null || till == null) return;
    final d = openingBox(r, door, thick: 1);
    if (_dist(d, till.box) <= math.max(r.width, r.depth) / 2) return;
    yield Finding(
      rule: 'checkout-exit',
      category: Category.efficiency,
      severity: Severity.nice,
      title: 'The checkout is far from the way out',
      detail: 'Customers end their visit at the exit; a distant till loses impulse sales and watch over the door.',
      fix: 'Put the checkout near the entrance, usually on the left as you walk in.',
      items: [till.id],
    );
  }),
];
