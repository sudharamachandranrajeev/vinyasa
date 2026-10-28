import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/analysis.dart';
import '../domain/catalog.dart';
import '../domain/fit.dart';
import '../domain/space.dart';
import 'look.dart';
import 'motion.dart';
import 'plan_editor.dart';
import 'plan_view.dart';

/// Fit before you buy: the size of a piece the user is thinking of, the
/// best places for it in the room, and whether it gets through the door.
class FitPage extends ConsumerStatefulWidget {
  const FitPage({super.key, required this.roomId, required this.space});
  final String roomId;
  final String space;

  @override
  ConsumerState<FitPage> createState() => _FitPageState();
}

class _FitPageState extends ConsumerState<FitPage> {
  ItemKind? _kind;
  final _w = TextEditingController(), _d = TextEditingController(), _h = TextEditingController();
  FitResult? _result;
  bool _busy = false;

  @override
  void dispose() {
    _w.dispose();
    _d.dispose();
    _h.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final k = await pickKind(context);
    if (k == null || !mounted) return;
    setState(() {
      _kind = k;
      _w.text = '${k.w}';
      _d.text = '${k.d}';
      _h.text = '${k.h}';
      _result = null;
    });
  }

  int? _mm(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return v == null || v < 50 || v > 20000 ? null : v;
  }

  Future<void> _find(Room room) async {
    final k = _kind, w = _mm(_w), d = _mm(_d), h = _mm(_h);
    if (k == null) return;
    if (w == null || d == null || h == null) {
      showMessage(context, 'Give each size in millimetres, between 50 and 20000.');
      return;
    }
    setState(() => _busy = true);
    final item = Item(id: newId(), kind: k.id, x: 0, y: 0, w: w, d: d, h: h);
    try {
      final r = await findFitInBackground(room, item);
      if (mounted) setState(() => _result = r);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _put(Room now, FitSpot s) async {
    final room = now.copyWith(items: [...now.items, s.item]);
    await ref.mutate((m) => m.book.saveRoom(room, space: widget.space, score: analyse(room).overall));
    if (!mounted) return;
    showMessage(context, '${s.item.name} is on the plan.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final room = ref.watch(roomProvider(widget.roomId)).value;
    final r = _result;
    final digits = [FilteringTextInputFormatter.digitsOnly];
    Widget size(TextEditingController c, String label) => SizedBox(
      width: 110,
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: digits,
        decoration: InputDecoration(labelText: label, suffixText: 'mm'),
        onChanged: (_) => setState(() => _result = null),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Will it fit?')),
      body: room == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 96 + MediaQuery.paddingOf(context).bottom),
              children: [
                Readable(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Before you buy, give the piece’s size from the shop. Vinyasa tries it everywhere in '
                        '${room.name}, checks each place with the same rules as the analysis, and checks the door.',
                        style: t.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pick,
                            icon: const Icon(Icons.chair_outlined),
                            label: Text(_kind?.label ?? 'What is it?'),
                          ),
                          if (_kind != null) ...[
                            size(_w, 'Width'),
                            size(_d, 'Depth'),
                            size(_h, 'Height'),
                            _busy
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: SizedBox.square(dimension: 24, child: CircularProgressIndicator()),
                                  )
                                : FilledButton.icon(
                                    onPressed: () => _find(room),
                                    icon: const Icon(Icons.search),
                                    label: const Text('Find places'),
                                  ),
                          ],
                        ],
                      ),
                      if (r != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          color: r.door.fits ? null : t.colorScheme.errorContainer,
                          child: ListTile(
                            leading: Icon(r.door.fits ? Icons.door_front_door_outlined : Icons.block),
                            title: Text(
                              r.door.fits ? 'Gets through the door' : 'Will not get through the door',
                            ),
                            subtitle: Text(r.door.text),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (r.spots.isEmpty)
                          const EmptyState(
                            icon: Icons.crop_free,
                            title: 'Nowhere free for it',
                            message: 'Every place it would stand overlaps something or a door’s swing.',
                          )
                        else
                          ...staggered([
                            for (final (i, s) in r.spots.indexed)
                              _SpotCard(rank: i, before: r.before, spot: s, onPut: () => _put(room, s)),
                          ]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  const _SpotCard({required this.rank, required this.before, required this.spot, required this.onPut});
  final int rank;
  final Report before;
  final FitSpot spot;
  final VoidCallback onPut;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final own = spot.own.where((f) => f.severity != Severity.nice).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(rank == 0 ? 'Best place' : 'Another place', style: t.textTheme.titleMedium),
                ),
                ScoreRing(score: before.overall, label: 'Now', size: 40),
                const SizedBox(width: 8),
                ScoreRing(score: spot.report.overall, label: 'With it', size: 48),
              ],
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: spot.room.width / spot.room.depth,
              child: PlanView(room: spot.room, highlight: {spot.item.id}, selected: spot.item.id),
            ),
            const SizedBox(height: 8),
            if (own.isEmpty)
              const Text('No problems with it here.')
            else
              for (final f in own.take(3))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline, size: 18),
                  title: Text(f.title),
                  subtitle: f.fix.isEmpty ? null : Text(f.fix),
                ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: onPut,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Put it here on the plan'),
            ),
          ],
        ),
      ),
    );
  }
}
