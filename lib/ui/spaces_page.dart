import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../db/database.dart';
import '../domain/analysis.dart';
import '../domain/samples.dart';
import '../domain/space.dart';
import 'look.dart';
import 'motion.dart';
import 'plan_view.dart';
import 'room_form.dart';
import 'room_page.dart';

/// Every space and its rooms, each room with its plan and score.
class SpacesPage extends ConsumerWidget {
  const SpacesPage({super.key});

  Future<void> _addSpace(BuildContext context, WidgetRef ref) async {
    final got = await editSpace(context);
    if (got == null) return;
    await ref.mutate((s) => s.book.saveSpace(name: got.name, kind: got.kind));
  }

  /// A home with a bedroom, a living room and a kitchen, each with the
  /// mistakes the rules look for.
  Future<void> _example(WidgetRef ref) async {
    await ref.mutate((s) async {
      final space = await s.book.saveSpace(name: 'Example home', kind: SpaceKind.home);
      for (final make in [sampleBedroom, sampleLiving, sampleKitchen]) {
        final room = make(newId());
        await s.book.saveRoom(room, space: space, score: analyse(room).overall);
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spacesProvider);
    final rooms = ref.watch(allRoomsProvider).value ?? const [];
    return AsyncView(
      spaces,
      builder: (spaces) => PageScaffold(
        title: 'Spaces',
        banner: 'page.spaces',
        fab: FloatingActionButton.extended(
          onPressed: () => _addSpace(context, ref),
          icon: const Icon(Icons.add_home_outlined),
          label: const Text('Add a space'),
        ),
        children: [
          if (spaces.isEmpty)
            EmptyState(
              icon: Icons.chair_outlined,
              title: 'Start with a space',
              message:
                  'A home, an office, a shop: add one, then its rooms. Or open an example to look around.',
              actions: [
                FilledButton.icon(
                  onPressed: () => _addSpace(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a space'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _example(ref),
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Try an example'),
                ),
              ],
            ),
          for (final s in spaces)
            _SpaceCard(s, [
              for (final r in rooms)
                if (r.space == s.id) r,
            ]),
        ],
      ),
    );
  }
}

IconData spaceIcon(SpaceKind k) => switch (k) {
  SpaceKind.home => Icons.home_outlined,
  SpaceKind.office => Icons.business_outlined,
  SpaceKind.shop => Icons.storefront_outlined,
  SpaceKind.clinic => Icons.local_hospital_outlined,
  SpaceKind.studio => Icons.brush_outlined,
  SpaceKind.storeroom => Icons.inventory_2_outlined,
  SpaceKind.other => Icons.place_outlined,
};

class _SpaceCard extends ConsumerWidget {
  const _SpaceCard(this.space, this.rooms);
  final SpaceRow space;
  final List<RoomRow> rooms;

  Future<void> _addRoom(BuildContext context, WidgetRef ref) async {
    final kind = SpaceKind.of(space.kind);
    final blank = Room(
      id: newId(),
      name: '',
      type: kind == SpaceKind.home ? RoomType.living : RoomType.office,
      width: 4000,
      depth: 3500,
      openings: [Opening(id: newId(), kind: OpeningKind.door, wall: Wall.bottom, offset: 300, width: 900)],
    );
    final room = await editRoom(context, blank, isNew: true);
    if (room == null || !context.mounted) return;
    await storeRoom(ref, room, space.id);
    if (context.mounted) _open(context, room.id);
  }

  void _open(BuildContext context, String id) =>
      Navigator.of(context).push(fluidRoute(RoomPage(roomId: id, space: space.id)));

  Future<void> _menu(BuildContext context, WidgetRef ref, String what) async {
    switch (what) {
      case 'edit':
        final got = await editSpace(context, name: space.name, kind: SpaceKind.of(space.kind));
        if (got != null) {
          await ref.mutate(
            (s) => s.book.saveSpace(id: space.id, name: got.name, kind: got.kind, notes: space.notes),
          );
        }
      case 'remove':
        final yes = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Remove ${space.name}?'),
            content: Text(
              rooms.isEmpty
                  ? 'It has no rooms.'
                  : 'Its ${rooms.length} ${rooms.length == 1 ? 'room goes' : 'rooms go'} too, with their plans '
                        'and photos. This cannot be undone.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
            ],
          ),
        );
        if (yes == true) await ref.mutate((s) => s.book.removeSpace(space.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final scored = rooms.where((r) => r.score >= 0).toList();
    final avg = scored.isEmpty ? -1 : (scored.fold(0, (s, r) => s + r.score) / scored.length).round();
    return SectionCard(
      title: space.name,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avg >= 0) ScoreRing(score: avg, size: 32),
          PopupMenuButton<String>(
            onSelected: (v) => _menu(context, ref, v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Rename')),
              PopupMenuItem(value: 'remove', child: Text('Remove space')),
            ],
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final cols = (c.maxWidth / 240).floor().clamp(1, 5);
          final w = (c.maxWidth - 12 * (cols - 1)) / cols;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: staggered([
              for (final r in rooms)
                SizedBox(
                  width: w,
                  child: _RoomCard(r, onTap: () => _open(context, r.id)),
                ),
              SizedBox(
                width: w,
                height: 196,
                child: Pressable(
                  onTap: () => _addRoom(context, ref),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(VinColors.of(context).radius),
                      border: Border.all(color: VinColors.of(context).line, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(spaceIcon(SpaceKind.of(space.kind)), color: t.colorScheme.primary),
                        const SizedBox(height: 6),
                        const Text('Add a room'),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard(this.row, {required this.onTap});
  final RoomRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final room = Room.decode(row.json);
    return Pressable(
      onTap: onTap,
      child: Card(
        color: t.colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(tag: 'room-${row.id}', child: PlanThumb(room, height: 130)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.name,
                          style: t.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${room.type.label} · ${(room.area / 1e6).toStringAsFixed(1)} m²',
                          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  ScoreRing(score: row.score, size: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
