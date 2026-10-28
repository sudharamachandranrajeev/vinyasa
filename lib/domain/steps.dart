/// Turns a plan into steps a person can follow: what to empty first, which
/// piece to move where (in an order that never puts something down where
/// another still stands), and the finishing touches.
library;

import 'analysis.dart';
import 'planner.dart';
import 'rules.dart' show mm, Limits;
import 'space.dart';

enum StepKind { prepare, move, finish }

class PlanStep {
  const PlanStep({
    required this.id,
    required this.kind,
    required this.title,
    this.detail = '',
    this.tips = const [],
    this.items = const [],
  });

  /// Stable for a given plan, so ticks survive a reload.
  final String id;
  final StepKind kind;
  final String title;
  final String detail;
  final List<String> tips;
  final List<String> items;
}

/// Where a box sits, in words: "in the south-west corner", "against the
/// east wall, 300 mm from the north wall", "1.2 m from the west wall and
/// 900 mm from the south wall".
String describePlace(Room room, Box b) {
  final gaps = {
    Wall.top: b.y,
    Wall.right: room.width - b.right,
    Wall.bottom: room.depth - b.bottom,
    Wall.left: b.x,
  };
  String wall(Wall w) => 'the ${room.wallDir(w).label.toLowerCase()} wall';
  final touching = [
    for (final e in gaps.entries)
      if (e.value <= Limits.againstWall) e.key,
  ];
  if (touching.length >= 2 && touching.any((w) => w.horizontal) && touching.any((w) => !w.horizontal)) {
    final h = touching.firstWhere((w) => w.horizontal), v = touching.firstWhere((w) => !w.horizontal);
    final corner = room.dirOf(
      v == Wall.left ? 0 : room.width.toDouble(),
      h == Wall.top ? 0 : room.depth.toDouble(),
    );
    return 'in the ${corner?.label.toLowerCase() ?? 'corner'} corner';
  }
  if (touching.isNotEmpty) {
    final w = touching.first;
    final across = w.horizontal ? [Wall.left, Wall.right] : [Wall.top, Wall.bottom];
    final near = gaps[across[0]]! <= gaps[across[1]]! ? across[0] : across[1];
    final centred = (gaps[across[0]]! - gaps[across[1]]!).abs() < 150;
    return centred
        ? 'centred against ${wall(w)}'
        : 'against ${wall(w)}, ${mm(gaps[near]!)} from ${wall(near)}';
  }
  final h = gaps[Wall.top]! <= gaps[Wall.bottom]! ? Wall.top : Wall.bottom;
  final v = gaps[Wall.left]! <= gaps[Wall.right]! ? Wall.left : Wall.right;
  return '${mm(gaps[v]!)} from ${wall(v)} and ${mm(gaps[h]!)} from ${wall(h)}';
}

/// Names counted: [bedside table, bedside table, rug] → [both bedside
/// tables, the rug].
List<String> together(List<String> names) {
  final counts = <String, int>{};
  for (final n in names) {
    counts[n] = (counts[n] ?? 0) + 1;
  }
  return [
    for (final MapEntry(key: n, value: c) in counts.entries)
      switch (c) {
        1 => n,
        2 => 'both ${n}s',
        _ => 'all $c ${n}s',
      },
  ];
}

/// The steps from [plan]'s before to its after.
List<PlanStep> stepsFor(PlanResult plan) {
  final from = plan.before.room, to = plan.after.room;
  final groups = groupsOf(from);
  final carried = {for (final g in groups.values) ...g};
  final moved = [
    for (final a in from.items)
      if (to.item(a.id) case final b?
          when (a.x != b.x || a.y != b.y || a.rot != b.rot) && !carried.contains(a.id))
        a.id,
  ];
  final steps = <PlanStep>[];

  final empty = [
    for (final id in moved)
      if (from.item(id)!.spec.has('storage') || from.item(id)!.spec.has('drawers'))
        from.item(id)!.name.toLowerCase(),
  ];
  steps.add(
    PlanStep(
      id: 'prepare',
      kind: StepKind.prepare,
      title: 'Clear the way',
      detail: [
        'Pick up everything on the floor and take out what does not belong in this room.',
        if (empty.isNotEmpty)
          'Empty the ${empty.join(', ')} before moving ${empty.length == 1 ? 'it' : 'them'}.',
        if (plan.before.freeShare < Limits.freeFloor) 'The room is crowded: sort things into keep, donate and discard, and keep only what is used or loved.',
      ].join(' '),
      tips: const [
        'Measure doorways before moving big pieces through them.',
        'Slide heavy pieces on furniture sliders or a folded blanket; lift with your legs, not your back.',
      ],
    ),
  );

  // An item can only go down once whatever stands on its new spot has
  // moved away. Rugs go before what stands on them.
  final order = <String>[];
  final pending = [...moved];
  bool blocks(String a, String b) {
    // Does a, where it stands now, sit on b's new spot (and a still has to move)?
    final aNow = from.item(a)!.box, bNew = to.item(b)!.box;
    return aNow.overlapArea(bNew) > 2500;
  }

  bool rugFirst(String rug, String other) =>
      from.item(rug)!.kind == 'rug' &&
      from.item(other)!.kind != 'rug' &&
      to.item(rug)!.box.overlaps(to.item(other)!.box);

  final parked = <String>{};
  while (pending.isNotEmpty) {
    String? next;
    // Heavy, then big, first: they set the room's shape.
    final ranked = [...pending]
      ..sort((a, b) {
        final ia = from.item(a)!, ib = from.item(b)!;
        if (ia.kind == 'rug' && ib.kind != 'rug') return -1;
        if (ib.kind == 'rug' && ia.kind != 'rug') return 1;
        if (ia.spec.heavy != ib.spec.heavy) return ia.spec.heavy ? -1 : 1;
        return ib.box.area.compareTo(ia.box.area);
      });
    for (final c in ranked) {
      final waits = pending.any((o) => o != c && !parked.contains(o) && (blocks(o, c) || rugFirst(o, c)));
      if (!waits) {
        next = c;
        break;
      }
    }
    if (next == null) {
      // A cycle (two pieces swapping places): park the first aside.
      final p = ranked.firstWhere((id) => !parked.contains(id), orElse: () => ranked.first);
      parked.add(p);
      final it = from.item(p)!;
      steps.add(
        PlanStep(
          id: 'park-$p',
          kind: StepKind.move,
          title: 'Move the ${it.name.toLowerCase()} aside for now',
          detail: 'Slide it into open floor out of the way; it goes to its new place in a later step.',
          items: [p],
        ),
      );
      continue;
    }
    pending.remove(next);
    order.add(next);
  }

  for (final id in order) {
    final a = from.item(id)!, b = to.item(id)!;
    final withIt = together([
      for (final g in groups[id] ?? const <String>[])
        if (from.item(g) case final i?) i.name.toLowerCase(),
    ]);
    final turn = a.rot != b.rot;
    steps.add(
      PlanStep(
        id: 'move-$id-${b.x}-${b.y}-${b.rot}',
        kind: StepKind.move,
        title:
            'Move the ${a.name.toLowerCase()}${withIt.isEmpty ? '' : ' (with ${withIt.map((n) => n.startsWith('both ') || n.startsWith('all ') ? n : 'the $n').join(' and ')})'}',
        detail: [
          'From ${describePlace(from, a.box)} to ${describePlace(to, b.box)}.',
          if (turn) 'Turn it so it faces ${to.facing(b).label.toLowerCase()}.',
          if (a.spec.has('bed'))
            'Its headboard goes against the ${to.wallDir(b.backWall).label.toLowerCase()} side.',
        ].join(' '),
        tips: [
          if (a.spec.heavy) 'Two people: this one is heavy.',
          if (a.h >= Limits.tall) 'Fix it to the wall with an anti-tip strap once it is in place.',
          if (a.kind == 'rug') 'Lay the rug before the furniture that stands on it.',
        ],
        items: [id, ...?groups[id]],
      ),
    );
  }

  final remaining = plan.after.findings.where((f) => f.severity != Severity.nice).toList();
  final room = to;
  steps.add(
    PlanStep(
      id: 'finish',
      kind: StepKind.finish,
      title: 'Finish and check',
      detail: [
        'Walk the room from the door to every piece: the main route should be about ${mm(Limits.pathMain)} wide.',
        if (remaining.isNotEmpty)
          'Still to sort out by other means: ${remaining.map((f) => f.title.toLowerCase()).join('; ')}.',
      ].join(' '),
      tips: [
        'Layer light: ceiling light for the room, a lamp for each task, and one warm accent light.',
        'Hang art with its centre about 1.45–1.5 m above the floor, or 150–250 mm above a sofa or headboard.',
        if (room.items.any((i) => i.kind == 'rug'))
          'Rugs: under a sofa’s front legs; under a bed, showing about 450 mm each side.',
        'Store things where they are used, everyday items between hip and shoulder height.',
      ],
    ),
  );
  return steps;
}
