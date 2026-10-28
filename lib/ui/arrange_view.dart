import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/analysis.dart';
import '../domain/planner.dart';
import '../domain/space.dart';
import '../domain/steps.dart';
import 'look.dart';
import 'motion.dart';
import 'plan_view.dart';
import 'room_3d.dart';

/// Rearranging a room: run the planner, watch the pieces glide to their new
/// places, keep the plan, then follow it step by step.
class ArrangeView extends ConsumerStatefulWidget {
  const ArrangeView({super.key, required this.room, required this.space});
  final Room room;
  final String space;

  @override
  ConsumerState<ArrangeView> createState() => _ArrangeViewState();
}

class _ArrangeViewState extends ConsumerState<ArrangeView> with SingleTickerProviderStateMixin {
  late final _morph = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  PlanResult? _result;
  bool _busy = false;
  int _seed = 7;

  @override
  void didUpdateWidget(ArrangeView old) {
    super.didUpdateWidget(old);
    // The room changed under a shown result: it no longer applies.
    if (old.room != widget.room && _result != null && _result!.before.room.encode() != widget.room.encode()) {
      _result = null;
    }
  }

  @override
  void dispose() {
    _morph.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      final r = await arrangeInBackground(widget.room, seed: _seed);
      if (!mounted) return;
      setState(() => _result = r);
      _play();
    } catch (e, s) {
      AppErrors.record(e, s);
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _play() {
    if (Motion.reduced(context)) {
      _morph.value = 1;
    } else {
      _morph.forward(from: 0);
    }
  }

  Future<void> _keep() async {
    final r = _result!;
    final id = await ref.mutate(
      (s) => s.book.savePlan(
        room: widget.room.id,
        arranged: r.room,
        before: r.before.overall,
        after: r.after.overall,
      ),
    );
    if (!mounted) return;
    setState(() => _result = null);
    final row = (await ref.read(roomPlansProvider(widget.room.id).future))
        .where((p) => p.id == id)
        .firstOrNull;
    if (row != null && mounted) {
      await Navigator.of(context)
          .push(fluidRoute(StepsPage(plan: row, roomId: widget.room.id, space: widget.space)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final plans = ref.watch(roomPlansProvider(widget.room.id)).value ?? const [];
    final r = _result;
    final movable = widget.room.items.where((i) => !i.fixed).length;
    final children = <Widget>[
      if (r == null)
        SectionCard(
          title: 'Rearrange this room',
          hint: 'arrange.how',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movable == 0
                    ? 'Add some furniture on the Plan tab first; fixed pieces stay where they are.'
                    : 'Vinyasa will try thousands of arrangements of the $movable pieces that can move and keep '
                          'the one that fixes the most for the least lifting.',
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: Motion.medium,
                child: _busy
                    ? const _Thinking(key: ValueKey('busy'))
                    : FilledButton.icon(
                        key: const ValueKey('go'),
                        onPressed: movable == 0 ? null : _run,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Find a better arrangement'),
                      ),
              ),
            ],
          ),
        )
      else ...[
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: math.max(1.0, widget.room.width / widget.room.depth),
                child: RoomPicture(
                  room: r.room,
                  from: r.before.room,
                  morph: _morph,
                  layers: const {PlanLayer.clearance},
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ScoreRing(score: r.before.overall, label: 'Before', size: 56),
                    Icon(Icons.arrow_forward, color: t.colorScheme.onSurfaceVariant),
                    ScoreRing(score: r.after.overall, label: 'After', size: 72),
                    SizedBox(
                      width: 220,
                      child: Text(
                        r.improved
                            ? '${_moved(r)} moved; ${math.max(0, r.before.findings.length - r.after.findings.length)} '
                                  'fewer problems.'
                            : 'This room is already about as good as moving furniture can make it.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (r.improved)
              FilledButton.icon(
                onPressed: _keep,
                icon: const Icon(Icons.checklist),
                label: const Text('Keep and show steps'),
              ),
            OutlinedButton.icon(
              onPressed: _play,
              icon: const Icon(Icons.replay),
              label: const Text('Replay'),
            ),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () {
                      _seed++;
                      _run();
                    },
              icon: const Icon(Icons.shuffle),
              label: const Text('Try another'),
            ),
            TextButton(onPressed: () => setState(() => _result = null), child: const Text('Discard')),
          ],
        ),
        if (r.after.findings.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Still to sort out', style: t.textTheme.titleSmall),
          const SizedBox(height: 4),
          for (final f in r.after.findings.where((f) => f.severity != Severity.nice).take(5))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline, size: 18),
              title: Text(f.title),
              subtitle: f.fix.isEmpty ? null : Text(f.fix),
            ),
        ],
      ],
      if (plans.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('Kept plans', style: t.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final p in plans) _PlanTile(plan: p, roomId: widget.room.id, space: widget.space),
      ],
    ];
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 96 + MediaQuery.paddingOf(context).bottom),
      children: [
        Readable(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: staggered(children)),
        ),
      ],
    );
  }

  String _moved(PlanResult r) {
    final n = r.before.room.items.where((a) {
      final b = r.after.room.item(a.id);
      return b != null && (a.x != b.x || a.y != b.y || a.rot != b.rot);
    }).length;
    return n == 1 ? 'One piece' : '$n pieces';
  }
}

/// A slowly turning nine-square while the planner works.
class _Thinking extends StatefulWidget {
  const _Thinking({super.key});

  @override
  State<_Thinking> createState() => _ThinkingState();
}

class _ThinkingState extends State<_Thinking> with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        RotationTransition(
          turns: _spin,
          child: SizedBox.square(
            dimension: 28,
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < 9; i++)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: i == 4 ? 0.2 : 0.75),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text('Trying arrangements…'),
      ],
    );
  }
}

class _PlanTile extends ConsumerWidget {
  const _PlanTile({required this.plan, required this.roomId, required this.space});
  final PlanRow plan;
  final String roomId;
  final String space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = plan.done.isEmpty ? 0 : plan.done.split(',').length;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ScoreRing(score: plan.scoreAfter, size: 40),
        title: Text('${plan.scoreBefore} → ${plan.scoreAfter}'),
        subtitle: Text('Made ${plan.created.substring(0, 10)}${done > 0 ? ' · $done steps done' : ''}'),
        trailing: IconButton(
          tooltip: 'Delete plan',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => ref.mutate((s) => s.book.removePlan(plan.id)),
        ),
        onTap: () =>
            Navigator.of(context).push(fluidRoute(StepsPage(plan: plan, roomId: roomId, space: space))),
      ),
    );
  }
}

/// A kept plan as steps to tick off, each with the plan lit where it acts.
/// When every step is done the room can take on the new arrangement.
class StepsPage extends ConsumerStatefulWidget {
  const StepsPage({super.key, required this.plan, required this.roomId, required this.space});
  final PlanRow plan;
  final String roomId;
  final String space;

  @override
  ConsumerState<StepsPage> createState() => _StepsPageState();
}

class _StepsPageState extends ConsumerState<StepsPage> with SingleTickerProviderStateMixin {
  late final _done = {...widget.plan.done.split(',').where((s) => s.isNotEmpty)};
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  int _at = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !Motion.reduced(context)) _pulse.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _tick(PlanStep s, bool on) async {
    setState(() => on ? _done.add(s.id) : _done.remove(s.id));
    await ref.mutate((x) => x.book.setStepsDone(widget.plan.id, _done));
  }

  /// Moves the pieces of the room as it is [now] to where [arranged] put
  /// them, so changes made since the plan (a new name, a new piece) stay.
  Future<void> _apply(Room now, Room arranged) async {
    final placed = {for (final i in arranged.items) i.id: i};
    final room = now.copyWith(
      items: [
        for (final i in now.items)
          if (placed[i.id] case final p?) i.copyWith(x: p.x, y: p.y, rot: p.rot) else i,
      ],
    );
    await ref.mutate((s) => s.book.saveRoom(room, space: widget.space, score: analyse(room).overall));
    if (!mounted) return;
    showMessage(context, 'The room now has its new arrangement.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final now = ref.watch(roomProvider(widget.roomId)).value;
    if (now == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final arranged = Room.decode(widget.plan.json);
    final result = PlanResult(analyse(now), analyse(arranged));
    final steps = stepsFor(result);
    _at = _at.clamp(0, steps.length - 1);
    final step = steps[_at];
    final allDone = steps.every((s) => _done.contains(s.id));
    final plan = Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: math.max(1.0, now.width / now.depth),
        child: AnimatedSwitcher(
          duration: Motion.medium,
          child: RoomPicture(
            key: ValueKey(step.id),
            room: step.kind == StepKind.prepare ? now : arranged,
            highlight: {...step.items},
            pulse: _pulse,
            layers: {if (step.kind == StepKind.finish) PlanLayer.path},
          ),
        ),
      ),
    );
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, s) in steps.indexed)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: i == _at ? t.colorScheme.primary.withValues(alpha: 0.08) : null,
            child: InkWell(
              borderRadius: BorderRadius.circular(VinColors.of(context).radius),
              onTap: () => setState(() => _at = i),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(value: _done.contains(s.id), onChanged: (v) => _tick(s, v ?? false)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            '${i + 1}. ${s.title}',
                            style: t.textTheme.titleSmall?.copyWith(
                              decoration: _done.contains(s.id) ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (s.detail.isNotEmpty) ...[const SizedBox(height: 4), Text(s.detail)],
                          if (i == _at)
                            for (final tip in s.tips)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.tips_and_updates_outlined,
                                      size: 16,
                                      color: t.colorScheme.tertiary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(tip, style: t.textTheme.bodySmall)),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: allDone ? () => _apply(now, arranged) : null,
          icon: const Icon(Icons.done_all),
          label: Text(allDone ? 'Done: update the room' : 'Tick every step to update the room'),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Plan ${widget.plan.scoreBefore} → ${widget.plan.scoreAfter}'),
        actions: [HintIconButton('arrange.steps', icon: Icons.help_outline, label: 'Steps')],
      ),
      body: LayoutBuilder(
        builder: (context, c) => c.maxWidth >= 900
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(padding: const EdgeInsets.all(16), child: plan),
                  ),
                  SizedBox(
                    width: 440,
                    child: ListView(padding: const EdgeInsets.fromLTRB(0, 16, 16, 32), children: [list]),
                  ),
                ],
              )
            : ListView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 32 + MediaQuery.paddingOf(context).bottom),
                children: [plan, const SizedBox(height: 12), list],
              ),
      ),
    );
  }
}
