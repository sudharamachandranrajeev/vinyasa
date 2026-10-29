import 'dart:convert';
import 'dart:typed_data';

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';

import '../domain/space.dart';
import '../domain/stored.dart';
import 'common.dart';
import 'motion.dart';
import 'scan_view.dart';

/// What the room's storage holds, and where each thing should go.
class StorageView extends ConsumerWidget {
  const StorageView({super.key, required this.room, required this.space, required this.onChanged});
  final Room room;
  final String space;
  final ValueChanged<Room> onChanged;

  void _set(List<Thing> things) => onChanged(room.copyWith(things: things));

  Future<void> _edit(BuildContext context, Thing? old) async {
    final made = await showDialog<List<Thing>>(
      context: context,
      builder: (_) => _ThingDialog(old: old, work: !room.type.residential),
    );
    if (made == null) return;
    _set(
      old == null
          ? [...room.things, ...made]
          : [for (final t in room.things) t.id == old.id ? made.single : t],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final plan = organise(room);
    final photos = ref.watch(mediaProvider(room.id)).value?.isNotEmpty ?? false;
    final muted = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    final today = DateTime.now();
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 96 + MediaQuery.paddingOf(context).bottom),
      children: [
        Readable(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: staggered([
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'List what the room’s wardrobes, shelves and cabinets hold. Vinyasa says which shelf '
                      'each thing belongs on, for ${_who(room.occupants)}.',
                      style: muted,
                    ),
                  ),
                  Hint(
                    'storage.how',
                    child: Icon(Icons.info_outline, size: 18, color: t.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              if (plan.units.isEmpty)
                const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No storage in this room yet',
                  message:
                      'Add a wardrobe, shelf, cabinet or rack on the Plan tab, then list what goes in it.',
                )
              else ...[
                SectionCard(
                  title: 'Things to store',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final th in room.things)
                        _ThingTile(
                          th,
                          today,
                          onEdit: () => _edit(context, th),
                          onRemove: () {
                            _set([
                              for (final x in room.things)
                                if (x.id != th.id) x,
                            ]);
                          },
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: () => _edit(context, null),
                              icon: const Icon(Icons.add),
                              label: const Text('Add things'),
                            ),
                            OutlinedButton.icon(
                              onPressed: photos ? () => startStorageScan(context, ref, room, space) : null,
                              icon: const Icon(Icons.auto_fix_high_outlined),
                              label: const Text('List from photos'),
                            ),
                            if (!photos)
                              Text(
                                'Add photos of the open cupboards on the Photos tab to list from them.',
                                style: muted,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (room.things.isNotEmpty) ...[
                  SectionCard(
                    title: 'Where things go',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reach: ${plan.reach.describe}.', style: muted),
                        const SizedBox(height: 8),
                        for (final u in plan.units) _UnitCard(plan, u),
                        if (plan.unplaced.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('No space for', style: t.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            '${plan.unplaced.map((x) => x.name).join(', ')}. Let some go, or add storage that '
                            'suits them.',
                            style: t.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SectionCard(
                    title: 'Steps',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (i, s) in plan.steps.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.title, style: t.textTheme.titleSmall),
                                      Text(s.detail, style: t.textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: plan.placed.isEmpty
                            ? null
                            : () => saveBytes(
                                context,
                                '${room.name} labels.html',
                                Uint8List.fromList(utf8.encode(labelSheet(plan, room.name))),
                                mime: 'text/html',
                              ),
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Save a label sheet'),
                      ),
                      OutlinedButton.icon(
                        onPressed: plan.placed.isEmpty
                            ? null
                            : () => copyText(context, labelText(plan), what: 'List copied.'),
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copy the list'),
                      ),
                    ],
                  ),
                ],
              ],
            ]),
          ),
        ),
      ],
    );
  }

  static String _who(Occupants o) => o.wheelchair
      ? 'wheelchair reach'
      : o.elderly
      ? 'older people’s reach'
      : 'adult reach';
}

class _ThingTile extends StatelessWidget {
  const _ThingTile(this.thing, this.today, {required this.onEdit, required this.onRemove});
  final Thing thing;
  final DateTime today;
  final VoidCallback onEdit, onRemove;

  @override
  Widget build(BuildContext context) {
    final age = tagAge(thing, today);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        age == null ? Icons.inventory_2_outlined : Icons.sell_outlined,
        color: age != null && age > tagDays ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(thing.name),
      subtitle: Text(
        [
          thing.stuff.label,
          thing.use.label.toLowerCase(),
          if (thing.heavy) 'heavy',
          if (age != null)
            age > tagDays
                ? 'red tag: ${age - tagDays} days overdue'
                : 'red tag: decide in ${tagDays - age} days',
        ].join(' · '),
      ),
      onTap: onEdit,
      trailing: IconButton(
        tooltip: 'Remove ${thing.name}',
        icon: const Icon(Icons.delete_outline),
        onPressed: onRemove,
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard(this.plan, this.u);
  final StoragePlan plan;
  final Unit u;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final s = t.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(u.name, style: t.textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final sh in u.shelves.reversed)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: sh.zone == Zone.prime
                      ? s.primaryContainer
                      : sh.zone.easy
                      ? s.surfaceContainerHigh
                      : s.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 118,
                      child: Text(
                        'Shelf ${sh.level + 1} · ${sh.zone.label}\n${sh.bottom}–${sh.top} mm',
                        style: t.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant),
                      ),
                    ),
                    Expanded(
                      child: plan.on(sh, u).isEmpty
                          ? Text('empty', style: t.textTheme.bodySmall?.copyWith(color: s.onSurfaceVariant))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final p in plan.on(sh, u))
                                  Tooltip(
                                    message: p.why,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        p.compromise ? '${p.thing.name} (${p.why})' : p.thing.name,
                                        style: p.compromise ? TextStyle(color: s.error) : null,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThingDialog extends StatefulWidget {
  const _ThingDialog({required this.old, required this.work});
  final Thing? old;
  final bool work;

  @override
  State<_ThingDialog> createState() => _ThingDialogState();
}

class _ThingDialogState extends State<_ThingDialog> {
  late final _name = TextEditingController(text: widget.old?.name ?? '');
  late var _stuff = widget.old?.stuff ?? Stuff.misc;
  late var _use = widget.old?.use ?? Use.weekly;
  late var _heavy = widget.old?.heavy ?? false;
  late var _tag = (widget.old?.tagged ?? '').isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _today {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void _save() {
    final old = widget.old;
    final names = old != null
        ? [_name.text.trim()]
        : [
            for (final n in _name.text.split(RegExp(r'[,\n]')))
              if (n.trim().isNotEmpty) n.trim(),
          ];
    if (names.isEmpty || names.first.isEmpty) return;
    Navigator.pop(context, [
      for (final n in names)
        Thing(
          id: old?.id ?? newId(),
          name: n,
          stuff: _stuff,
          use: _use,
          heavy: _heavy,
          // Keep the original day when it stays tagged.
          tagged: !_tag
              ? ''
              : (old?.tagged.isNotEmpty ?? false)
              ? old!.tagged
              : _today,
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.old == null ? 'Add things' : 'Edit thing'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: widget.old == null ? 'Name (several, separated by commas)' : 'Name',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Stuff>(
              initialValue: _stuff,
              decoration: const InputDecoration(labelText: 'Sort of thing'),
              items: [for (final s in Stuff.values) DropdownMenuItem(value: s, child: Text(s.label))],
              onChanged: (v) => setState(() => _stuff = v ?? _stuff),
            ),
            const SizedBox(height: 12),
            const Text('How often is it used?'),
            const SizedBox(height: 6),
            SegmentedButton<Use>(
              showSelectedIcon: false,
              segments: [for (final u in Use.values) ButtonSegment(value: u, label: Text(u.label))],
              selected: {_use},
              onSelectionChanged: (v) => setState(() => _use = v.first),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Heavy (two hands, or about 10 kg)'),
              value: _heavy,
              onChanged: (v) => setState(() => _heavy = v),
            ),
            if (widget.work)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Red-tag: not sure it is needed'),
                subtitle: const Text('Decide within 7 days (5S).'),
                value: _tag,
                onChanged: (v) => setState(() => _tag = v),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
