import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinyasa/app/modules.dart';
import 'package:vinyasa/domain/analysis.dart';
import 'package:vinyasa/domain/book.dart';
import 'package:vinyasa/domain/samples.dart';
import 'package:vinyasa/domain/space.dart';
import 'package:vinyasa/ui/plan_view.dart';

import 'app_harness.dart';

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
}
