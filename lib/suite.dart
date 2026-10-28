import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/session.dart';
import 'ui/hints.dart';
import 'ui/look.dart';

/// Vinyasa as the Brahma suite app hosts it. The suite updates
/// itself, so the app's own updater stays off.
final vinyasaSuite = SuiteApp(
  identity: vinyasaIdentity,
  tagline: 'Space organiser',
  icon: Icons.chair_outlined,
  open: AppSession.open,
  overrides: (s) => [sessionProvider.overrideWithValue(s as AppSession)],
  hints: vinyasaHints,
  theme: chosenTheme,
  themeMode: chosenMode,
  home: (onHome) => VinyasaHome(onHome: onHome),
  builder: (context, child) => Backdrop(child: child ?? const SizedBox.shrink()),
  summary: (_) => const _Summary(),
);

class _Summary extends ConsumerWidget {
  const _Summary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(allRoomsProvider).value;
    if (rooms == null) return const SizedBox(height: 48);
    final scored = [
      for (final r in rooms)
        if (r.score >= 0) r.score,
    ];
    return SummaryFigures([
      ('${ref.watch(spacesProvider).value?.length ?? 0}', 'spaces'),
      ('${rooms.length}', 'rooms'),
      if (scored.isNotEmpty) ('${(scored.reduce((a, b) => a + b) / scored.length).round()}', 'average score'),
    ]);
  }
}
