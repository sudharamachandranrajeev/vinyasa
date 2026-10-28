import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/analysis.dart';
import '../domain/space.dart';
import 'analysis_view.dart';
import 'arrange_view.dart';
import 'ideas_page.dart';
import 'look.dart';
import 'photos_view.dart';
import 'plan_editor.dart';
import 'plan_view.dart';
import 'room_3d.dart';
import 'room_form.dart';
import 'storage_view.dart';

/// Saves [room] in [space] with its score, so lists show it without
/// running the rules again.
Future<void> storeRoom(WidgetRef ref, Room room, String space) =>
    ref.mutate((s) => s.book.saveRoom(room, space: space, score: analyse(room).overall));

/// One room: its plan, the room in 3D, the report on it, rearranging it, its photos and
/// ideas for it.
class RoomPage extends ConsumerStatefulWidget {
  const RoomPage({super.key, required this.roomId, required this.space});
  final String roomId;
  final String space;

  @override
  ConsumerState<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends ConsumerState<RoomPage> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 7, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _details(Room room) async {
    final edited = await editRoom(context, room);
    if (edited != null) await storeRoom(ref, edited, widget.space);
  }

  Future<void> _remove(Room room) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${room.name}?'),
        content: const Text('Its plan, kept arrangements and photos go too. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    Navigator.pop(context);
    await ref.mutate((s) => s.book.removeRoom(room.id));
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomProvider(widget.roomId));
    final report = ref.watch(reportProvider(widget.roomId)).value;
    final r = room.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(r?.name ?? ''),
        actions: [
          if (report != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(child: ScoreRing(score: report.overall, size: 36)),
            ),
          if (r != null) ...[
            IconButton(
              tooltip: 'Room details',
              onPressed: () => _details(r),
              icon: const Icon(Icons.edit_outlined),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'remove') _remove(r);
              },
              itemBuilder: (_) => const [PopupMenuItem(value: 'remove', child: Text('Remove room'))],
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view_outlined), text: 'Plan'),
            Tab(icon: Icon(Icons.view_in_ar_outlined), text: '3D'),
            Tab(icon: Icon(Icons.fact_check_outlined), text: 'Analysis'),
            Tab(icon: Icon(Icons.auto_awesome_outlined), text: 'Arrange'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Storage'),
            Tab(icon: Icon(Icons.photo_library_outlined), text: 'Photos'),
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Ideas'),
          ],
        ),
      ),
      body: AsyncView(
        room,
        builder: (r) => r == null
            ? const EmptyState(icon: Icons.meeting_room_outlined, title: 'This room is gone')
            : TabBarView(
                controller: _tabs,
                // Dragging on the plan must not swipe between tabs.
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Hero(
                    tag: 'room-${r.id}',
                    // The plan alone flies; the editor's buttons appear when it lands.
                    flightShuttleBuilder: (_, _, _, _, _) =>
                        IgnorePointer(child: PlanView(room: r, showLabels: false)),
                    child: Material(
                      type: MaterialType.transparency,
                      child: PlanEditor(room: r, onChanged: (x) => storeRoom(ref, x, widget.space)),
                    ),
                  ),
                  Room3D(room: r, interactive: true),
                  report == null
                      ? const SizedBox.shrink()
                      : AnalysisView(report: report, onArrange: () => _tabs.animateTo(3)),
                  ArrangeView(room: r, space: widget.space),
                  StorageView(room: r, onChanged: (x) => storeRoom(ref, x, widget.space)),
                  PhotosView(room: r, space: widget.space),
                  RoomIdeas(
                    room: r,
                    onLook: (id) => storeRoom(ref, r.copyWith(style: id), widget.space),
                  ),
                ],
              ),
      ),
    );
  }
}
