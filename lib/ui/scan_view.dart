import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/scan_media.dart';
import '../db/database.dart';
import '../domain/space.dart';
import '../domain/vision.dart';
import 'motion.dart';
import 'plan_view.dart';
import 'room_form.dart';
import 'room_page.dart';

/// Makes a plan of [room] from its photos and videos with the AI chosen in
/// Ask AI's settings: asks first, sends, then shows the result to check.
Future<void> startScan(BuildContext context, WidgetRef ref, Room room, String space) async {
  final media = ref.read(mediaProvider(room.id)).value ?? const <MediaRow>[];
  final setup = await ref.read(helpAiProvider.future);
  if (!context.mounted) return;
  if (!canSee(setup.via)) {
    final change = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose an AI that can see'),
        content: Text(
          'Making a plan from photos needs an AI that reads images: a free Gemini key, an Anthropic, '
          'OpenAI or OpenRouter key, or a vision model on your own computer. '
          'Ask AI is set to “${setup.via.label}”.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Set up Ask AI')),
        ],
      ),
    );
    if (change == true && context.mounted) await showAskAiSetup(context);
    return;
  }
  final choice = await showDialog<_ScanChoice>(
    context: context,
    builder: (context) => _ScanDialog(room: room, media: media, setup: setup),
  );
  if (choice == null || !context.mounted) return;
  await Navigator.of(context)
      .push(fluidRoute<void>(_ScanPage(room: room, space: space, setup: setup, choice: choice)));
}

class _ScanChoice {
  const _ScanChoice(this.media, this.known);
  final List<MediaRow> media;
  final KnownSize known;
}

/// Which pictures to send and what is known for sure, with a plain account
/// of what leaves the device.
class _ScanDialog extends StatefulWidget {
  const _ScanDialog({required this.room, required this.media, required this.setup});
  final Room room;
  final List<MediaRow> media;
  final HelpAiSetup setup;

  @override
  State<_ScanDialog> createState() => _ScanDialogState();
}

class _ScanDialogState extends State<_ScanDialog> {
  late final _picked = {for (final m in widget.media) m.id};
  bool _sizeKnown = true;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final r = widget.room;
    final picked = widget.media.where((m) => _picked.contains(m.id)).toList();
    final videos = picked.where((m) => m.kind == 'video').length;
    final whole = takesVideo(widget.setup.via);
    return AlertDialog(
      title: const Text('Make a plan from photos'),
      content: SizedBox(
        width: 460,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final m in widget.media)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _picked.contains(m.id),
                onChanged: (v) => setState(() => v == true ? _picked.add(m.id) : _picked.remove(m.id)),
                secondary: Icon(m.kind == 'video' ? Icons.videocam_outlined : Icons.photo_outlined),
                title: Text(
                  m.path.split(RegExp(r'[\\/]')).last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _sizeKnown,
              onChanged: (v) => setState(() => _sizeKnown = v),
              title: Text('The room is ${metresText(r.width)} × ${metresText(r.depth)} m'),
              subtitle: const Text(
                'Photos cannot show true size. If you measured the room, the plan is scaled to it; '
                'otherwise sizes are judged from doors and furniture.',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sending ${picked.length - videos} photo${picked.length - videos == 1 ? '' : 's'}'
              '${videos == 0
                  ? ''
                  : whole
                  ? ' and $videos video${videos == 1 ? '' : 's'}'
                  : ' and frames from $videos video${videos == 1 ? '' : 's'}'}'
              ' to ${widget.setup.via.label}'
              '${widget.setup.via == HelpAi.local ? ' at ${widget.setup.effectiveBase}' : ''}. '
              'Photos are made smaller and their location and camera details removed first. '
              'Nothing else about you or your rooms is sent.',
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              'Take the first photo facing the wall you want at the top of the plan.',
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: picked.isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  _ScanChoice(
                    picked,
                    _sizeKnown
                        ? KnownSize(width: r.width, depth: r.depth, type: r.type)
                        : KnownSize(type: r.type),
                  ),
                ),
          icon: const Icon(Icons.send_outlined),
          label: const Text('Send'),
        ),
      ],
    );
  }
}

/// Prepares and sends the pictures, then shows the plan the AI drew for
/// the user to check and keep.
class _ScanPage extends ConsumerStatefulWidget {
  const _ScanPage({required this.room, required this.space, required this.setup, required this.choice});
  final Room room;
  final String space;
  final HelpAiSetup setup;
  final _ScanChoice choice;

  @override
  ConsumerState<_ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<_ScanPage> {
  String _step = 'Preparing the photos';
  Object? _error;
  RoomDraft? _draft;
  final _left = <String>{};

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _error = null;
      _draft = null;
      _step = 'Preparing the photos';
    });
    try {
      final media = await prepareMedia(
        widget.choice.media,
        wholeVideo: takesVideo(widget.setup.via),
        step: (s) => mounted ? setState(() => _step = s) : null,
      );
      if (!mounted) return;
      setState(() => _step = 'Waiting for ${widget.setup.via.label} to read the room');
      final asker = await ref.read(visionAskerProvider)(widget.setup);
      final draft = await asker.read(widget.room, media, widget.choice.known);
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _left
          ..clear()
          ..addAll([
            for (final i in draft.items)
              if (i.unsure) i.value.id,
          ]);
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Room get _kept {
    final d = _draft!;
    return d.room.copyWith(
      items: [
        for (final i in d.items)
          if (!_left.contains(i.value.id)) i.value,
      ],
    );
  }

  Future<void> _use() async {
    final had = widget.room.items.length + widget.room.openings.length;
    if (had > 0) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace the current plan?'),
          content: Text(
            'The room’s $had doors, windows and pieces are replaced by these. '
            'Its name, occupants and settings stay.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Replace')),
          ],
        ),
      );
      if (yes != true) return;
    }
    final kept = _kept;
    // Fresh ids, so nothing clashes with what the room had before.
    final room = kept.copyWith(
      openings: [
        for (final o in kept.openings) Opening.fromJson({...o.toJson(), 'id': newId()}),
      ],
      items: [
        for (final i in kept.items) Item.fromJson({...i.toJson(), 'id': newId()}),
      ],
    );
    await storeRoom(ref, room, widget.space);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    return Scaffold(
      appBar: AppBar(title: Text('Plan of ${widget.room.name}')),
      body: switch ((draft, _error)) {
        (_, final Object e) => EmptyState(
          icon: Icons.error_outline,
          title: 'The plan could not be made',
          message: e is UserFacingError ? '$e' : 'Something went wrong: $e',
          actions: [FilledButton(onPressed: _run, child: const Text('Try again'))],
        ),
        (null, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: Motion.short,
                child: Text(_step, key: ValueKey(_step)),
              ),
            ],
          ),
        ),
        (final RoomDraft d, _) => _review(context, d),
      },
    );
  }

  Widget _review(BuildContext context, RoomDraft d) {
    final t = Theme.of(context);
    final plan = PlanView(
      room: _kept,
      highlight: {
        for (final i in d.items)
          if (i.unsure) i.value.id,
      },
    );
    final list = [
      if (d.notes.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(d.notes, style: t.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
        ),
      Text(
        '${metresText(d.room.width)} × ${metresText(d.room.depth)} m, '
        '${d.openings.length} door${d.openings.length == 1 ? '' : 's'} and window${d.openings.length == 1 ? '' : 's'}. '
        'Untick anything that is wrong; unsure guesses start unticked and glow on the plan.',
        style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
      ),
      for (final s in d.items)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: !_left.contains(s.value.id),
          onChanged: (v) => setState(() => v == true ? _left.remove(s.value.id) : _left.add(s.value.id)),
          secondary: Icon(kindIcon(s.value.spec)),
          title: Text(s.value.name),
          subtitle: Text(
            '${metresText(s.value.w)} × ${metresText(s.value.d)} m · '
            '${s.unsure ? 'unsure' : 'sure'} (${(s.confidence * 100).round()}%)',
          ),
        ),
      if (d.items.isEmpty) const Text('No furniture was recognised; you can add it on the plan.'),
    ];
    final buttons = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(onPressed: _use, icon: const Icon(Icons.check), label: const Text('Use this plan')),
        OutlinedButton(onPressed: _run, child: const Text('Ask again')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Discard')),
      ],
    );
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 840;
        final side = ListView(
          padding: const EdgeInsets.all(16),
          children: [...list, const SizedBox(height: 16), buttons],
        );
        if (wide) {
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(padding: const EdgeInsets.all(16), child: plan),
              ),
              SizedBox(width: 380, child: side),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AspectRatio(aspectRatio: d.room.width / d.room.depth, child: plan),
            const SizedBox(height: 12),
            ...list,
            const SizedBox(height: 16),
            buttons,
          ],
        );
      },
    );
  }
}
