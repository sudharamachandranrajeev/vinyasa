import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';

import '../domain/space.dart';
import 'motion.dart';

/// Millimetres as metres for a text field: 3600 → "3.6".
String metresText(int mm) {
  final s = (mm / 1000).toStringAsFixed(2);
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Metres typed by a person ("3.6", "3,6", "3.6 m") as millimetres, or null.
int? parseMetres(String text) {
  final v = double.tryParse(text.trim().replaceAll(',', '.').replaceAll(RegExp(r'\s*m$'), ''));
  return v == null || v <= 0 ? null : (v * 1000).round();
}

String? _lengthError(String? text, {double min = 0.5, double max = 100}) {
  final mm = parseMetres(text ?? '');
  if (mm == null) return 'Metres, like 3.6';
  if (mm < min * 1000 || mm > max * 1000) return 'From $min to $max m';
  return null;
}

/// Asks for a space's name and kind.
Future<({String name, SpaceKind kind})?> editSpace(
  BuildContext context, {
  String name = '',
  SpaceKind kind = SpaceKind.home,
}) => showDialog(
  context: context,
  builder: (context) => _SpaceDialog(name: name, kind: kind),
);

class _SpaceDialog extends StatefulWidget {
  const _SpaceDialog({required this.name, required this.kind});
  final String name;
  final SpaceKind kind;

  @override
  State<_SpaceDialog> createState() => _SpaceDialogState();
}

class _SpaceDialogState extends State<_SpaceDialog> {
  late final _name = TextEditingController(text: widget.name);
  late var _kind = widget.kind;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _done() {
    if (_name.text.trim().isEmpty) return;
    Navigator.pop(context, (name: _name.text.trim(), kind: _kind));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.name.isEmpty ? 'New space' : 'Edit space'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Name', hintText: 'Home, Office, Corner shop'),
            onSubmitted: (_) => _done(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in SpaceKind.values)
                ChoiceChip(
                  label: Text(k.label),
                  selected: k == _kind,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _done, child: const Text('Save')),
    ],
  );
}

/// The room's size, use, compass bearing, people and priorities, on a page
/// of its own. Returns the edited room, or null when cancelled.
Future<Room?> editRoom(BuildContext context, Room room, {bool isNew = false}) =>
    Navigator.of(context).push<Room>(fluidRoute(RoomForm(room: room, isNew: isNew)));

class RoomForm extends StatefulWidget {
  const RoomForm({super.key, required this.room, this.isNew = false});
  final Room room;
  final bool isNew;

  @override
  State<RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends State<RoomForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.room.name);
  late final _width = TextEditingController(text: metresText(widget.room.width));
  late final _depth = TextEditingController(text: metresText(widget.room.depth));
  late final _height = TextEditingController(text: metresText(widget.room.height));
  late final _notes = TextEditingController(text: widget.room.notes);
  late var _type = widget.room.type;
  late var _north = widget.room.northDeg;
  late var _vaastu = widget.room.vaastu;
  late var _occupants = widget.room.occupants;
  late final _weights = {for (final c in Category.values) c: widget.room.weights[c] ?? 1};

  @override
  void dispose() {
    for (final c in [_name, _width, _depth, _height, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final width = parseMetres(_width.text)!, depth = parseMetres(_depth.text)!;
    final r = widget.room;
    // Shrinking the room keeps everything inside it.
    final items = [
      for (final i in r.items)
        i.copyWith(
          x: i.x.clamp(0, math.max(0, width - i.footW)),
          y: i.y.clamp(0, math.max(0, depth - i.footD)),
        ),
    ];
    final openings = [
      for (final o in r.openings)
        if (o.width <= (o.wall.horizontal ? width : depth))
          o.copyWith(offset: o.offset.clamp(0, (o.wall.horizontal ? width : depth) - o.width)),
    ];
    Navigator.pop(
      context,
      r.copyWith(
        name: _name.text.trim(),
        type: _type,
        width: width,
        depth: depth,
        height: parseMetres(_height.text)!,
        northDeg: _north,
        vaastu: _vaastu,
        occupants: _occupants,
        weights: {
          for (final c in Category.values)
            if (c != Category.vaastu && _weights[c] != 1) c: _weights[c]!,
        },
        notes: _notes.text.trim(),
        items: items,
        openings: openings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final soft = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New room' : 'Room details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 32 + MediaQuery.paddingOf(context).bottom),
          children: [
            Readable(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: staggered([
                  SectionCard(
                    title: 'The room',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _name,
                          autofocus: widget.isNew,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (v) => (v ?? '').trim().isEmpty ? 'Give it a name' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<RoomType>(
                          initialValue: _type,
                          decoration: const InputDecoration(labelText: 'Used as'),
                          items: [
                            for (final r in RoomType.values) DropdownMenuItem(value: r, child: Text(r.label)),
                          ],
                          onChanged: (v) => setState(() => _type = v ?? _type),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _length(_width, 'Width (m)', 'along the top wall')),
                            const SizedBox(width: 12),
                            Expanded(child: _length(_depth, 'Depth (m)', 'top wall to bottom')),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _length(_height, 'Height (m)', 'floor to ceiling', min: 1.8, max: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SectionCard(
                    title: 'Which way it faces',
                    hint: 'room.north',
                    child: Row(
                      children: [
                        _Compass(_north),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'The top wall faces ${Dir8.ofBearing(_north).label.toLowerCase()} '
                                '(${_north.round()}°)',
                              ),
                              Slider(
                                value: _north,
                                max: 359,
                                divisions: 359,
                                label: '${_north.round()}°',
                                onChanged: (v) => setState(() => _north = v),
                              ),
                              Wrap(
                                spacing: 6,
                                children: [
                                  for (final d in const [Dir8.n, Dir8.e, Dir8.s, Dir8.w])
                                    ActionChip(
                                      label: Text(d.short),
                                      onPressed: () => setState(() => _north = d.bearing),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SectionCard(
                    title: 'Who uses it',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(child: Text('People')),
                            IconButton(
                              tooltip: 'Fewer',
                              onPressed: _occupants.people <= 1
                                  ? null
                                  : () => setState(
                                      () => _occupants = _occupants.copyWith(people: _occupants.people - 1),
                                    ),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('${_occupants.people}', style: t.textTheme.titleMedium?.merge(tabular)),
                            IconButton(
                              tooltip: 'More',
                              onPressed: () => setState(
                                () => _occupants = _occupants.copyWith(people: _occupants.people + 1),
                              ),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('Wheelchair user'),
                              selected: _occupants.wheelchair,
                              onSelected: (v) =>
                                  setState(() => _occupants = _occupants.copyWith(wheelchair: v)),
                            ),
                            FilterChip(
                              label: const Text('Older people'),
                              selected: _occupants.elderly,
                              onSelected: (v) => setState(() => _occupants = _occupants.copyWith(elderly: v)),
                            ),
                            FilterChip(
                              label: const Text('Young children'),
                              selected: _occupants.children,
                              onSelected: (v) =>
                                  setState(() => _occupants = _occupants.copyWith(children: v)),
                            ),
                            FilterChip(
                              label: const Text('Left-handed'),
                              selected: _occupants.leftHanded,
                              onSelected: (v) =>
                                  setState(() => _occupants = _occupants.copyWith(leftHanded: v)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Wider walkways, turning space and anti-tip advice follow from these.',
                          style: soft,
                        ),
                      ],
                    ),
                  ),
                  SectionCard(
                    title: 'What matters most',
                    hint: 'room.weights',
                    child: Column(
                      children: [
                        for (final c in Category.values.where((c) => c != Category.vaastu))
                          Row(
                            children: [
                              SizedBox(width: 84, child: Text(c.label)),
                              Expanded(
                                child: Slider(
                                  value: _weights[c]!.toDouble(),
                                  max: 3,
                                  divisions: 3,
                                  label: const ['Off', 'Normal', 'More', 'Most'][_weights[c]!],
                                  onChanged: (v) => setState(() => _weights[c] = v.round()),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const SizedBox(width: 84, child: Text('Vaastu')),
                            Expanded(
                              child: SegmentedButton<VaastuMode>(
                                segments: [
                                  for (final m in VaastuMode.values)
                                    ButtonSegment(value: m, label: Text(m.label)),
                                ],
                                selected: {_vaastu},
                                onSelectionChanged: (s) => setState(() => _vaastu = s.first),
                              ),
                            ),
                            Hint(
                              'room.vaastu',
                              child: Icon(
                                Icons.info_outline,
                                size: 18,
                                color: t.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SectionCard(
                    title: 'Notes',
                    child: TextField(
                      controller: _notes,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Anything to remember: a radiator, a beam, a pet',
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _length(
    TextEditingController c,
    String label,
    String helper, {
    double min = 0.5,
    double max = 100,
  }) => TextFormField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, helperText: helper),
    validator: (v) => _lengthError(v, min: min, max: max),
  );
}

/// A compass rose turned so north points where it would with the plan's
/// top wall facing [bearing].
class _Compass extends StatelessWidget {
  const _Compass(this.bearing);
  final double bearing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SizedBox.square(
      dimension: 72,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: -bearing * math.pi / 180),
        duration: Motion.reduced(context) ? Duration.zero : Motion.medium,
        curve: Motion.curve,
        builder: (context, a, _) => Transform.rotate(
          angle: a,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.colorScheme.outlineVariant),
                ),
              ),
              Icon(Icons.navigation, color: t.colorScheme.error, size: 30),
              Align(
                alignment: Alignment.topCenter,
                child: Text('N', style: t.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
