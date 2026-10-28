import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;

import '../db/database.dart';
import '../domain/analysis.dart';
import '../domain/book.dart';
import '../domain/json.dart';
import '../domain/photos.dart';
import '../domain/space.dart';
import '../domain/themes.dart';
import '../domain/update.dart';
import '../domain/vision.dart';
import '../ui/hints.dart';
import '../ui/look.dart';
import 'session.dart';

/// The open session; main() overrides this before the first frame.
final sessionProvider = Provider<AppSession>((ref) => throw StateError('No session'));

/// HTTP for updates and online ideas; tests override it.
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

/// The self-updater: main() sets it in a release build of the standalone app.
/// Null in the Brahma suite (which updates itself) and in tests.
final updaterProvider = Provider<Updater?>((ref) => null);

/// Builds the photo reader for an Ask AI setup, with its key from the
/// keychain. Tests swap the HTTP client.
final visionAskerProvider = Provider<Future<VisionAsker> Function(HelpAiSetup)>((ref) {
  return (setup) async => VisionAsker(
    setup,
    key: setup.via.needsKey || setup.via == HelpAi.local
        ? await ref.read(keyVaultProvider).aiKey(setup.via.name)
        : null,
    client: ref.read(httpClientProvider),
  );
});

/// Searches for ideas photos with the keys in the keychain. Rebuilt when a
/// key changes (ref.invalidate), which also forgets the remembered answers.
final photoFinderProvider = FutureProvider<PhotoFinder>((ref) async {
  final vault = ref.watch(keyVaultProvider);
  return PhotoFinder(
    ref.watch(httpClientProvider),
    unsplashKey: await vault.photoKey(PhotoSource.unsplash),
    openverse: OpenverseApp.decode(await vault.photoKey(PhotoSource.openverse)),
  );
});

/// The source picked last for ideas photos.
final photoSourceProvider = FutureProvider<PhotoSource>((ref) async {
  ref.watch(revisionProvider);
  return PhotoSource.of(await ref.watch(sessionProvider).book.pref<String>(PrefKeys.photoSource, ''));
});

/// A room's moodboard.
final pinsProvider = FutureProvider.family<List<IdeaPhoto>, String>((ref, room) async {
  ref.watch(revisionProvider);
  final rows = await ref.watch(sessionProvider).book.pins(room);
  return [for (final r in rows) ?_tryPhoto(r.json)];
});

IdeaPhoto? _tryPhoto(String json) {
  try {
    final p = IdeaPhoto.fromJson(decodeObject(json));
    return p.image.isEmpty ? null : p;
  } on FormatException {
    return null;
  }
}

/// What main() and the tests override: the session, under both its own and
/// its shared type, and the app's identity and hints.
List<Override> vinyasaOverrides(
  AppSession session, {
  http.Client? client,
  Updater? updater,
  List<VinTheme>? builtInThemes,
}) => [
  sessionProvider.overrideWithValue(session),
  coreSessionProvider.overrideWithValue(session),
  appIdentityProvider.overrideWithValue(vinyasaIdentity),
  hintTextsProvider.overrideWithValue({...coreHints, ...vinyasaHints}),
  sentinelChecksProvider.overrideWithValue([...coreChecks, lockCheck]),
  if (client != null) httpClientProvider.overrideWithValue(client),
  if (updater != null) ...[
    updaterProvider.overrideWithValue(updater),
    // The app offers its own updates, which install in place; core's
    // banner would only point at the releases page.
    startupUpdateProvider.overrideWith((ref) async => null),
  ],
  if (builtInThemes != null) builtInThemesProvider.overrideWith((ref) => builtInThemes),
];

extension Mutate on WidgetRef {
  /// Runs a write, refreshes the screens and queues a sync.
  Future<T> mutate<T>(Future<T> Function(AppSession s) write) async {
    final result = await write(read(sessionProvider));
    changed();
    return result;
  }
}

// ---- updates ----

/// Set when the user asks for an update check, so one runs even with the
/// start-up check turned off.
class UpdateAsked extends Notifier<bool> {
  @override
  bool build() => false;
  void ask() => state = true;
}

final updateAskedProvider = NotifierProvider<UpdateAsked, bool>(UpdateAsked.new);

/// A newer release for this device, looked for once a run (at start unless
/// the user turned that off in Settings); null when this is the newest,
/// there is no updater, or nobody asked. A version the user went back from
/// is not offered at start again, only when they ask.
final updateProvider = FutureProvider<Release?>((ref) async {
  final updater = ref.watch(updaterProvider);
  if (updater == null) return null;
  final book = ref.read(sessionProvider).book;
  final asked = ref.watch(updateAskedProvider);
  if (!asked && !await book.updateOnStart()) return null;
  return updater.check(skipped: asked ? '' : await book.updateSkipped());
});

final updateOnStartProvider = FutureProvider<bool>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.updateOnStart();
});

/// Releases older than this one that can be gone back to, newest first.
final earlierReleasesProvider = FutureProvider.autoDispose<List<Release>>((ref) async {
  final updater = ref.watch(updaterProvider);
  return updater == null ? const [] : updater.earlier();
});

/// The versions this device has run, newest last (main() notes each start).
final versionsProvider = FutureProvider<List<String>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.versions();
});

// ---- themes ----

/// Reads themes/builtin.json: under its own name in the standalone app,
/// under the package's in the Brahma suite.
Future<List<VinTheme>> loadBuiltInThemes() async {
  String text;
  try {
    text = await rootBundle.loadString('themes/builtin.json');
  } on Object {
    text = await rootBundle.loadString('packages/vinyasa/themes/builtin.json');
  }
  return parseBuiltInThemes(text);
}

final builtInThemesProvider = FutureProvider<List<VinTheme>>((ref) => loadBuiltInThemes());

/// The user's own themes (synced); rows that no longer parse are skipped.
final customThemesProvider = FutureProvider<List<VinTheme>>((ref) async {
  ref.watch(revisionProvider);
  final rows = await ref.watch(sessionProvider).book.themes();
  return [for (final r in rows) ?_tryTheme(r)];
});

VinTheme? _tryTheme(ThemeRow r) {
  try {
    return VinTheme.decode(r.json);
  } on FormatException {
    return null;
  }
}

/// The theme used before the list has loaded, and when the chosen one is
/// gone: Terracotta, the first built-in theme.
const fallbackTheme = VinTheme(
  id: 'terracotta',
  name: 'Terracotta',
  seed: Color(0xFFB5562F),
  accent: Color(0xFF2F8F83),
  furniture: Color(0xFFA86A45),
  zone: Color(0xFF3E9BB0),
  lightBackground: Color(0xFFFAF5F0),
  darkBackground: Color(0xFF17110E),
  radius: 18,
  builtIn: true,
);

/// Every theme, built-in first.
final allThemesProvider = FutureProvider<List<VinTheme>>(
  (ref) async => [
    ...await ref.watch(builtInThemesProvider.future),
    ...await ref.watch(customThemesProvider.future),
  ],
);

class Appearance {
  const Appearance(this.theme, this.mode, {this.calm = false});
  final VinTheme theme;
  final ThemeMode mode;

  /// No drifting backdrop (Settings › Look).
  final bool calm;
}

/// The chosen theme, light/dark mode and motion, kept on this device.
final appearanceProvider = FutureProvider<Appearance>((ref) async {
  ref.watch(revisionProvider);
  final db = ref.watch(sessionProvider).db;
  final id = await db.localSetting(LocalKeys.theme);
  final mode = switch (await db.localSetting(LocalKeys.mode)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  final calm = await db.localSetting(LocalKeys.motion) == 'calm';
  ambientMotion.value = !calm;
  final themes = await ref.watch(allThemesProvider.future);
  return Appearance(
    themes.where((t) => t.id == id).firstOrNull ?? themes.firstOrNull ?? fallbackTheme,
    mode,
    calm: calm,
  );
});

Future<void> chooseTheme(WidgetRef ref, String id) async {
  await ref.read(sessionProvider).db.setLocalSetting(LocalKeys.theme, id);
  ref.changed();
}

Future<void> chooseMode(WidgetRef ref, ThemeMode mode) async {
  await ref.read(sessionProvider).db.setLocalSetting(LocalKeys.mode, mode.name);
  ref.changed();
}

Future<void> chooseCalm(WidgetRef ref, bool calm) async {
  await ref.read(sessionProvider).db.setLocalSetting(LocalKeys.motion, calm ? 'calm' : 'flow');
  ref.changed();
}

// ---- spaces and rooms ----

final spacesProvider = FutureProvider<List<SpaceRow>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.spaces();
});

/// Every room, newest first, for the spaces page to group by space.
final allRoomsProvider = FutureProvider<List<RoomRow>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.allRooms();
});

/// A room as saved, or null once it is gone.
final roomProvider = FutureProvider.family<Room?, String>((ref, id) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.room(id);
});

/// The rules run over a room. Quick enough (a few milliseconds) to run on
/// the UI thread whenever the room changes.
final reportProvider = FutureProvider.family<Report?, String>((ref, id) async {
  final room = await ref.watch(roomProvider(id).future);
  return room == null ? null : analyse(room);
});

/// The arrangements made for a room, newest first.
final roomPlansProvider = FutureProvider.family<List<PlanRow>, String>((ref, room) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.plans(room);
});

/// The photos and videos kept for a room on this device.
final mediaProvider = FutureProvider.family<List<MediaRow>, String>((ref, room) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.media(room);
});

/// The look picked last on the Ideas page.
final ideasStyleProvider = FutureProvider<String>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(sessionProvider).book.pref<String>(PrefKeys.ideasStyle, '');
});
