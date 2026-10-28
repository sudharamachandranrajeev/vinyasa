import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:vinyasa/app/modules.dart';
import 'package:vinyasa/domain/analysis.dart';
import 'package:vinyasa/domain/book.dart';
import 'package:vinyasa/domain/samples.dart';
import 'package:vinyasa/domain/space.dart';
import 'package:vinyasa/ui/plan_view.dart';

import 'app_harness.dart';
import 'vision_test.dart' show planJson;

/// An example home with the three sample rooms.
Future<void> seedHome(SpaceBook book) async {
  final space = await book.saveSpace(name: 'Test home', kind: SpaceKind.home);
  for (final (i, make) in [sampleBedroom, sampleLiving, sampleKitchen].indexed) {
    final room = make('room$i');
    await book.saveRoom(room, space: space, score: analyse(room).overall);
  }
}

/// Smoke tests: every page builds, with and without data, on phone and
/// desktop widths, without throwing or overflowing; and the main flows.
void main() {
  final pages = [for (final d in allDestinations) d.label];

  testWidgets('every page builds on a desktop window, empty and with data', (tester) async {
    for (final seeded in [false, true]) {
      final app = AppHarness(tester)..desktop();
      await app.open(seed: seeded ? seedHome : null);
      await app.run();
      for (final label in pages) {
        await app.go(label);
        expect(tester.takeException(), isNull, reason: '$label (seeded: $seeded)');
      }
      await app.close();
    }
  });

  testWidgets('every page builds on a phone', (tester) async {
    final app = AppHarness(tester)..phone();
    await app.open(seed: seedHome);
    await app.run();
    for (final label in pages) {
      await app.go(label);
      expect(tester.takeException(), isNull, reason: label);
    }
    await app.close();
  });

  testWidgets('the example opens, and a room shows every tab', (tester) async {
    for (final phone in [false, true]) {
      final app = AppHarness(tester);
      phone ? app.phone() : app.desktop();
      await app.open();
      await app.run();
      await app.tapText('Try an example');
      expect(find.text('Example home'), findsOneWidget);
      await app.tap(find.text('Bedroom').first);
      expect(find.byType(PlanView), findsWidgets);
      for (final tab in ['Analysis', 'Arrange', 'Photos', 'Ideas', 'Plan']) {
        await app.tap(find.widgetWithText(Tab, tab));
        expect(tester.takeException(), isNull, reason: '$tab (phone: $phone)');
      }
      await app.close();
    }
  });

  testWidgets('a kept arrangement gives steps, and ticking them all updates the room', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedHome);
    await app.run();
    await app.tap(find.text('Kitchen').first);
    await app.tap(find.widgetWithText(Tab, 'Arrange'));
    await app.tap(find.text('Find a better arrangement'));
    // The planner runs in an isolate: real time.
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
    await app.settle();
    await app.tap(find.text('Keep and show steps'));
    expect(find.text('Clear the way', findRichText: true), findsNothing);
    expect(find.textContaining('Clear the way'), findsOneWidget);
    for (final box in find.byType(Checkbox).evaluate().toList()) {
      await app.tap(find.byWidget(box.widget));
    }
    await app.tap(find.text('Done: update the room'));
    final kitchen = await tester.runAsync(() => app.book.room('room2'));
    expect(analyse(kitchen!).overall, greaterThan(analyse(sampleKitchen('x')).overall));
    await app.close();
  });

  testWidgets('a plan made from a photo is checked, then replaces the room', (tester) async {
    final app = AppHarness(tester)..desktop();
    late Directory dir;
    await app.open(
      seed: (book) async {
        await seedHome(book);
        dir = await Directory.systemTemp.createTemp('vinyasa-scan-');
        final photo = File('${dir.path}/corner.jpg')
          ..writeAsBytesSync(img.encodeJpg(img.Image(width: 64, height: 48)));
        await book.addMedia('room0', photo.path, 'photo');
      },
    );
    await tester.runAsync(() async {
      await app.session.db.setLocalSetting(
        'ai.help',
        jsonEncode(const HelpAiSetup(via: HelpAi.anthropic).toJson()),
      );
      await app.session.keys.setAiKey('anthropic', 'test-key');
    });
    var calls = 0;
    await app.run(
      client: MockClient((r) async {
        if (r.url.host != 'api.anthropic.com') return http.Response('[]', 200);
        calls++;
        return http.Response(
          jsonEncode({
            'stop_reason': 'end_turn',
            'content': [
              {'type': 'text', 'text': planJson()},
            ],
          }),
          200,
        );
      }),
    );
    await app.tap(find.text('Bedroom').first);
    await app.tap(find.widgetWithText(Tab, 'Photos'));
    await app.tapText('Make a plan from these');
    expect(find.textContaining('to Anthropic API key'), findsOneWidget);
    await app.tapText('Send');
    // The photo is cleaned in an isolate: real time.
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    await app.settle();
    expect(calls, 1);
    expect(find.text('The left wall was hidden.'), findsOneWidget);
    await app.tapText('Use this plan');
    await app.tapText('Replace');
    final room = await tester.runAsync(() => app.book.room('room0'));
    // The unsure wardrobe starts unticked, so the bed and the piano stay.
    expect(room!.items.map((i) => i.kind).toList()..sort(), ['bed_double', 'generic']);
    expect((room.width, room.depth), (3600, 3300));
    expect(room.name, 'Bedroom');
    await app.close();
    await tester.runAsync(() => dir.delete(recursive: true));
  });
}
