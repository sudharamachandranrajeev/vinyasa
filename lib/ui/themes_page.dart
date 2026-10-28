import 'dart:convert';
import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/samples.dart';
import '../domain/themes.dart';
import 'common.dart';
import 'look.dart';
import 'plan_view.dart';

/// The theme manager: pick a theme and light or dark, make and edit your
/// own, and share them as JSON files.
class ThemesPage extends ConsumerWidget {
  const ThemesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themes = ref.watch(allThemesProvider);
    final look = ref.watch(appearanceProvider).value;
    return PageScaffold(
      title: 'Themes',
      banner: 'page.themes',
      actions: [
        IconButton(
          tooltip: 'Import a theme',
          icon: const Icon(Icons.file_open_outlined),
          onPressed: () => _import(context, ref),
        ),
      ],
      fab: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New theme'),
      ),
      children: [
        SectionCard(
          title: 'Light or dark',
          child: Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {look?.mode ?? ThemeMode.system},
              onSelectionChanged: (s) => chooseMode(ref, s.first),
            ),
          ),
        ),
        AsyncView(
          themes,
          onRetry: () => ref.invalidate(customThemesProvider),
          builder: (list) {
            final builtIn = list.where((t) => t.builtIn).toList();
            final mine = list.where((t) => !t.builtIn).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Section('Built in', builtIn, look?.theme.id),
                if (mine.isNotEmpty) _Section('Yours', mine, look?.theme.id),
              ],
            );
          },
        ),
        const SizedBox(height: 72),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final taken = {for (final t in await ref.read(allThemesProvider.future)) t.id};
    final names = ['Signal', 'Beacon', 'Tide', 'Ember', 'Grove', 'Dusk', 'Comet', 'Lagoon'];
    final random = math.Random();
    final name = names[random.nextInt(names.length)];
    if (!context.mounted) return;
    await editTheme(
      context,
      ref,
      generateTheme(random, id: themeIdFor(name, taken), name: name),
      isNew: true,
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final text = await showDialog<String>(context: context, builder: (_) => const _ImportDialog());
    if (text == null || !context.mounted) return;
    final VinTheme theme;
    try {
      theme = VinTheme.decode(text);
    } on FormatException catch (e) {
      return showMessage(context, e.message);
    }
    final taken = {for (final t in await ref.read(allThemesProvider.future)) t.id};
    // A theme with a taken id comes in beside the one there, never over it.
    final id = taken.contains(theme.id) ? themeIdFor(theme.name, taken) : theme.id;
    final saved = theme.copyWith(id: id, builtIn: false);
    if (!context.mounted) return;
    if (await guarded(context, () => ref.mutate((s) => s.book.saveTheme(id, saved.name, saved.encode()))) &&
        context.mounted) {
      showMessage(context, 'Imported ${saved.name}.');
    }
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.themes, this.current);
  final String title;
  final List<VinTheme> themes;
  final String? current;

  @override
  Widget build(BuildContext context) => SectionCard(
    title: title,
    child: LayoutBuilder(
      builder: (context, c) {
        final columns = math.max(1, (c.maxWidth / 220).floor());
        final width = (c.maxWidth - 12 * (columns - 1)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final t in themes)
              SizedBox(
                width: width,
                child: _ThemeTile(t, selected: t.id == current),
              ),
          ],
        );
      },
    ),
  );
}

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile(this.theme, {required this.selected});
  final VinTheme theme;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(math.min(theme.radius, 18));
    return Semantics(
      selected: selected,
      button: true,
      label: '${theme.name} theme',
      child: InkWell(
        borderRadius: radius,
        onTap: () => chooseTheme(ref, theme.id),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? scheme.primary : VinColors.of(context).line,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 86, child: _Swatch(theme, dark: dark)),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
                child: Row(
                  children: [
                    if (selected) ...[
                      Icon(Icons.check_circle, size: 18, color: scheme.primary),
                      const SizedBox(width: 6),
                    ],
                    Expanded(child: Text(theme.name, overflow: TextOverflow.ellipsis)),
                    PopupMenuButton<String>(
                      tooltip: 'More',
                      itemBuilder: (_) => [
                        if (!theme.builtIn) const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'copy', child: Text('Make a copy')),
                        const PopupMenuItem(value: 'clip', child: Text('Copy as JSON')),
                        const PopupMenuItem(value: 'save', child: Text('Save to a file')),
                        if (!theme.builtIn) const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (v) => _act(context, ref, v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _act(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'edit':
        await editTheme(context, ref, theme);
      case 'copy':
        final taken = {for (final t in await ref.read(allThemesProvider.future)) t.id};
        final name = '${theme.name} copy'.substring(0, math.min(40, '${theme.name} copy'.length));
        if (context.mounted) {
          await editTheme(
            context,
            ref,
            theme.copyWith(id: themeIdFor(name, taken), name: name, builtIn: false),
            isNew: true,
          );
        }
      case 'clip':
        await copyText(context, theme.encode(), what: 'Copied ${theme.name} as JSON.');
      case 'save':
        await saveBytes(
          context,
          'vinyasa-theme-${theme.id}.json',
          Uint8List.fromList(utf8.encode(theme.encode())),
          mime: 'application/json',
        );
      case 'delete':
        final ok = await confirm(
          context,
          title: 'Delete ${theme.name}?',
          message: 'It is removed from every synced device.',
          action: 'Delete',
          destructive: true,
        );
        if (ok && context.mounted) {
          await guarded(context, () => ref.mutate((s) => s.book.removeTheme(theme.id)));
        }
    }
  }
}

/// A theme drawn small: its background, a card holding a tiny room in the
/// furniture and zone colours, and the seed and accent.
class _Swatch extends StatelessWidget {
  const _Swatch(this.t, {required this.dark});
  final VinTheme t;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? t.darkBackground : t.lightBackground;
    final card = Color.alphaBlend(t.seed.withValues(alpha: dark ? 0.12 : 0.08), bg);
    return ColoredBox(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DecoratedBox(
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(t.radius / 2)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: CustomPaint(painter: _MiniRoom(t), size: Size.infinite),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(radius: 9, backgroundColor: t.seed),
                    CircleAvatar(radius: 9, backgroundColor: t.accent),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _file() async {
    try {
      final f = await FilePicker.pickFile(
        dialogTitle: 'A theme file',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (bytes.length > 64 * 1024) {
        if (mounted) showMessage(context, 'That file is too big to be a theme.');
        return;
      }
      _text.text = utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Import a theme'),
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _text,
            minLines: 6,
            maxLines: 12,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(hintText: 'Paste a theme’s JSON here'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: _file,
                icon: const Icon(Icons.folder_open),
                label: const Text('From a file'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final d = await Clipboard.getData(Clipboard.kTextPlain);
                  if (d?.text != null) _text.text = d!.text!;
                },
                icon: const Icon(Icons.content_paste),
                label: const Text('Paste'),
              ),
            ],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(context, _text.text), child: const Text('Import')),
    ],
  );
}

/// Opens the editor on [theme]; saves it as one of the user's themes.
Future<void> editTheme(BuildContext context, WidgetRef ref, VinTheme theme, {bool isNew = false}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _ThemeEditor(theme, isNew: isNew)));

class _ThemeEditor extends ConsumerStatefulWidget {
  const _ThemeEditor(this.initial, {required this.isNew});
  final VinTheme initial;
  final bool isNew;

  @override
  ConsumerState<_ThemeEditor> createState() => _ThemeEditorState();
}

class _ThemeEditorState extends ConsumerState<_ThemeEditor> {
  late VinTheme _t = widget.initial;
  late final _name = TextEditingController(text: widget.initial.name);
  Brightness? _preview;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || name.length > 40) return showMessage(context, 'The name must be 1 to 40 characters.');
    final t = _t.copyWith(name: name, builtIn: false);
    final ok = await guarded(context, () async {
      await ref.mutate((s) => s.book.saveTheme(t.id, t.name, t.encode()));
      if (widget.isNew) await chooseTheme(ref, t.id);
    });
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = _preview ?? Theme.of(context).brightness;
    final bg = brightness == Brightness.dark ? _t.darkBackground : _t.lightBackground;
    final warnings = [
      if (contrast(_t.furniture, bg) < 2) 'Furniture is hard to see on the ${brightness.name} background.',
      if (contrast(_t.zone, bg) < 2) 'Zone is hard to see on the ${brightness.name} background.',
      if (contrast(_t.furniture, _t.zone) < 1.3) 'Furniture and zone look alike.',
    ];
    final wide = MediaQuery.sizeOf(context).width > 820;
    final controls = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
          maxLength: 40,
        ),
        _ColourField('Main colour', _t.seed, (c) => setState(() => _t = _t.copyWith(seed: c))),
        _ColourField('Accent', _t.accent, (c) => setState(() => _t = _t.copyWith(accent: c))),
        _ColourField('Furniture', _t.furniture, (c) => setState(() => _t = _t.copyWith(furniture: c))),
        _ColourField('Zone', _t.zone, (c) => setState(() => _t = _t.copyWith(zone: c))),
        _ColourField(
          'Light background',
          _t.lightBackground,
          (c) => setState(() => _t = _t.copyWith(lightBackground: c)),
        ),
        _ColourField(
          'Dark background',
          _t.darkBackground,
          (c) => setState(() => _t = _t.copyWith(darkBackground: c)),
        ),
        const SizedBox(height: 8),
        Text('Corners: ${_t.radius.round()}'),
        Slider(
          value: _t.radius,
          max: 32,
          divisions: 32,
          label: '${_t.radius.round()}',
          onChanged: (v) => setState(() => _t = _t.copyWith(radius: v.roundToDouble())),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'sans', label: Text('Sans')),
            ButtonSegment(value: 'mono', label: Text('Monospace')),
          ],
          selected: {_t.font},
          onSelectionChanged: (s) => setState(() => _t = _t.copyWith(font: s.first)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => setState(
            () => _t = generateTheme(math.Random(), id: _t.id, name: _name.text).copyWith(font: _t.font),
          ),
          icon: const Icon(Icons.casino_outlined),
          label: const Text('Surprise me'),
        ),
        for (final w in warnings)
          Padding(padding: const EdgeInsets.only(top: 12), child: StatusLabel(Status.warning, w)),
      ],
    );
    final preview = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<Brightness>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: Brightness.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: Brightness.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Dark'),
              ),
            ],
            selected: {brightness},
            onSelectionChanged: (s) => setState(() => _preview = s.first),
          ),
        ),
        Expanded(child: _Preview(_t, brightness)),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New theme' : 'Edit ${widget.initial.name}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                SizedBox(width: 380, child: controls),
                Expanded(child: preview),
              ],
            )
          : Column(
              children: [
                SizedBox(height: 330, child: preview),
                const Divider(),
                Expanded(child: controls),
              ],
            ),
    );
  }
}

/// The theme applied to a few of the app's own pieces.
class _Preview extends StatelessWidget {
  const _Preview(this.t, this.brightness);
  final VinTheme t;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final data = vinTheme(t, brightness);
    return Theme(
      data: data,
      child: Builder(
        builder: (context) => Backdrop(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Living room', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: PlanView(
                          room: _previewRoom,
                          layers: const {PlanLayer.clearance},
                          selected: 'sofa',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          ScoreRing(score: 86, label: 'Space'),
                          SizedBox(width: 12),
                          ScoreRing(score: 64, label: 'Access'),
                          SizedBox(width: 12),
                          ScoreRing(score: 41, label: 'Vaastu'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(onPressed: () {}, child: const Text('Button')),
                  OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                  FilterChip(label: const Text('Vaastu grid'), selected: true, onSelected: (_) {}),
                  Chip(label: const Text('Accent'), backgroundColor: t.accent.withValues(alpha: 0.25)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _previewRoom = sampleLiving('preview');

/// Four walls, a bed, a sofa and a walkway, for the swatches.
class _MiniRoom extends CustomPainter {
  const _MiniRoom(this.t);
  final VinTheme t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = Radius.circular(math.min(4, t.radius / 4));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.55, w * 0.84, h * 0.2), r),
      Paint()..color = t.zone.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.4, h * 0.42), r),
      Paint()..color = t.furniture,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.6, h * 0.08, w * 0.32, h * 0.2), r),
      Paint()..color = t.furniture.withValues(alpha: 0.7),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = t.seed,
    );
  }

  @override
  bool shouldRepaint(_MiniRoom old) => old.t != t;
}

/// A colour: a swatch, its hex code and hue/saturation/lightness sliders.
class _ColourField extends StatefulWidget {
  const _ColourField(this.label, this.value, this.onChanged);
  final String label;
  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  State<_ColourField> createState() => _ColourFieldState();
}

class _ColourFieldState extends State<_ColourField> {
  late final _hex = TextEditingController(text: hexOf(widget.value));
  bool _open = false;

  @override
  void didUpdateWidget(_ColourField old) {
    super.didUpdateWidget(old);
    final hex = hexOf(widget.value);
    if (parseHex(_hex.text) != widget.value) _hex.text = hex;
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(widget.value);
    Widget slider(String label, double value, double max, HSLColor Function(double v) apply) => Row(
      children: [
        SizedBox(width: 82, child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
        Expanded(
          child: Slider(
            value: value.clamp(0, max),
            max: max,
            onChanged: (v) => widget.onChanged(apply(v).toColor()),
          ),
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _open = !_open),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.value,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: VinColors.of(context).line),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.label)),
              SizedBox(
                width: 112,
                child: TextField(
                  controller: _hex,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(isDense: true),
                  onChanged: (v) {
                    final c = parseHex(v);
                    if (c != null) widget.onChanged(c);
                  },
                ),
              ),
              IconButton(
                tooltip: _open ? 'Hide sliders' : 'Adjust',
                icon: Icon(_open ? Icons.expand_less : Icons.tune),
                onPressed: () => setState(() => _open = !_open),
              ),
            ],
          ),
          if (_open) ...[
            slider('Hue', hsl.hue, 360, hsl.withHue),
            slider('Saturation', hsl.saturation, 1, hsl.withSaturation),
            slider('Lightness', hsl.lightness, 1, hsl.withLightness),
          ],
        ],
      ),
    );
  }
}
