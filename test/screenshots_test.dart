import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

/// Renders the main screens with the real fonts to PNG files, for checking
/// the look and for the README. Runs only when VINYASA_SHOTS names an output
/// folder: `VINYASA_SHOTS=/tmp/shots flutter test test/screenshots_test.dart`.
///
/// The data is the app's own example home (Try an example): made up.
void main() {
  final out = Platform.environment['VINYASA_SHOTS'];

  Future<void> loadFonts() async {
    Future<void> family(String name, List<String> files) async {
      final loader = FontLoader(name);
      for (final f in files) {
        loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
      }
      await loader.load();
    }

    await family('Inter', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) 'assets/fonts/Inter-$w.ttf',
    ]);
    await family('PlusJakartaSans', [
      for (final w in ['Medium', 'SemiBold', 'Bold', 'ExtraBold']) 'assets/fonts/PlusJakartaSans-$w.ttf',
    ]);
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
    final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) await family('MaterialIcons', [icons.path]);
  }

  testWidgets('screenshots', skip: out == null, (tester) async {
    await tester.runAsync(loadFonts);
    // Tests draw elevation as black outlines unless told otherwise.
    debugDisableShadows = false;

    Future<void> shot(String name) async {
      // The root layer already scales to device pixels.
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      final size = tester.view.physicalSize;
      final bytes = await tester.runAsync(() async {
        final image = await layer.toImage(Offset.zero & size);
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      File('$out/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    Future<AppHarness> start() async {
      final app = AppHarness(tester);
      await app.open(
        seed: (book) => book.db.setLocalSetting(
          'ui.hints.dismissed',
          jsonEncode([
            for (final h in ['spaces', 'ideas', 'themes', 'settings']) 'nav.$h',
            for (final h in ['spaces', 'ideas', 'themes']) 'page.$h',
            'room.score', 'room.weights', 'room.north', 'room.vaastu', 'plan.drag', 'plan.layers',
            'storage.how', 'arrange.how', 'arrange.steps', 'photos.what',
          ]),
        ),
      );
      await app.run();
      await app.tapText('Try an example');
      return app;
    }

    Future<void> tab(AppHarness app, String name) => app.tap(find.widgetWithText(Tab, name));

    // Phone, light and dark.
    for (final dark in [false, true]) {
      tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      final mode = dark ? 'dark' : 'light';
      final app = await start();
      await shot('spaces-$mode');
      await app.tap(find.text('Bedroom').first);
      await shot('plan-$mode');
      if (!dark) {
        await tab(app, '3D');
        await shot('3d-$mode');
        await tab(app, 'Analysis');
        await shot('analysis-$mode');
        await tab(app, 'Arrange');
        await app.tapText('Find a better arrangement');
        for (var i = 0; i < 10 && find.text('Keep and show steps').evaluate().isEmpty; i++) {
          await app.settle();
        }
        await shot('arrange-$mode');
      }
      await app.close();
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();

    // Desktop window.
    tester.view.physicalSize = const Size(1440, 860);
    tester.view.devicePixelRatio = 1;
    final app = await start();
    await app.tap(find.text('Living room').first);
    await shot('plan-desktop');
    await tab(app, '3D');
    await shot('3d-desktop');
    await app.close();
    tester.view.reset();
    debugDisableShadows = true;
  });
}
