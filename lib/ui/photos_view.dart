import 'dart:io';

import 'package:brahma_core/brahma_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../app/providers.dart';
import '../db/database.dart';
import 'common.dart';
import 'motion.dart';

/// A room's photos and videos, copied into the app's own folder so they
/// stay when the originals move. They never leave this device.
class PhotosView extends ConsumerWidget {
  const PhotosView({super.key, required this.roomId});
  final String roomId;

  static const _videoExt = {'mp4', 'mov', 'm4v', 'webm', 'mkv', '3gp', 'avi'};

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final picked =
        await FilePicker.pickFiles(
          dialogTitle: 'Photos or videos of the room',
          type: FileType.media,
        ).catchError((Object e) {
          if (context.mounted) showError(context, e);
          return <PlatformFile>[];
        });
    if (picked.isEmpty) return;
    final dir = Directory('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}media');
    await dir.create(recursive: true);
    for (final f in picked) {
      final from = f.path;
      if (from == null) continue;
      final ext = (f.extension ?? '').toLowerCase();
      final to = '${dir.path}${Platform.pathSeparator}${newId()}${ext.isEmpty ? '' : '.$ext'}';
      await File(from).copy(to);
      await ref.mutate((s) => s.book.addMedia(roomId, to, _videoExt.contains(ext) ? 'video' : 'photo'));
    }
  }

  Future<void> _remove(WidgetRef ref, MediaRow m) async {
    await ref.mutate((s) => s.book.removeMedia(m.id));
    await File(m.path).delete().catchError((_) => File(m.path));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    return AsyncView(
      ref.watch(mediaProvider(roomId)),
      builder: (media) => ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 96 + MediaQuery.paddingOf(context).bottom),
        children: [
          Readable(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _add(context, ref),
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Add photos or videos'),
                    ),
                    const SizedBox(width: 8),
                    Hint(
                      'photos.what',
                      child: Icon(Icons.info_outline, size: 18, color: t.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Take one photo from each corner, standing, and a slow video turning round from the door. '
                  'They help you fill in the plan and compare before and after.',
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                if (media.isEmpty)
                  const EmptyState(icon: Icons.photo_library_outlined, title: 'No photos of this room yet')
                else
                  LayoutBuilder(
                    builder: (context, c) {
                      final cols = (c.maxWidth / 180).floor().clamp(2, 6);
                      return GridView.count(
                        crossAxisCount: cols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: staggered([
                          for (final m in media)
                            Pressable(
                              onTap: () => _open(context, m),
                              onLongPress: () => _remove(ref, m),
                              child: Hero(tag: 'media-${m.id}', child: _Thumb(m)),
                            ),
                        ]),
                      );
                    },
                  ),
                if (media.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Press and hold one to remove it.',
                      style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, MediaRow m) {
    if (m.kind == 'video') {
      openLink(context, Uri.file(m.path).toString());
      return;
    }
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, _, _) => GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Hero(
              tag: 'media-${m.id}',
              child: InteractiveViewer(child: Image.file(File(m.path), fit: BoxFit.contain)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb(this.m);
  final MediaRow m;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: m.kind == 'video'
          ? ColoredBox(
              color: scheme.surfaceContainerHigh,
              child: Icon(Icons.play_circle_outline, size: 40, color: scheme.primary),
            )
          : Image.file(
              File(m.path),
              fit: BoxFit.cover,
              cacheWidth: 400,
              errorBuilder: (_, _, _) => ColoredBox(
                color: scheme.surfaceContainerHigh,
                child: Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
              ),
            ),
    );
  }
}
