/// Crashes and uncaught errors kept on disk, so they outlive the run that
/// met them, with everything needed to read them later: the full stack, the
/// version and system, and what the app was doing just before. Nothing
/// leaves the device; the user reads the log, then saves, copies or attaches
/// it to a problem report.
library;

import 'dart:io';

/// One file per crash in [CrashLog.dir], named `crash-<utc millis>-<kind>.txt`
/// so names sort by time. Android's native handler (MainActivity.kt) writes
/// the same way, with the kind `native`.
class CrashEntry {
  const CrashEntry(this.file, this.when, this.kind, this.text);
  final File file;
  final DateTime when;
  final String kind;
  final String text;

  /// The first line of the error, for lists.
  String get headline {
    final m = RegExp(r'^Error: (.*)$', multiLine: true).firstMatch(text);
    return m?[1] ?? text.split('\n').first;
  }
}

class CrashLog {
  CrashLog(this.dir, {required this.facts, DateTime? started}) : started = started ?? DateTime.now();

  /// The log this app run writes to; null where none was opened (tests, the
  /// Brahma suite).
  static CrashLog? current;

  final Directory dir;

  /// Version, system and the like, written at the top of every entry.
  final Map<String, String> facts;

  /// When this run began: entries from before it are from an earlier run.
  final DateTime started;

  /// Entries kept; the oldest go first.
  static const keep = 30;
  static const _frames = 150;
  static const _trailLength = 40;

  final _trail = <String>[];

  /// Notes what the app is doing, for the "just before" part of a crash.
  void note(String what) {
    _trail.add('${_clock(DateTime.now())}  $what');
    if (_trail.length > _trailLength) _trail.removeAt(0);
  }

  /// Writes [error] at once and synchronously, so it is on disk even when the
  /// process dies straight after. Never throws: a crash log that crashes
  /// would hide the first error.
  void record(Object error, StackTrace? stack, {required String kind, String? context}) {
    try {
      final now = DateTime.now().toUtc();
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
        // Error messages can hold room names: only the user reads them.
        if (Platform.isLinux) Process.runSync('chmod', ['700', dir.path]);
      }
      var name = 'crash-${now.millisecondsSinceEpoch}-$kind.txt';
      // Two errors in one millisecond keep both.
      for (var n = 2; File('${dir.path}/$name').existsSync(); n++) {
        name = 'crash-${now.millisecondsSinceEpoch}-$kind-$n.txt';
      }
      File('${dir.path}/$name').writeAsStringSync(_entry(error, stack, kind, context, now), flush: true);
      _prune();
    } catch (_) {}
  }

  String _entry(Object error, StackTrace? stack, String kind, String? context, DateTime now) {
    final message = '$error';
    final frames = (stack?.toString() ?? '').split('\n').where((l) => l.trim().isNotEmpty).toList();
    final up = now.difference(started.toUtc());
    return redact(
      [
        'Time: ${now.toIso8601String()}',
        'Kind: $kind',
        for (final f in facts.entries) '${f.key}: ${f.value}',
        'Running for: ${up.inMinutes} min ${up.inSeconds % 60} s',
        'Memory in use: ${_rss()}',
        if (context != null && context.isNotEmpty) 'While: $context',
        'Error type: ${error.runtimeType}',
        'Error: ${message.length > 4000 ? '${message.substring(0, 4000)}… (cut)' : message}',
        '',
        'Stack (${frames.length} frames${frames.length > _frames ? ', first $_frames shown' : ''}):',
        if (frames.isEmpty) '  (none recorded)' else ...frames.take(_frames).map((l) => '  $l'),
        '',
        'Just before (oldest first):',
        if (_trail.isEmpty) '  (nothing noted)' else ..._trail.map((l) => '  $l'),
      ].join('\n'),
    );
  }

  void _prune() {
    final old = _files();
    for (final f in old.skip(keep)) {
      f.deleteSync();
    }
  }

  List<File> _files() {
    if (!dir.existsSync()) return const [];
    return dir.listSync().whereType<File>().where((f) => _when(f) != null).toList()
      ..sort((a, b) => _name(b).compareTo(_name(a)));
  }

  /// Every entry, newest first.
  List<CrashEntry> entries() => [
    for (final f in _files())
      if (_read(f) case final text?) CrashEntry(f, _when(f)!, _kind(f), text),
  ];

  /// Entries from earlier runs the user has not looked at yet.
  List<CrashEntry> unseen() {
    final seen = _seenFile.existsSync() ? _seenFile.readAsStringSync().trim() : '';
    return [
      for (final e in entries())
        if (_name(e.file).compareTo(seen) > 0 &&
            e.when.millisecondsSinceEpoch < started.millisecondsSinceEpoch)
          e,
    ];
  }

  /// Marks every entry so far as looked at.
  void markSeen() {
    final newest = _files().firstOrNull;
    if (newest == null) return;
    try {
      _seenFile.writeAsStringSync(_name(newest));
    } catch (_) {}
  }

  void clear() {
    for (final f in _files()) {
      f.deleteSync();
    }
    if (_seenFile.existsSync()) _seenFile.deleteSync();
  }

  /// The whole log as one text: the device first, then each entry, newest
  /// first. [limit] keeps only the newest few.
  String report({int? limit}) {
    final all = entries();
    final shown = limit == null ? all : all.take(limit).toList();
    return [
      'Vinyasa crash log, made ${DateTime.now().toUtc().toIso8601String()}',
      for (final f in facts.entries) '${f.key}: ${f.value}',
      'Entries: ${all.length}${shown.length < all.length ? ' (newest ${shown.length} shown)' : ''}',
      for (final (i, e) in shown.indexed) ...[
        '',
        '===== ${i + 1}. ${e.kind} at ${e.when.toIso8601String()} =====',
        e.text,
      ],
    ].join('\n');
  }

  File get _seenFile => File('${dir.path}/seen');

  static final _pattern = RegExp(r'^crash-(\d+)-([a-z]+)(?:-\d+)?\.txt$');
  static String _name(File f) => f.uri.pathSegments.last;
  static DateTime? _when(File f) => switch (_pattern.firstMatch(_name(f))?[1]) {
    final ms? => DateTime.fromMillisecondsSinceEpoch(int.parse(ms), isUtc: true),
    null => null,
  };
  static String _kind(File f) => _pattern.firstMatch(_name(f))![2]!;
  static String? _read(File f) {
    try {
      return f.readAsStringSync();
    } catch (_) {
      return null;
    }
  }
}

/// Takes out what would name the user or unlock their accounts: their home
/// folder (which holds the account name), e-mail addresses, and API keys or
/// tokens, which can ride in an address (Gemini's `?key=`) or a header.
String redact(String text, {Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  var out = text;
  for (final home in [env['HOME'], env['USERPROFILE']]) {
    if (home != null && home.length > 3) out = out.replaceAll(home, '~');
  }
  for (final user in [env['USER'], env['USERNAME']]) {
    if (user != null && user.length > 2) {
      out = out.replaceAll(RegExp('(?<=[/\\\\])${RegExp.escape(user)}(?=[/\\\\])'), '<user>');
    }
  }
  return out
      .replaceAll(RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'), '<email>')
      .replaceAllMapped(
        RegExp(r'([?&](?:key|api_key|apikey|access_token|token|client_id)=)[^&\s#]+', caseSensitive: false),
        (m) => '${m[1]}<hidden>',
      )
      .replaceAllMapped(
        RegExp(r'((?:Bearer|Client-ID)\s+|x-api-key[:=]\s*|x-goog-api-key[:=]\s*)\S+', caseSensitive: false),
        (m) => '${m[1]}<hidden>',
      )
      .replaceAll(RegExp(r'\b(?:sk-[\w-]{16,}|AIza[\w-]{30,})'), '<hidden>');
}

String _clock(DateTime t) => [t.hour, t.minute, t.second].map((n) => '$n'.padLeft(2, '0')).join(':');

String _rss() {
  try {
    return '${(ProcessInfo.currentRss / (1 << 20)).round()} MB';
  } catch (_) {
    return 'unknown';
  }
}
