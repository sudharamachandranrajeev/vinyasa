import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/book.dart';
import '../domain/ideas.dart';
import '../domain/space.dart';
import 'common.dart';
import 'motion.dart';

/// Looks to aim for, the most-loved tips, and searches on Pinterest, Houzz,
/// Behance, Dribbble and Unsplash.
class IdeasPage extends ConsumerWidget {
  const IdeasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picked = lookOf(ref.watch(ideasStyleProvider).value ?? '');
    return PageScaffold(
      title: 'Ideas',
      banner: 'page.ideas',
      children: [
        SectionCard(
          title: 'Looks',
          child: LookGrid(
            selected: picked?.id,
            onPick: (l) =>
                ref.mutate((s) => s.book.setPref(PrefKeys.ideasStyle, l.id == picked?.id ? '' : l.id)),
          ),
        ),
        if (picked != null)
          SectionCard(
            title: 'Find ${picked.name.toLowerCase()} ideas',
            child: SearchButtons(query: '${picked.name.toLowerCase()} interior'),
          ),
        SectionCard(
          title: 'Tips people love most',
          child: Column(children: [for (final t in tips) _TipTile(t)]),
        ),
      ],
    );
  }
}

/// The looks as cards with their palettes; the picked one is ringed.
class LookGrid extends StatelessWidget {
  const LookGrid({super.key, required this.selected, required this.onPick});
  final String? selected;
  final ValueChanged<Look> onPick;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final cols = (c.maxWidth / 220).floor().clamp(1, 4);
        final w = (c.maxWidth - 10 * (cols - 1)) / cols;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: staggered(stepMs: 30, [
            for (final l in looks)
              SizedBox(
                width: w,
                child: Pressable(
                  onTap: () => onPick(l),
                  child: AnimatedContainer(
                    duration: Motion.reduced(context) ? Duration.zero : Motion.medium,
                    curve: Motion.curve,
                    decoration: BoxDecoration(
                      color: t.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: l.id == selected ? t.colorScheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 44,
                          child: Row(
                            children: [
                              for (final p in l.palette)
                                Expanded(child: ColoredBox(color: Color(0xFF000000 | p))),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.name, style: t.textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                                l.about,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }
}

/// A button per site, each opening a search for [query].
class SearchButtons extends StatelessWidget {
  const SearchButtons({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('“$query”', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in ideaSites)
            OutlinedButton.icon(
              onPressed: () => openLink(context, s.build(query).toString()),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(s.name),
            ),
        ],
      ),
    ],
  );
}

class _TipTile extends StatelessWidget {
  const _TipTile(this.tip);
  final Tip tip;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(Icons.tips_and_updates_outlined, color: Theme.of(context).colorScheme.tertiary),
    title: Text(tip.title),
    subtitle: Text(tip.why),
  );
}

/// Ideas for one room: its look, searches built from its type and size,
/// and the tips that apply to it.
class RoomIdeas extends ConsumerWidget {
  const RoomIdeas({super.key, required this.room, required this.onLook});
  final Room room;
  final ValueChanged<String> onLook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = lookOf(room.style);
    final mine = [
      for (final t in tips)
        if (t.types == null || t.types!.contains(room.type)) t,
    ];
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 96 + MediaQuery.paddingOf(context).bottom),
      children: [
        Readable(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                title: 'The look you want',
                child: LookGrid(selected: look?.id, onPick: (l) => onLook(l.id == look?.id ? '' : l.id)),
              ),
              SectionCard(
                title: 'Search for this room',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchButtons(query: ideaQuery(room, look: look)),
                    const SizedBox(height: 12),
                    SearchButtons(
                      query: ideaQuery(room, look: look, extra: 'storage ideas'),
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: 'Tips for a ${room.type.label.toLowerCase()}',
                child: Column(children: [for (final t in mine) _TipTile(t)]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
