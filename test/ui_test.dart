import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/gestures.dart';
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
import 'package:vinyasa/ui/room_3d.dart';

import 'app_harness.dart';
import 'photos_test.dart' show openverseJson;
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
      for (final tab in ['3D', 'Analysis', 'Arrange', 'Storage', 'Photos', 'Ideas', 'Plan']) {
        await app.tap(find.widgetWithText(Tab, tab));
        expect(tester.takeException(), isNull, reason: '$tab (phone: $phone)');
      }
      await app.close();
    }
  });

  testWidgets('the 3D view turns, zooms and glides between views; Analysis switches to 3D', (tester) async {
    for (final phone in [false, true]) {
      final app = AppHarness(tester);
      phone ? app.phone() : app.desktop();
      await app.open();
      await app.run();
      await app.tapText('Try an example');
      await app.tap(find.text('Bedroom').first);
      await app.tap(find.widgetWithText(Tab, '3D'));
      final view = find.byType(Room3D);
      expect(view, findsOneWidget);
      await tester.drag(view, const Offset(-120, 40));
      await app.settle();
      for (final button in ['From above', 'From the door', 'From a corner']) {
        // Not app.tap: ensureVisible would scroll the tab pages sideways.
        await tester.tap(find.byTooltip(button));
        await app.settle();
        expect(tester.takeException(), isNull, reason: '$button (phone: $phone)');
      }
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(view));
      await tester.sendEventToBinding(
        PointerScrollEvent(position: tester.getCenter(view), scrollDelta: const Offset(0, 200)),
      );
      await app.settle();
      await mouse.removePointer();

      await app.tap(find.widgetWithText(Tab, 'Analysis'));
      expect(find.byType(Room3D), findsNothing);
      await app.tap(find.byTooltip('Show in 3D'));
      expect(find.byType(Room3D), findsOneWidget);
      await app.tap(find.byTooltip('Show the plan'));
      expect(find.byType(Room3D), findsNothing);
      expect(tester.takeException(), isNull);
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

  testWidgets('an older kept plan moves the pieces but keeps later changes to the room', (tester) async {
    final app = AppHarness(tester)..desktop();
    late Item moved;
    await app.open(
      seed: (book) async {
        await seedHome(book);
        final now = (await book.room('room2'))!;
        moved = now.items.firstWhere((i) => !i.fixed);
        // The plan was made when the room had another name.
        final arranged = now.copyWith(
          name: 'Old name',
          items: [for (final i in now.items) i.id == moved.id ? i.copyWith(x: i.x + 300) : i],
        );
        await book.savePlan(room: 'room2', arranged: arranged, before: 50, after: 60);
      },
    );
    await app.run();
    await app.tap(find.text('Kitchen').first);
    await app.tap(find.widgetWithText(Tab, 'Arrange'));
    await app.tapText('50 → 60');
    for (final box in find.byType(Checkbox).evaluate().toList()) {
      await app.tap(find.byWidget(box.widget));
    }
    await app.tap(find.text('Done: update the room'));
    final room = (await tester.runAsync(() => app.book.room('room2')))!;
    expect(room.name, 'Kitchen');
    expect(room.item(moved.id)!.x, moved.x + 300);
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

  testWidgets('things listed on the Storage tab are given shelves and kept with the room', (tester) async {
    for (final phone in [false, true]) {
      final app = AppHarness(tester);
      phone ? app.phone() : app.desktop();
      await app.open(seed: seedHome);
      await app.run();
      await app.tap(find.text('Bedroom').first);
      await app.tap(find.widgetWithText(Tab, 'Storage'));
      await app.tapText('Add things');
      await tester.enterText(find.byType(TextField).first, 'Shirts, Winter quilt');
      await app.tapText('Save');
      expect(find.text('Where things go'), findsOneWidget);
      expect(find.text('Shirts'), findsWidgets);
      expect(find.textContaining('Shelf 1'), findsWidgets);
      final room = await tester.runAsync(() => app.book.room('room0'));
      expect(room!.things.map((t) => t.name), ['Shirts', 'Winter quilt']);
      expect(tester.takeException(), isNull, reason: 'phone: $phone');
      await app.close();
    }
  });

  testWidgets('a piece to buy is tried in the room and put on the plan', (tester) async {
    for (final phone in [false, true]) {
      final app = AppHarness(tester);
      phone ? app.phone() : app.desktop();
      await app.open(seed: seedHome);
      await app.run();
      await app.tap(find.text('Bedroom').first);
      await app.tap(find.widgetWithText(Tab, 'Arrange'));
      await app.tapText('Will it fit?');
      await app.tapText('What is it?');
      await tester.enterText(find.byType(TextField).last, 'bookshelf');
      await app.settle();
      await app.tap(find.text('Bookshelf').last);
      await app.tapText('Find places');
      // The places are found in an isolate: real time.
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
      await app.settle();
      expect(find.text('Gets through the door'), findsOneWidget);
      expect(find.text('Best place'), findsOneWidget);
      await app.tap(find.text('Put it here on the plan').first);
      final room = await tester.runAsync(() => app.book.room('room0'));
      expect(room!.items.where((i) => i.kind == 'bookshelf'), hasLength(1));
      expect(tester.takeException(), isNull, reason: 'phone: $phone');
      await app.close();
    }
  });

  testWidgets('a photo from the ideas is pinned to the room’s moodboard', (tester) async {
    final app = AppHarness(tester)..desktop();
    await app.open(seed: seedHome);
    await app.run(
      client: MockClient(
        (r) async => r.url.host == 'api.openverse.org'
            ? http.Response(openverseJson(), 200)
            : http.Response('[]', 200),
      ),
    );
    await app.tap(find.text('Bedroom').first);
    await app.tap(find.widgetWithText(Tab, 'Ideas'));
    expect(find.text('Ana'), findsOneWidget);
    await app.tap(find.text('Ana'));
    expect(find.textContaining('CC BY 2.0'), findsWidgets);
    await app.tapText('Pin to the moodboard');
    final pins = await tester.runAsync(() => app.book.pins('room0'));
    expect(pins, hasLength(1));
    await tester.pageBack();
    await app.settle();
    expect(find.text('Ana'), findsNWidgets(2), reason: 'on the moodboard and in the ideas');
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    expect(tester.takeException(), isNull);
    await app.close();
  });
}
