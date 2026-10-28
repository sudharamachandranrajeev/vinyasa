import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/book.dart';
import '../domain/photos.dart';
import 'common.dart';
import 'motion.dart';

/// Ideas photos for [query] from Openverse or Unsplash, in a grid that
/// grows a page at a time. With a [room], photos can be pinned to its
/// moodboard; without one, the user picks the room.
class IdeaPhotos extends ConsumerStatefulWidget {
  const IdeaPhotos({super.key, required this.query, this.room});
  final String query;
  final String? room;

  @override
  ConsumerState<IdeaPhotos> createState() => _IdeaPhotosState();
}

class _IdeaPhotosState extends ConsumerState<IdeaPhotos> {
  final _photos = <IdeaPhoto>[];
  int _page = 0;
  bool _more = false, _busy = false;
  Object? _error;

  /// What the grid shows, so a change of words or source starts again.
  (PhotoSource, String, PhotoFinder)? _for;

  Future<void> _load(PhotoFinder finder, PhotoSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = await finder.search(source, widget.query, page: _page + 1);
      if (!mounted) return;
      setState(() {
        _page++;
        _photos.addAll(page.photos);
        _more = page.more && page.photos.isNotEmpty;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose(PhotoSource s, PhotoFinder finder) async {
    if (!finder.ready(s)) {
      await showPhotoSources(context, ref);
      final now = await ref.read(photoFinderProvider.future);
      if (!now.ready(s)) return;
    }
    await ref.mutate((x) => x.book.setPref(PrefKeys.photoSource, s.name));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final finder = ref.watch(photoFinderProvider).value;
    final picked = ref.watch(photoSourceProvider).value ?? PhotoSource.openverse;
    if (finder == null) return const SizedBox(height: 48);
    final source = finder.ready(picked) ? picked : PhotoSource.openverse;
    final key = (source, widget.query, finder);
    if (_for != key) {
      _for = key;
      _photos.clear();
      _page = 0;
      _more = false;
      _error = null;
      _busy = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _for == key) _load(finder, source);
      });
    }
    final pinned = widget.room == null
        ? const <String>{}
        : {
            for (final p in ref.watch(pinsProvider(widget.room!)).value ?? const <IdeaPhoto>[])
              '${p.source.name}.${p.id}',
          };
    final error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<PhotoSource>(
              segments: [for (final s in PhotoSource.values) ButtonSegment(value: s, label: Text(s.label))],
              selected: {source},
              onSelectionChanged: (s) => _choose(s.first, finder),
            ),
            IconButton(
              tooltip: 'Photo sources',
              onPressed: () => showPhotoSources(context, ref),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_photos.isNotEmpty)
          LayoutBuilder(
            builder: (context, c) {
              final cols = (c.maxWidth / 170).floor().clamp(2, 6);
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (final (i, p) in _photos.indexed)
                    FadeIn(
                      delay: Duration(milliseconds: 25 * (i % 20).clamp(0, 10)),
                      child: Pressable(
                        onTap: () => showPhoto(context, p, room: widget.room),
                        child: _Tile(p, finder: finder, pinned: pinned.contains('${p.source.name}.${p.id}')),
                      ),
                    ),
                ],
              );
            },
          ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  describeError(error),
                  style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.error),
                ),
                if (error is PhotoSearchException && error.limited && finder.openverse == null)
                  TextButton(
                    onPressed: () => showPhotoSources(context, ref),
                    child: const Text('Register with Openverse'),
                  ),
                TextButton(onPressed: () => _load(finder, source), child: const Text('Try again')),
              ],
            ),
          )
        else if (_photos.isEmpty && _page > 0)
          Text('No photos found for “${widget.query}”.', style: t.textTheme.bodySmall)
        else if (_more)
          Align(
            child: TextButton.icon(
              onPressed: () => _load(finder, source),
              icon: const Icon(Icons.expand_more),
              label: const Text('More photos'),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Searching for “${widget.query}” on ${source.label}. Only these words are sent; the photos load '
          'from ${source.label}. Tap a photo for its credit and licence.',
          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.p, {required this.finder, this.pinned = false});
  final IdeaPhoto p;
  final PhotoFinder? finder;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final back = p.colour == null ? scheme.surfaceContainerHigh : Color(0xFF000000 | p.colour!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: back),
          Image.network(
            p.thumb,
            headers: finder?.imageHeaders(p),
            fit: BoxFit.cover,
            cacheWidth: 400,
            semanticLabel: p.title.isEmpty ? null : p.title,
            frameBuilder: (context, child, frame, sync) => sync
                ? child
                : AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: Motion.medium, child: child),
            errorBuilder: (_, _, _) =>
                Icon(Icons.image_not_supported_outlined, color: scheme.onSurfaceVariant),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0x99000000)],
                ),
              ),
              child: Text(
                p.creator,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 11),
              ),
            ),
          ),
          if (pinned)
            Positioned(
              top: 6,
              right: 6,
              child: CircleAvatar(
                radius: 13,
                backgroundColor: scheme.primary,
                child: Icon(Icons.push_pin, size: 15, color: scheme.onPrimary),
              ),
            ),
        ],
      ),
    );
  }
}

/// A room's pinned photos.
class Moodboard extends ConsumerWidget {
  const Moodboard({super.key, required this.room});
  final String room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final pins = ref.watch(pinsProvider(room)).value ?? const <IdeaPhoto>[];
    final finder = ref.watch(photoFinderProvider).value;
    if (pins.isEmpty) {
      return Text(
        'Pin photos from the ideas below to keep them here. Pins sync with the room; the photos stay at '
        'their sources.',
        style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final cols = (c.maxWidth / 170).floor().clamp(2, 6);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: staggered([
            for (final p in pins)
              Pressable(
                onTap: () => showPhoto(context, p, room: room),
                child: Hero(
                  tag: 'pin-$room-${p.source.name}-${p.id}',
                  child: _Tile(p, finder: finder),
                ),
              ),
          ]),
        );
      },
    );
  }
}

/// [p] large, with its credit, licence and a link to its source; pins it to
/// [room], or to a room the user picks.
Future<void> showPhoto(BuildContext context, IdeaPhoto p, {String? room}) =>
    Navigator.of(context).push(fluidRoute<void>(_PhotoPage(p, room: room)));

class _PhotoPage extends ConsumerWidget {
  const _PhotoPage(this.p, {this.room});
  final IdeaPhoto p;
  final String? room;

  Future<void> _pin(BuildContext context, WidgetRef ref, bool pinned) async {
    var to = room;
    if (to == null) {
      to = await _pickRoom(context, ref);
      if (to == null || !context.mounted) return;
    }
    final target = to;
    if (pinned) {
      await ref.mutate((s) => s.book.unpin(target, p));
      if (context.mounted) showMessage(context, 'Removed from the moodboard.');
      return;
    }
    await ref.mutate((s) => s.book.pin(target, p));
    final finder = await ref.read(photoFinderProvider.future);
    await finder.kept(p);
    if (context.mounted) showMessage(context, 'Pinned to the moodboard.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final finder = ref.watch(photoFinderProvider).value;
    final pinned =
        room != null &&
        (ref.watch(pinsProvider(room!)).value ?? const <IdeaPhoto>[]).any(
          (x) => x.source == p.source && x.id == p.id,
        );
    final link = t.textTheme.bodyMedium?.copyWith(
      color: t.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: t.colorScheme.primary,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(p.title.isEmpty ? 'Photo' : p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: AspectRatio(
                  aspectRatio: p.aspect,
                  child: Hero(
                    tag: room == null
                        ? 'photo-${p.source.name}-${p.id}'
                        : 'pin-$room-${p.source.name}-${p.id}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          p.thumb,
                          headers: finder?.imageHeaders(p),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                        Image.network(
                          p.image,
                          fit: BoxFit.contain,
                          frameBuilder: (context, child, frame, sync) => sync
                              ? child
                              : AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: Motion.medium,
                                  child: child,
                                ),
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Readable(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(p.credit, style: t.textTheme.bodyMedium),
                        if (p.creatorUrl.isNotEmpty)
                          InkWell(
                            onTap: () => openLink(context, p.creatorUrl),
                            child: Text(p.creator.isEmpty ? 'Creator' : p.creator, style: link),
                          ),
                        if (p.licenceUrl.isNotEmpty)
                          InkWell(
                            onTap: () => openLink(context, p.licenceUrl),
                            child: Text(p.licence.isEmpty ? 'Licence' : p.licence, style: link),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _pin(context, ref, pinned),
                          icon: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined),
                          label: Text(
                            pinned
                                ? 'Unpin'
                                : room == null
                                ? 'Pin to a room'
                                : 'Pin to the moodboard',
                          ),
                        ),
                        if (p.page.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => openLink(context, p.page),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: Text('Open on ${p.source.label}'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> _pickRoom(BuildContext context, WidgetRef ref) async {
  final rooms = await ref.read(allRoomsProvider.future);
  if (!context.mounted) return null;
  if (rooms.isEmpty) {
    showMessage(context, 'Add a room first; pins belong to a room.');
    return null;
  }
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Pin to which room?'),
      children: [
        for (final r in rooms)
          SimpleDialogOption(onPressed: () => Navigator.pop(context, r.id), child: Text(r.name)),
      ],
    ),
  );
}

/// Where ideas photos come from: registering with Openverse for more
/// searches, and the user's own Unsplash key. Both stay in this device's
/// keychain.
Future<void> showPhotoSources(BuildContext context, WidgetRef ref) async {
  await showDialog<void>(context: context, builder: (_) => const _SourcesDialog());
  ref.invalidate(photoFinderProvider);
}

class _SourcesDialog extends ConsumerStatefulWidget {
  const _SourcesDialog();

  @override
  ConsumerState<_SourcesDialog> createState() => _SourcesDialogState();
}

class _SourcesDialogState extends ConsumerState<_SourcesDialog> {
  final _email = TextEditingController();
  final _key = TextEditingController();
  OpenverseApp? _openverse;
  bool _hasKey = false, _busy = false, _loaded = false;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    final vault = ref.read(keyVaultProvider);
    final o = OpenverseApp.decode(await vault.photoKey(PhotoSource.openverse));
    final k = await vault.photoKey(PhotoSource.unsplash);
    if (!mounted) return;
    setState(() {
      _openverse = o;
      _hasKey = (k ?? '').isNotEmpty;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      showMessage(context, 'Enter an email address Openverse can send its link to.');
      return;
    }
    setState(() => _busy = true);
    try {
      final app = await registerOpenverse(ref.read(httpClientProvider), email);
      await ref.read(keyVaultProvider).setPhotoKey(PhotoSource.openverse, app.encode());
      if (mounted) setState(() => _openverse = app);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _set(PhotoSource s, String value) async {
    await ref.read(keyVaultProvider).setPhotoKey(s, value);
    await _read();
    _key.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final soft = t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant);
    final o = _openverse;
    return AlertDialog(
      title: const Text('Photo sources'),
      content: SizedBox(
        width: 480,
        child: !_loaded
            ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
            : ListView(
                shrinkWrap: true,
                children: [
                  Text('Openverse', style: t.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Openly licensed photos, gathered by WordPress.org. Without registering it allows 5 '
                    'searches an hour.',
                    style: soft,
                  ),
                  const SizedBox(height: 8),
                  if (o == null) ...[
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Your email address'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Registering sends this address to Openverse, which emails a link to confirm it. Once '
                      'it is opened, Vinyasa can make about 10,000 searches a day. The details Openverse '
                      'returns stay in this device’s keychain.',
                      style: soft,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonal(
                        onPressed: _busy ? null : _register,
                        child: Text(_busy ? 'Registering…' : 'Register with Openverse'),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Registered for ${o.email}. If searches stay limited, open the link Openverse '
                      'emailed.',
                      style: t.textTheme.bodyMedium,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => _set(PhotoSource.openverse, ''),
                        child: const Text('Forget this registration'),
                      ),
                    ),
                  ],
                  const Divider(height: 32),
                  Text('Unsplash', style: t.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Many of the best interior photos. Needs your own free access key: make an app at '
                    'unsplash.com/oauth/applications and copy its Access Key. 50 searches an hour.',
                    style: soft,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => openLink(context, 'https://unsplash.com/oauth/applications'),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Get a key'),
                    ),
                  ),
                  if (_hasKey)
                    Row(
                      children: [
                        const Expanded(child: Text('An access key is kept on this device.')),
                        TextButton(
                          onPressed: () => _set(PhotoSource.unsplash, ''),
                          child: const Text('Remove'),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _key,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Access key'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () {
                            final k = _key.text.trim();
                            if (k.isNotEmpty) _set(PhotoSource.unsplash, k);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                ],
              ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
    );
  }
}
