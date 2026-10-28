import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';

import '../domain/catalog.dart';
import '../domain/rules.dart' show mm;
import '../domain/space.dart';
import 'look.dart';
import 'plan_view.dart';
import 'room_form.dart' show metresText, parseMetres;

/// The plan, editable: drag pieces, tap to select, turn, resize or remove
/// the selected one, add furniture, doors and windows. Every finished
/// change goes to [onChanged]; a drag only when the finger lifts.
class PlanEditor extends StatefulWidget {
  const PlanEditor({super.key, required this.room, required this.onChanged});
  final Room room;
  final ValueChanged<Room> onChanged;

  @override
  State<PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<PlanEditor> {
  /// The room while a drag is under way; else the widget's.
  Room? _dragging;
  String? _selected;
  Offset _grab = Offset.zero;
  final _layers = <PlanLayer>{PlanLayer.clearance};

  Room get _room => _dragging ?? widget.room;
  Item? get _item => _selected == null ? null : _room.item(_selected!);

  void _change(Room r) {
    setState(() => _dragging = null);
    widget.onChanged(r);
  }

  static int _snap(double v) => (v / 50).round() * 50;

  /// [v] kept so a piece [size] long stays inside a wall [room] long.
  static int _fit(int v, int room, int size) => math.min(math.max(0, v), math.max(0, room - size));

  void _start(Offset px, PlanFit fit) {
    final at = fit.toMm(px);
    final hit = itemAt(_room, at);
    setState(() => _selected = hit?.id);
    if (hit == null || hit.fixed) return;
    _grab = at - Offset(hit.x.toDouble(), hit.y.toDouble());
    _dragging = _room;
  }

  void _move(Offset px, PlanFit fit) {
    final item = _item;
    if (_dragging == null || item == null) return;
    final at = fit.toMm(px) - _grab;
    final x = _fit(_snap(at.dx), _room.width, item.footW);
    final y = _fit(_snap(at.dy), _room.depth, item.footD);
    if (x == item.x && y == item.y) return;
    setState(() => _dragging = _room.withItem(item.copyWith(x: x, y: y)));
  }

  void _end() {
    final r = _dragging;
    if (r == null) return;
    final now = r.item(_selected ?? ''), was = widget.room.item(_selected ?? '');
    if (now != null && was != null && was.x == now.x && was.y == now.y) {
      return setState(() => _dragging = null);
    }
    _change(r);
  }

  void _turn(int by) {
    final i = _item;
    if (i == null) return;
    final rot = (i.rot + by) % 4;
    // Turn about the centre, then keep it inside the room.
    final turned = i.copyWith(rot: rot);
    final cx = i.x + i.footW / 2, cy = i.y + i.footD / 2;
    final x = _fit(_snap(cx - turned.footW / 2), _room.width, turned.footW);
    final y = _fit(_snap(cy - turned.footD / 2), _room.depth, turned.footD);
    _change(_room.withItem(turned.copyWith(x: x, y: y)));
  }

  Future<void> _add() async {
    final kind = await pickKind(context);
    if (kind == null || !mounted) return;
    // Into the middle of the room, to be dragged where it goes.
    final x = _fit(_snap((_room.width - kind.w) / 2), _room.width, kind.w);
    final y = _fit(_snap((_room.depth - kind.d) / 2), _room.depth, kind.d);
    final item = Item(
      id: newId(),
      kind: kind.id,
      x: x,
      y: y,
      w: kind.w,
      d: kind.d,
      h: kind.h,
      fixed: kind.builtIn,
    );
    setState(() => _selected = item.id);
    _change(_room.copyWith(items: [..._room.items, item]));
  }

  Future<void> _edit() async {
    final i = _item;
    if (i == null) return;
    final edited = await editItem(context, i, _room);
    if (edited == null || !mounted) return;
    if (edited.isEmpty) {
      setState(() => _selected = null);
      _change(
        _room.copyWith(
          items: [
            for (final x in _room.items)
              if (x.id != i.id) x,
          ],
        ),
      );
    } else {
      _change(_room.withItem(edited.first));
    }
  }

  Future<void> _opening([Opening? o]) async {
    final edited = await editOpening(context, _room, o);
    if (edited == null || !mounted) return;
    final rest = [
      for (final x in _room.openings)
        if (x.id != o?.id) x,
    ];
    _change(_room.copyWith(openings: edited.isEmpty ? rest : [...rest, edited.first]));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final item = _item;
    final plan = LayoutBuilder(
      builder: (context, c) {
        final fit = PlanFit(c.biggest, _room);
        return GestureDetector(
          onTapUp: (d) => setState(() => _selected = itemAt(_room, fit.toMm(d.localPosition))?.id),
          onDoubleTapDown: (d) => setState(() => _selected = itemAt(_room, fit.toMm(d.localPosition))?.id),
          onDoubleTap: () => _turn(1),
          onPanStart: (d) => _start(d.localPosition, fit),
          onPanUpdate: (d) => _move(d.localPosition, fit),
          onPanEnd: (_) => _end(),
          onPanCancel: _end,
          child: Semantics(
            label: 'Plan of ${_room.name}: ${_room.items.length} pieces. Select a piece in the list below.',
            child: PlanView(room: _room, layers: _layers, selected: _selected),
          ),
        );
      },
    );
    final tools = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Furniture')),
        OutlinedButton.icon(
          onPressed: () => _opening(),
          icon: const Icon(Icons.sensor_door_outlined),
          label: const Text('Door or window'),
        ),
        for (final l in PlanLayer.values)
          FilterChip(
            avatar: Icon(l.icon, size: 18),
            label: Text(l.label),
            selected: _layers.contains(l),
            onSelected: (on) => setState(() => on ? _layers.add(l) : _layers.remove(l)),
          ),
        Hint('plan.drag', child: Icon(Icons.help_outline, size: 20, color: t.colorScheme.onSurfaceVariant)),
      ],
    );
    final selection = AnimatedSwitcher(
      duration: Motion.reduced(context) ? Duration.zero : Motion.short,
      transitionBuilder: (child, a) => SizeTransition(
        sizeFactor: a,
        child: FadeTransition(opacity: a, child: child),
      ),
      child: item == null
          ? const SizedBox(key: ValueKey('none'), width: double.infinity)
          : Card(
              key: ValueKey(item.id),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Icon(kindIcon(item.spec), color: VinColors.of(context).furniture),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: t.textTheme.titleSmall),
                          Text(
                            '${mm(item.w)} × ${mm(item.d)} · faces ${_room.facing(item).label.toLowerCase()}'
                            '${item.fixed ? ' · fixed' : ''}',
                            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Turn left',
                      onPressed: item.fixed ? null : () => _turn(3),
                      icon: const Icon(Icons.rotate_left),
                    ),
                    IconButton(
                      tooltip: 'Turn right',
                      onPressed: item.fixed ? null : () => _turn(1),
                      icon: const Icon(Icons.rotate_right),
                    ),
                    IconButton(tooltip: 'Edit', onPressed: _edit, icon: const Icon(Icons.tune)),
                  ],
                ),
              ),
            ),
    );
    final openings = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final o in _room.openings)
          ListTile(
            dense: true,
            leading: Icon(o.kind == OpeningKind.window ? Icons.window_outlined : Icons.sensor_door_outlined),
            title: Text(o.kind.label),
            subtitle: Text(
              '${mm(o.width)} wide, ${_room.wallDir(o.wall).label.toLowerCase()} wall, ${mm(o.offset)} from its end',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _opening(o),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(padding: const EdgeInsets.all(16), child: plan),
              ),
              SizedBox(
                width: 340,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 16, 16, 96),
                  children: [
                    tools,
                    const SizedBox(height: 12),
                    selection,
                    const SizedBox(height: 8),
                    openings,
                  ],
                ),
              ),
            ],
          );
        }
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 96 + MediaQuery.paddingOf(context).bottom),
          children: [
            SizedBox(height: math.max(280, MediaQuery.sizeOf(context).height * 0.5), child: plan),
            const SizedBox(height: 8),
            selection,
            const SizedBox(height: 8),
            tools,
            const SizedBox(height: 8),
            openings,
          ],
        );
      },
    );
  }
}

/// Picks a kind of furniture from the catalog, with a search box.
Future<ItemKind?> pickKind(BuildContext context) => showModalBottomSheet<ItemKind>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => const _CatalogSheet(),
);

class _CatalogSheet extends StatefulWidget {
  const _CatalogSheet();

  @override
  State<_CatalogSheet> createState() => _CatalogSheetState();
}

class _CatalogSheetState extends State<_CatalogSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final shown = [
      for (final k in catalog)
        if (q.isEmpty || k.label.toLowerCase().contains(q) || k.tags.any((t) => t.contains(q))) k,
    ];
    final t = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: false,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Bed, desk, shelf…',
              ),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                for (final g in KindGroup.values)
                  if (shown.where((k) => k.group == g).toList() case final ks when ks.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        g.label,
                        style: t.textTheme.labelLarge?.copyWith(color: t.colorScheme.primary),
                      ),
                    ),
                    for (final k in ks)
                      ListTile(
                        leading: Icon(kindIcon(k)),
                        title: Text(k.label),
                        subtitle: Text('${mm(k.w)} × ${mm(k.d)}'),
                        onTap: () => Navigator.pop(context, k),
                      ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Edits a piece's name, size and whether it is fixed. Returns the piece in
/// a one-item list, an empty list to remove it, or null when cancelled.
Future<List<Item>?> editItem(BuildContext context, Item item, Room room) =>
    showDialog(context: context, builder: (_) => _ItemDialog(item, room));

class _ItemDialog extends StatefulWidget {
  const _ItemDialog(this.item, this.room);
  final Item item;
  final Room room;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late final _label = TextEditingController(text: widget.item.label);
  late final _w = TextEditingController(text: metresText(widget.item.w));
  late final _d = TextEditingController(text: metresText(widget.item.d));
  late final _h = TextEditingController(text: metresText(widget.item.h));
  late var _fixed = widget.item.fixed;
  String? _error;

  @override
  void dispose() {
    for (final c in [_label, _w, _d, _h]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final w = parseMetres(_w.text), d = parseMetres(_d.text), h = parseMetres(_h.text) ?? 0;
    if (w == null || d == null || w < 50 || d < 20) {
      return setState(() => _error = 'Width and depth in metres, like 0.6');
    }
    final i = widget.item;
    var out = i.copyWith(label: _label.text.trim(), w: w, d: d, h: h, fixed: _fixed);
    out = out.copyWith(
      x: out.x.clamp(0, math.max(0, widget.room.width - out.footW)),
      y: out.y.clamp(0, math.max(0, widget.room.depth - out.footD)),
    );
    Navigator.pop(context, [out]);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item.name),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _label,
            decoration: InputDecoration(labelText: 'Name', hintText: widget.item.spec.label),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (c, l) in [(_w, 'Width'), (_d, 'Depth'), (_h, 'Height')]) ...[
                Expanded(
                  child: TextField(
                    controller: c,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: '$l (m)'),
                  ),
                ),
                if (l != 'Height') const SizedBox(width: 8),
              ],
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fixed in place'),
            subtitle: const Text('Built in or plumbed: rearranging leaves it where it is.'),
            value: _fixed,
            onChanged: (v) => setState(() => _fixed = v),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, const <Item>[]),
        style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
        child: const Text('Remove'),
      ),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

/// Adds or edits a door or window. Returns it in a one-item list, an empty
/// list to remove it, or null when cancelled.
Future<List<Opening>?> editOpening(BuildContext context, Room room, Opening? opening) =>
    showDialog(context: context, builder: (_) => _OpeningDialog(room, opening));

class _OpeningDialog extends StatefulWidget {
  const _OpeningDialog(this.room, this.opening);
  final Room room;
  final Opening? opening;

  @override
  State<_OpeningDialog> createState() => _OpeningDialogState();
}

class _OpeningDialogState extends State<_OpeningDialog> {
  late var _o =
      widget.opening ??
      Opening(id: newId(), kind: OpeningKind.door, wall: Wall.bottom, offset: 300, width: 900);
  late final _width = TextEditingController(text: metresText(_o.width));
  late final _offset = TextEditingController(text: metresText(_o.offset));
  String? _error;

  @override
  void dispose() {
    _width.dispose();
    _offset.dispose();
    super.dispose();
  }

  int get _wallLen => _o.wall.horizontal ? widget.room.width : widget.room.depth;

  void _save() {
    final w = parseMetres(_width.text),
        off = parseMetres(_offset.text) ?? (_offset.text.trim() == '0' ? 0 : null);
    if (w == null || off == null || w < 300) return setState(() => _error = 'Width and distance in metres');
    if (off + w > _wallLen) {
      return setState(() => _error = 'That runs past the end of the wall (${mm(_wallLen)}).');
    }
    Navigator.pop(context, [_o.copyWith(width: w, offset: off)]);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.room;
    final start = switch (_o.wall) {
      Wall.top || Wall.bottom => r.wallDir(Wall.left),
      Wall.left || Wall.right => r.wallDir(Wall.top),
    };
    return AlertDialog(
      title: Text(widget.opening == null ? 'Add a door or window' : _o.kind.label),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in OpeningKind.values)
                    ChoiceChip(
                      label: Text(k.label),
                      selected: _o.kind == k,
                      onSelected: (_) => setState(() => _o = _o.copyWith(kind: k)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('On the wall', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              SegmentedButton<Wall>(
                segments: [
                  for (final w in Wall.values)
                    ButtonSegment(
                      value: w,
                      label: Text(r.wallDir(w).short),
                      tooltip: '${w.name} of the plan',
                    ),
                ],
                selected: {_o.wall},
                onSelectionChanged: (s) => setState(() => _o = _o.copyWith(wall: s.first)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _width,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Width (m)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _offset,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: 'From the ${start.label.toLowerCase()} end (m)'),
                    ),
                  ),
                ],
              ),
              if (_o.kind == OpeningKind.door || _o.kind == OpeningKind.balconyDoor) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Opens into this room'),
                  value: _o.swingIn,
                  onChanged: (v) => setState(() => _o = _o.copyWith(swingIn: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Hinge at the ${start.label.toLowerCase()} end'),
                  value: _o.hingeAtStart,
                  onChanged: (v) => setState(() => _o = _o.copyWith(hingeAtStart: v)),
                ),
              ],
              if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.opening != null)
          TextButton(
            onPressed: () => Navigator.pop(context, const <Opening>[]),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Remove'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
