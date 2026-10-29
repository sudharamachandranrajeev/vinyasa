import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinyasa/app/crash_log_page.dart';
import 'package:vinyasa/domain/crash_log.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('crash'));
  tearDown(() => dir.deleteSync(recursive: true));

  CrashLog open({DateTime? started}) =>
      CrashLog(dir, facts: const {'App': 'Vinyasa 9.9.9', 'System': 'test'}, started: started);

  test('an error is written at once with its facts, full stack and what came before', () {
    final log = open()..note('opened RoomPage');
    try {
      throw StateError('the plan broke');
    } catch (e, s) {
      log.record(e, s, kind: 'uncaught', context: 'saving a room');
    }
    final e = log.entries().single;
    expect(e.kind, 'uncaught');
    expect(e.headline, 'Bad state: the plan broke');
    for (final part in [
      'App: Vinyasa 9.9.9',
      'Error type: StateError',
      'While: saving a room',
      'crash_log_test.dart',
      'opened RoomPage',
    ]) {
      expect(e.text, contains(part));
    }
    expect(log.report(), allOf(contains('Entries: 1'), contains('Bad state: the plan broke')));
  });

  test('keeps the newest entries only, newest first', () {
    final log = open();
    for (var i = 0; i < CrashLog.keep + 5; i++) {
      log.record('error $i', null, kind: 'flutter');
    }
    final all = log.entries();
    expect(all, hasLength(CrashLog.keep));
    expect(all.first.headline, 'error ${CrashLog.keep + 4}');
    expect(log.report(limit: 3), contains('(newest 3 shown)'));
  });

  test('entries from an earlier run are unseen until looked at', () {
    open().record('last time', null, kind: 'uncaught');
    sleep(const Duration(milliseconds: 5));
    final now = open();
    now.record('this time', null, kind: 'uncaught');
    expect([for (final e in now.unseen()) e.headline], ['last time']);
    now.markSeen();
    expect(now.unseen(), isEmpty);
    now.clear();
    expect(now.entries(), isEmpty);
  });

  test('reads what Android writes for a native crash, and ignores other files', () {
    File('${dir.path}/crash-1767225600000-native.txt').writeAsStringSync(
      'Time: 2026-01-01T00:00:00.000Z\nKind: native\nError type: java.lang.IllegalStateException\nError: boom',
    );
    File('${dir.path}/notes.txt').writeAsStringSync('not a crash');
    final e = open().entries().single;
    expect((e.kind, e.headline, e.when.year), ('native', 'boom', 2026));
  });

  // Made up, and built here so secret scanners do not flag the test.
  final fakeGoogleKey = 'AIza${'x' * 35}';

  test('leaves out the home folder, the account name and e-mail addresses', () {
    const env = {'HOME': '/home/someone', 'USER': 'someone'};
    expect(
      redact('at /home/someone/app.dart and /mnt/someone/x, mail a.b@example.com', environment: env),
      'at ~/app.dart and /mnt/<user>/x, mail <email>',
    );
    expect(
      redact(
        'GET https://x.googleapis.com/v1/m?alt=sse&key=$fakeGoogleKey failed; '
        'Authorization: Bearer abc.def; x-api-key: secret123; sk-ant-api03-abcdefghijklmnopqrstuv',
        environment: const {},
      ),
      'GET https://x.googleapis.com/v1/m?alt=sse&key=<hidden> failed; '
      'Authorization: Bearer <hidden> x-api-key: <hidden> <hidden>',
    );
  });

  testWidgets('the crash log page lists entries, shows one in full and clears', (tester) async {
    final log = open()..record(StateError('the plan broke'), StackTrace.current, kind: 'uncaught');
    await tester.pumpWidget(MaterialApp(home: CrashLogPage(log)));
    expect(find.text('Bad state: the plan broke'), findsOneWidget);
    expect(find.textContaining('Uncaught error'), findsOneWidget);
    await tester.tap(find.text('Bad state: the plan broke'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Error type: StateError'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Clear'));
    await tester.pumpAndSettle();
    expect(find.text('No crashes'), findsOneWidget);
    expect(log.entries(), isEmpty);
  });
}
