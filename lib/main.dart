import 'dart:io';

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/session.dart';
import 'domain/update.dart';
import 'ui/look.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _start();
}

Future<void> _start() async {
  try {
    AppErrors.watch();
    final session = await AppSession.open(KeyVault(const DeviceSecretStore(), vinyasaIdentity));
    // Kept for problem reports: which versions this device has run.
    await session.book
        .noteVersion((await PackageInfo.fromPlatform()).version)
        .catchError((_) => const <String>[]);
    runApp(
      ProviderScope(
        overrides: vinyasaOverrides(
          session,
          updater: await _updater(),
          // Loaded before the first frame, so the chosen theme shows at once.
          builtInThemes: await loadBuiltInThemes().catchError((_) => const [fallbackTheme]),
        ),
        // Failures are shown with a retry button; silent retries would hide them.
        retry: (_, _) => null,
        child: const VinyasaApp(),
      ),
    );
  } catch (e) {
    // Also in release builds' logs, where smoke tests look for it.
    debugPrint('Vinyasa startup failed: $e');
    runApp(
      StartupFailure(
        e,
        appName: vinyasaIdentity.name,
        theme: (b) => vinTheme(fallbackTheme, b),
        onRetry: _start,
      ),
    );
  }
}

/// Release builds on the platforms the releases publish for update themselves.
Future<Updater?> _updater() async {
  if (!kReleaseMode || !const {'android', 'windows', 'linux'}.contains(Platform.operatingSystem)) return null;
  return Updater(
    http.Client(),
    current: (await PackageInfo.fromPlatform()).version,
    os: Platform.operatingSystem,
    // Android's FileProvider shares the APK from here (res/xml/file_paths.xml).
    dir: Directory('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}updates'),
  );
}
