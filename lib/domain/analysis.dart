/// The analysis: every rule that applies to a room, run against it, and
/// the findings rolled up into a score per category and overall.
library;

import 'dart:math' as math;

import 'grid.dart';
import 'rules.dart';
import 'space.dart';

enum Severity {
  must('Must fix', 30),
  should('Should fix', 12),
  nice('Nice to have', 4);

  const Severity(this.label, this.penalty);
  final String label;
  final int penalty;
}

/// One thing a rule noticed.
class Finding {
  const Finding({
    required this.rule,
    required this.category,
    required this.severity,
    required this.title,
    required this.detail,
    this.fix = '',
    this.items = const [],
    this.weight = 1.0,
  });

  final String rule;
  final Category category;
  final Severity severity;

  /// Short, in the imperative or as a fact: "Wardrobe doors are blocked".
  final String title;

  /// Why it matters, with the measured numbers.
  final String detail;

  /// What to do about it.
  final String fix;

  /// Ids of the items involved, for highlighting on the plan.
  final List<String> items;

  /// How bad, 0 to 1 of the severity's penalty (a path 50 mm short is
  /// milder than one 400 mm short).
  final double weight;

  double get penalty => severity.penalty * weight.clamp(0.1, 1.0);
}

/// Everything a rule may ask about the room, worked out once.
class Ctx {
  Ctx(this.room) : grid = FloorGrid.of(room);
  Ctx.withGrid(this.room, this.grid);

  final Room room;
  final FloorGrid grid;

  Iterable<Item> tagged(String tag) => room.items.where((i) => i.spec.has(tag));
  Iterable<Item> kinds(Set<String> ids) => room.items.where((i) => ids.contains(i.kind));
  Iterable<Item> get blocking => room.items.where((i) => i.spec.blocks);
}

typedef Check = Iterable<Finding> Function(Ctx ctx);

/// A rule: when it applies and what it checks.
class Rule {
  const Rule(this.id, this.category, this.check, {this.types});
  final String id;
  final Category category;
  final Check check;

  /// The room types it applies to; null for every room.
  final Set<RoomType>? types;

  bool appliesTo(Room room) => types == null || types!.contains(room.type);
}

class Report {
  const Report(this.room, this.findings, this.scores, this.overall, this.freeShare);
  final Room room;
  final List<Finding> findings;
  final Map<Category, int> scores;
  final int overall;

  /// Share of the floor free to walk on, 0 to 1.
  final double freeShare;

  /// Total weighted penalty: what the planner minimises.
  double get cost => costOf(room, findings);

  List<Finding> of(Category c) => findings.where((f) => f.category == c).toList();
}

/// Weighted penalty of [findings] in [room]: categories the user cares
/// more about count more; ones turned off count nothing.
double costOf(Room room, Iterable<Finding> findings) {
  var sum = 0.0;
  for (final f in findings) {
    sum += f.penalty * room.weight(f.category);
  }
  return sum;
}

/// Runs every applicable rule. [grid] may be passed in when the caller
/// already built one (the planner does).
Report analyse(Room room, {FloorGrid? grid}) {
  final ctx = grid == null ? Ctx(room) : Ctx.withGrid(room, grid);
  final findings = <Finding>[
    for (final rule in allRules)
      if (rule.appliesTo(room) && (rule.category != Category.vaastu || room.vaastu != VaastuMode.off))
        ...rule.check(ctx),
  ];
  findings.sort((a, b) {
    final s = a.severity.index.compareTo(b.severity.index);
    return s != 0 ? s : b.weight.compareTo(a.weight);
  });
  final scores = {
    for (final c in Category.values)
      c: (100 - findings.where((f) => f.category == c).fold(0.0, (s, f) => s + f.penalty)).round().clamp(
        0,
        100,
      ),
  };
  var total = 0.0, weights = 0;
  for (final c in Category.values) {
    final w = room.weight(c);
    total += scores[c]! * w;
    weights += w;
  }
  final overall = weights == 0 ? 100 : (total / weights).round();
  return Report(room, findings, scores, math.max(0, overall), ctx.grid.freeShare);
}
