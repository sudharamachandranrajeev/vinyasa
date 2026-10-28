import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vinyasa/app/app.dart';
import 'package:vinyasa/app/providers.dart';
import 'package:vinyasa/app/session.dart';
import 'package:vinyasa/domain/book.dart';

import 'support.dart';

/// The whole app over a fresh in-memory database, for widget tests. No
/// HTTP leaves the machine.
class AppHarness {
  AppHarness(this.tester);
  final WidgetTester tester;
  late AppSession session;

  SpaceBook get book => session.book;

  /// Opens the database; [seed] runs before the app starts.
  Future<void> open({Future<void> Function(SpaceBook book)? seed}) async {
    await tester.runAsync(() async {
      final store = await Store.open(memoryDatabase());
      session = AppSession(
        KeyVault(MemorySecretStore(), vinyasaIdentity),
        store,
        SpaceBook(store),
        deviceName: 'Test laptop',
      );
      // Past the first-run choice between this device only and sync.
      await session.db.setLocalSetting('onboarding.sync', 'done');
      await seed?.call(session.book);
    });
  }

  Future<void> run() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: vinyasaOverrides(
          session,
          client: MockClient((_) async => http.Response('[]', 200)),
          builtInThemes: builtInThemes(),
        ),
        retry: (_, _) => null,
        child: const VinyasaApp(),
      ),
    );
    await settle();
  }

  Future<void> close() async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => session.db.close());
  }

  /// Lets database work (real I/O) and animations finish.
  Future<void> settle() async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  Future<void> tap(Finder f) async {
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
    await settle();
  }

  Future<void> tapText(String text) => tap(find.text(text).last);

  /// Goes to a top-level page through the rail (desktop) or the dock (phone).
  Future<void> go(String page) async {
    final rail = find.descendant(of: find.byType(NavigationRail), matching: find.text(page));
    if (rail.evaluate().isNotEmpty) return tap(rail);
    await tap(
      find.descendant(
        of: find.byWidgetPredicate((w) => '${w.runtimeType}' == '_Dock'),
        matching: find.byTooltip(page),
      ),
    );
  }

  void desktop() => _size(const Size(1400, 900));

  void phone() => _size(const Size(390, 844));

  void _size(Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
}
