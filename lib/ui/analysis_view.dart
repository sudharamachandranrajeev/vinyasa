import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart' hide Finding;
import 'package:flutter/material.dart';

import '../domain/analysis.dart';
import '../domain/space.dart';
import 'look.dart';
import 'motion.dart';
import 'plan_view.dart';

/// The report on a room: the scores, then each finding with why and what
/// to do; picking a finding lights up the pieces it is about on the plan.
class AnalysisView extends StatefulWidget {
  const AnalysisView({super.key, required this.report, this.onArrange});
  final Report report;
  final VoidCallback? onArrange;

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  Finding? _picked;
  Category? _only;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _pick(Finding f) {
    setState(() => _picked = identical(_picked, f) ? null : f);
    if (_picked == null || Motion.reduced(context)) {
      _pulse.stop();
      _pulse.value = 1;
    } else {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final t = Theme.of(context);
    final shown = [
      for (final f in r.findings)
        if (_only == null || f.category == _only) f,
    ];
    final scores = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 20,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Hint(
              'room.score',
              child: ScoreRing(score: r.overall, label: 'Overall', size: 96),
            ),
            for (final c in Category.values)
              if (r.room.weight(c) > 0)
                Pressable(
                  onTap: () => setState(() => _only = _only == c ? null : c),
                  child: AnimatedOpacity(
                    opacity: _only == null || _only == c ? 1 : 0.4,
                    duration: Motion.short,
                    child: ScoreRing(score: r.scores[c]!, label: c.label, size: 60),
                  ),
                ),
            SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Free floor ${(r.freeShare * 100).round()}%', style: t.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Meter(value: r.freeShare / 0.6, color: VinColors.of(context).zone),
                  const SizedBox(height: 6),
                  Text(
                    r.findings.isEmpty
                        ? 'Nothing to fix.'
                        : '${r.findings.where((f) => f.severity == Severity.must).length} must, '
                              '${r.findings.where((f) => f.severity == Severity.should).length} should, '
                              '${r.findings.where((f) => f.severity == Severity.nice).length} nice to have',
                    style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    final plan = Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: math.max(1.0, r.room.width / r.room.depth),
        child: PlanView(
          room: r.room,
          highlight: {...?_picked?.items},
          pulse: _pulse,
          layers: {
            if (_picked?.category == Category.vaastu) PlanLayer.vaastu,
            if (_picked?.category == Category.accessibility) PlanLayer.path,
            if (_picked?.rule.startsWith('clear') ?? false) PlanLayer.clearance,
          },
        ),
      ),
    );
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (shown.isEmpty)
          const EmptyState(
            icon: Icons.verified_outlined,
            title: 'Nothing to fix here',
            message: 'Every rule that applies to this room passes.',
          ),
        ...staggered([
          for (final f in shown) _FindingCard(f, picked: identical(f, _picked), onTap: () => _pick(f)),
        ]),
      ],
    );
    return LayoutBuilder(
      builder: (context, c) {
        final arrange = widget.onArrange == null || r.findings.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton.icon(
                  onPressed: widget.onArrange,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Find a better arrangement'),
                ),
              );
        if (c.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: math.min(520, c.maxWidth * 0.45),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [scores, const SizedBox(height: 12), plan, arrange],
                ),
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(0, 16, 16, 96), children: [list]),
              ),
            ],
          );
        }
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 96 + MediaQuery.paddingOf(context).bottom),
          children: [scores, const SizedBox(height: 12), plan, arrange, const SizedBox(height: 12), list],
        );
      },
    );
  }
}

Color severityColor(Severity s) => switch (s) {
  Severity.must => StatusColors.critical,
  Severity.should => StatusColors.warning,
  Severity.nice => const Color(0xFF6B8FB5),
};

IconData categoryIcon(Category c) => switch (c) {
  Category.efficiency => Icons.open_in_full,
  Category.accessibility => Icons.accessible_forward,
  Category.ergonomics => Icons.self_improvement,
  Category.aesthetics => Icons.auto_awesome_outlined,
  Category.vaastu => Icons.explore_outlined,
};

class _FindingCard extends StatelessWidget {
  const _FindingCard(this.f, {required this.picked, required this.onTap});
  final Finding f;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final colour = severityColor(f.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.reduced(context) ? Duration.zero : Motion.medium,
          curve: Motion.curve,
          decoration: BoxDecoration(
            color: picked ? colour.withValues(alpha: 0.1) : t.cardTheme.color,
            borderRadius: BorderRadius.circular(VinColors.of(context).radius),
            border: Border.all(color: picked ? colour : VinColors.of(context).line),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(categoryIcon(f.category), size: 18, color: colour),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f.title, style: t.textTheme.titleSmall)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colour.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(f.severity.label, style: t.textTheme.labelSmall?.copyWith(color: colour)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(f.detail, style: t.textTheme.bodyMedium),
              AnimatedSize(
                duration: Motion.reduced(context) ? Duration.zero : Motion.medium,
                curve: Motion.curve,
                alignment: Alignment.topCenter,
                child: picked && f.fix.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline, size: 18, color: t.colorScheme.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                f.fix,
                                style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
