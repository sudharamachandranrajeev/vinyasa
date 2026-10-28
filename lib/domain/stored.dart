/// What a room keeps in its wardrobes, shelves and cabinets, and where each
/// thing should go: daily things in easy reach near the door, heavy things
/// low, rarely used things out of the way. Reach follows who uses the room.
/// The method the plan follows (KonMari at home, 5S at work, ABC in a
/// storeroom) is in docs/rules.md, section "Organisation".
library;

import 'dart:math' as math;

import 'json.dart';
import 'space.dart';

/// What sort of thing it is; it decides which storage suits it.
enum Stuff {
  clothes('Clothes'),
  shoes('Shoes'),
  books('Books'),
  papers('Papers'),
  kitchen('Kitchenware'),
  tools('Tools'),
  stock('Stock'),
  misc('Other things'),
  keepsakes('Keepsakes');

  const Stuff(this.label);
  final String label;

  /// The KonMari order: clothes, books, papers, komono (everything else),
  /// then things with feelings attached.
  int get konmari => switch (this) {
    clothes => 0,
    books => 1,
    papers => 2,
    keepsakes => 4,
    _ => 3,
  };

  static Stuff of(String name) => values.where((v) => v.name == name).firstOrNull ?? misc;
}

/// How often it is used.
enum Use {
  daily('Daily'),
  weekly('Weekly'),
  rare('Rarely');

  const Use(this.label);
  final String label;

  static Use of(String name) => values.where((v) => v.name == name).firstOrNull ?? weekly;
}

/// One thing, or one kind of thing (“winter coats”), to find a place for.
class Thing {
  const Thing({
    required this.id,
    required this.name,
    this.stuff = Stuff.misc,
    this.use = Use.weekly,
    this.heavy = false,
    this.tagged = '',
  });

  final String id, name;
  final Stuff stuff;
  final Use use;

  /// Two hands, or more than about 10 kg.
  final bool heavy;

  /// The day it was red-tagged (5S) as "not sure we need it", as yyyy-mm-dd.
  final String tagged;

  Thing copyWith({String? name, Stuff? stuff, Use? use, bool? heavy, String? tagged}) => Thing(
    id: id,
    name: name ?? this.name,
    stuff: stuff ?? this.stuff,
    use: use ?? this.use,
    heavy: heavy ?? this.heavy,
    tagged: tagged ?? this.tagged,
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'stuff': stuff.name,
    'use': use.name,
    if (heavy) 'heavy': true,
    if (tagged.isNotEmpty) 'tagged': tagged,
  };

  factory Thing.fromJson(Json j) => Thing(
    id: str(j['id']).isEmpty ? 't${j.hashCode}' : str(j['id']),
    name: str(j['name']).isEmpty ? 'Thing' : str(j['name']),
    stuff: Stuff.of(str(j['stuff'])),
    use: Use.of(str(j['use'])),
    heavy: j['heavy'] == true,
    tagged: DateTime.tryParse(str(j['tagged'])) == null ? '' : str(j['tagged']),
  );
}

/// How easy a shelf is to reach for the people who use the room, from the
/// floor in millimetres. [prime] is the best band (waist to shoulder), [ok]
/// the band reachable without a stool or bending low.
class Reach {
  const Reach({required this.primeLow, required this.primeHigh, required this.okLow, required this.okHigh});
  final int primeLow, primeHigh, okLow, okHigh;

  /// Wheelchair users: the ADA 308 reach range, 380 to 1220.
  static const wheelchair = Reach(primeLow: 600, primeHigh: 1100, okLow: 380, okHigh: 1220);
  static const elderly = Reach(primeLow: 750, primeHigh: 1350, okLow: 500, okHigh: 1500);
  static const adult = Reach(primeLow: 750, primeHigh: 1450, okLow: 400, okHigh: 1750);

  factory Reach.of(Occupants o) => o.wheelchair
      ? wheelchair
      : o.elderly
      ? elderly
      : adult;

  String get describe => '$primeLow–$primeHigh mm is easiest, $okLow–$okHigh mm is within reach';
}

enum Zone {
  prime('Easiest to reach'),
  low('Low'),
  high('High'),
  floor('Near the floor'),
  beyond('Out of easy reach');

  const Zone(this.label);
  final String label;

  /// Within comfortable reach.
  bool get easy => this == prime || this == low || this == high;
}

/// One shelf (or drawer, or hanging rail) of a storage unit; [level] 0 is the lowest.
class Shelf {
  const Shelf(this.level, this.bottom, this.top, this.zone, this.slots);
  final int level, bottom, top, slots;
  final Zone zone;
}

/// A piece of storage with the shelves it has.
class Unit {
  const Unit(this.item, this.name, this.shelves);
  final Item item;

  /// The item's name, numbered when the room has more than one of the kind.
  final String name;
  final List<Shelf> shelves;
}

/// Where one thing goes.
class Placement {
  const Placement(this.thing, this.unit, this.shelf, this.why, {this.compromise = false});
  final Thing thing;
  final Unit unit;
  final Shelf shelf;
  final String why;

  /// The best place left was not a good one; the reason says so.
  final bool compromise;
}

/// The result: a place for each thing that fits, the rest, and the steps.
class StoragePlan {
  const StoragePlan({
    required this.reach,
    required this.units,
    required this.placed,
    required this.unplaced,
    required this.steps,
  });
  final Reach reach;
  final List<Unit> units;
  final List<Placement> placed;
  final List<Thing> unplaced;
  final List<({String title, String detail})> steps;

  List<Placement> on(Shelf s, Unit u) => [
    for (final p in placed)
      if (identical(p.unit, u) && p.shelf.level == s.level) p,
  ];
}

const _pitch = {'pallet_rack': 1000, 'dresser': 280};

/// The shelves of [item], from the bottom: its height cut into levels, each
/// holding about a thing per 300 mm of width.
List<Shelf> shelvesOf(Item item, Reach reach) {
  final height = item.h > 0 ? item.h : item.spec.h;
  final pitch = _pitch[item.kind] ?? 400;
  final n = (height / pitch).round().clamp(1, 8);
  final slots = (item.w / 300).round().clamp(1, 6);
  return [
    for (var k = 0; k < n; k++)
      () {
        final bottom = (k * height / n).round(), top = ((k + 1) * height / n).round();
        final mid = (bottom + top) / 2;
        final zone = mid >= reach.primeLow && mid <= reach.primeHigh
            ? Zone.prime
            : mid >= reach.okLow && mid < reach.primeLow
            ? Zone.low
            : mid > reach.primeHigh && mid <= reach.okHigh
            ? Zone.high
            : mid < reach.okLow
            ? Zone.floor
            : Zone.beyond;
        return Shelf(k, bottom, top, zone, slots);
      }(),
  ];
}

/// 2 for storage made for this sort of thing, 1 for storage that will do,
/// 0 for storage that does not suit it.
int fits(String unitKind, Stuff s) => switch (unitKind) {
  'shoe_rack' => s == Stuff.shoes ? 2 : 0,
  'bookshelf' => switch (s) {
    Stuff.books => 2,
    Stuff.keepsakes || Stuff.misc || Stuff.papers => 1,
    _ => 0,
  },
  'wardrobe' || 'wardrobe_sliding' => switch (s) {
    Stuff.clothes => 2,
    Stuff.shoes || Stuff.keepsakes || Stuff.misc => 1,
    _ => 0,
  },
  'dresser' => switch (s) {
    Stuff.clothes => 2,
    Stuff.papers || Stuff.keepsakes || Stuff.misc => 1,
    _ => 0,
  },
  'filing' => s == Stuff.papers ? 2 : 0,
  'shelving_unit' || 'pallet_rack' => switch (s) {
    Stuff.stock || Stuff.tools => 2,
    _ => 1,
  },
  _ => 1,
};

/// The room's storage, numbered where a kind repeats.
List<Unit> unitsOf(Room room) {
  final stores = [
    for (final i in room.items)
      if (i.spec.has('storage')) i,
  ];
  final reach = Reach.of(room.occupants);
  final count = <String, int>{};
  for (final i in stores) {
    count[i.name] = (count[i.name] ?? 0) + 1;
  }
  final seen = <String, int>{};
  return [
    for (final i in stores)
      Unit(
        i,
        count[i.name]! > 1 ? '${i.name} ${seen[i.name] = (seen[i.name] ?? 0) + 1}' : i.name,
        shelvesOf(i, reach),
      ),
  ];
}

/// Days a red-tagged thing may wait for a decision (5S).
const tagDays = 7;

/// How many days ago [t] was red-tagged as of [today], or null if it was not.
int? tagAge(Thing t, DateTime today) {
  final at = DateTime.tryParse(t.tagged);
  if (at == null) return null;
  return DateTime(today.year, today.month, today.day).difference(DateTime(at.year, at.month, at.day)).inDays;
}

/// Finds a place for each of the room's things. Daily things take the
/// easiest shelves nearest the door, heavy things the lowest shelves within
/// reach, rarely used things what is left, out of the way.
StoragePlan organise(Room room, {DateTime? today}) {
  today ??= DateTime.now();
  final reach = Reach.of(room.occupants);
  final units = unitsOf(room);
  final doors = [
    for (final o in room.openings)
      if (o.kind.passable) openingBox(room, o),
  ];
  final reachFar = math.sqrt(room.width * room.width + room.depth * room.depth);
  // 0 beside the door, 1 at the far end of the room.
  double far(Unit u) => doors.isEmpty
      ? 0.5
      : (doors
                    .map(
                      (d) => math.sqrt(math.pow(d.cx - u.item.box.cx, 2) + math.pow(d.cy - u.item.box.cy, 2)),
                    )
                    .reduce(math.min) /
                reachFar)
            .clamp(0, 1);

  final free = {
    for (final u in units) u: {for (final s in u.shelves) s.level: s.slots},
  };
  final order = [...room.things]
    ..sort((a, b) {
      final byUse = a.use.index.compareTo(b.use.index);
      return byUse != 0 ? byUse : (b.heavy ? 1 : 0).compareTo(a.heavy ? 1 : 0);
    });

  final placed = <Placement>[];
  final unplaced = <Thing>[];
  for (final t in order) {
    Placement? best;
    double bestCost = double.infinity;
    for (final u in units) {
      final fit = fits(u.item.kind, t.stuff);
      if (fit == 0) continue;
      for (final s in u.shelves) {
        if ((free[u]![s.level] ?? 0) <= 0) continue;
        // Heavy things: no higher than 1100 mm, and within reach if they
        // can be; otherwise the cost below still pulls them low.
        final reachable = s.zone.easy && (!t.heavy || s.top <= 1100);
        var cost = fit == 2 ? 0.0 : 5.0;
        cost += switch (t.use) {
          Use.daily => (s.zone == Zone.prime ? 0 : 3) + 4 * far(u),
          Use.weekly => (s.zone == Zone.prime ? 0 : 1) + 2 * far(u),
          Use.rare => (s.zone == Zone.prime ? 6 : (s.zone.easy ? 2 : 0)) + 4 * (1 - far(u)),
        };
        if (t.heavy) cost += 2 * s.level;
        // Things used often must be within reach: keep an unreachable
        // shelf as a last resort only.
        if (!reachable && (t.use != Use.rare || t.heavy)) cost += 100;
        if (cost < bestCost) {
          bestCost = cost;
          best = Placement(
            t,
            u,
            s,
            _why(t, s, reachable),
            compromise: !reachable && (t.use != Use.rare || t.heavy),
          );
        }
      }
    }
    if (best == null) {
      unplaced.add(t);
      continue;
    }
    free[best.unit]![best.shelf.level] = free[best.unit]![best.shelf.level]! - 1;
    placed.add(best);
  }
  return StoragePlan(
    reach: reach,
    units: units,
    placed: placed,
    unplaced: unplaced,
    steps: _steps(room, placed, unplaced, today),
  );
}

String _why(Thing t, Shelf s, bool reachable) {
  final at = '${s.bottom}–${s.top} mm up';
  if (t.heavy && reachable) return 'Heavy, so low: $at, within reach, never overhead.';
  if (!reachable && (t.use != Use.rare || t.heavy)) {
    return 'The only shelf with space left is ${s.zone.label.toLowerCase()} ($at). Make room on a better shelf or remove something.';
  }
  return switch (t.use) {
    Use.daily =>
      s.zone == Zone.prime
          ? 'Used daily: easiest to reach ($at), nearest the door.'
          : 'Used daily: within reach ($at).',
    Use.weekly => 'Used weekly: ${s.zone == Zone.prime ? 'easy to reach' : 'within reach'} ($at).',
    Use.rare =>
      s.zone.easy
          ? 'Rarely used: out of the way ($at).'
          : 'Rarely used: ${s.zone.label.toLowerCase()} ($at), keeping easy shelves free.',
  };
}

List<({String title, String detail})> _steps(
  Room room,
  List<Placement> placed,
  List<Thing> unplaced,
  DateTime today,
) {
  final things = room.things;
  if (things.isEmpty) return const [];
  final steps = <({String title, String detail})>[];
  final kinds = <Stuff>{for (final t in things) t.stuff}.toList()
    ..sort((a, b) => a.konmari.compareTo(b.konmari));
  if (room.type.residential) {
    steps.add((
      title: 'Declutter first, one sort of thing at a time',
      detail:
          'Take everything of one sort out and keep only what you use or love. Go in this order: '
          '${kinds.map((k) => k.label.toLowerCase()).join(', ')}. Feelings come last, so keepsakes are the last.',
    ));
  } else {
    final tagged = things.where((t) => t.tagged.isNotEmpty).toList();
    final late = tagged.where((t) => (tagAge(t, today) ?? 0) > tagDays).length;
    steps.add((
      title: 'Sort: red-tag what you are not sure of',
      detail: tagged.isEmpty
          ? 'Tag anything you are not sure the work needs, move it to a quarantine shelf, and decide within '
                '$tagDays days.'
          : '${tagged.length} tagged. Decide each within $tagDays days of its tag${late > 0 ? ' ($late overdue)' : ''}: '
                'keep it, move it elsewhere or let it go.',
    ));
  }
  if (room.type == RoomType.storeroom && things.isNotEmpty) {
    final a = things.where((t) => t.use == Use.daily).length;
    final share = (100 * a / things.length).round();
    steps.add((
      title: 'Slot by how often things move (ABC)',
      detail:
          'Daily things ($a of ${things.length}, $share%) are A: nearest the door, on the easiest shelves. '
          'Weekly are B, rare are C, furthest and highest or lowest.'
          '${share > 20 ? ' More than a fifth marked A is a lot; check that each really moves daily.' : ''}',
    ));
  }
  steps.add((
    title: 'Give each thing its place',
    detail:
        'Put things where the list says, heaviest first so the shelves do not need unloading again. '
        '${placed.length} of ${things.length} have a place.'
        '${unplaced.isEmpty ? '' : ' ${unplaced.length} have no space: let some go or add storage.'}',
  ));
  steps.add((
    title: 'Label every shelf',
    detail: 'Print the label sheet and stick each label at eye level on its shelf.',
  ));
  steps.add((
    title: room.type.residential ? 'Put away in one move' : 'Keep it that way',
    detail: room.type.residential
        ? 'After use, return each thing to its place straight away; a job under two minutes is done now.'
        : 'Whoever makes a mess clears it. Check the shelves against this list on a set day each month.',
  ));
  return steps;
}

String _esc(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

/// The plan as plain text, one line per thing, grouped by unit and shelf.
String labelText(StoragePlan plan) {
  final out = StringBuffer();
  for (final u in plan.units) {
    final here = [
      for (final p in plan.placed)
        if (identical(p.unit, u)) p,
    ];
    if (here.isEmpty) continue;
    out.writeln(u.name);
    for (final s in u.shelves.reversed) {
      for (final p in plan.on(s, u)) {
        out.writeln('  shelf ${s.level + 1} from the bottom (${s.bottom}–${s.top} mm): ${p.thing.name}');
      }
    }
  }
  return out.toString();
}

/// A page of labels, one per thing, to print and cut out.
String labelSheet(StoragePlan plan, String room) {
  final cards = StringBuffer();
  for (final u in plan.units) {
    for (final s in u.shelves.reversed) {
      for (final p in plan.on(s, u)) {
        cards.writeln(
          '<div class="l"><b>${_esc(p.thing.name)}</b>'
          '<span>${_esc(u.name)} · shelf ${s.level + 1}</span></div>',
        );
      }
    }
  }
  return '<!doctype html><meta charset="utf-8"><title>${_esc(room)} labels</title>'
      '<style>body{font-family:sans-serif;display:flex;flex-wrap:wrap;gap:6mm;margin:10mm}'
      '.l{border:1px solid #000;border-radius:2mm;padding:3mm 5mm;min-width:45mm;break-inside:avoid}'
      '.l b{display:block;font-size:16pt}.l span{font-size:9pt;color:#444}</style>\n$cards';
}
