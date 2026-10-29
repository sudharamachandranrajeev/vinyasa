import 'dart:convert';

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/crash_log.dart';
import '../ui/common.dart';
import 'settings_page.dart';

/// Notes each page and dialog opened and closed in the crash log.
class CrashTrail extends NavigatorObserver {
  static String _name(Route<dynamic>? r) =>
      r?.settings.name ?? (r is PopupRoute ? 'a dialog' : r?.runtimeType.toString() ?? '?');

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      CrashLog.current?.note('opened ${_name(route)}');

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      CrashLog.current?.note('closed ${_name(route)}');

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      CrashLog.current?.note('replaced ${_name(oldRoute)} with ${_name(newRoute)}');
}

/// After a run that crashed: says so once, and leads to the log.
void offerCrashLog(BuildContext context) {
  final log = CrashLog.current;
  final missed = log?.unseen() ?? const [];
  if (log == null || missed.isEmpty) return;
  log.markSeen();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 10),
      content: Text(
        missed.length == 1
            ? 'Vinyasa met an error last time. The crash log has the details.'
            : 'Vinyasa met ${missed.length} errors since you last looked. The crash log has the details.',
      ),
      action: SnackBarAction(
        label: 'See',
        onPressed: () =>
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CrashLogPage(log))),
      ),
    ),
  );
}

/// The crash log, entry by entry, to read, copy, save, attach to a problem
/// report, or clear.
class CrashLogPage extends StatefulWidget {
  const CrashLogPage(this.log, {super.key});
  final CrashLog log;

  @override
  State<CrashLogPage> createState() => _CrashLogPageState();
}

class _CrashLogPageState extends State<CrashLogPage> {
  late var _entries = widget.log.entries();

  @override
  void initState() {
    super.initState();
    widget.log.markSeen();
  }

  Future<void> _clear() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear the crash log?'),
        content: Text('The ${_entries.length} entries are deleted from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (sure != true) return;
    widget.log.clear();
    setState(() => _entries = widget.log.entries());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final mono = t.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    final day = DateTime.now().toIso8601String().substring(0, 10);
    final some = _entries.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crash log'),
        actions: [
          IconButton(
            tooltip: 'Copy',
            onPressed: some ? () => copyText(context, widget.log.report(), what: 'Crash log copied.') : null,
            icon: const Icon(Icons.copy_outlined),
          ),
          IconButton(
            tooltip: 'Save as a file',
            onPressed: some
                ? () => saveBytes(
                    context,
                    'vinyasa-crash-log-$day.txt',
                    Uint8List.fromList(utf8.encode(widget.log.report())),
                    mime: 'text/plain',
                  )
                : null,
            icon: const Icon(Icons.save_alt),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: some ? _clear : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: !some
          ? const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'No crashes',
              message: 'When Vinyasa meets an error it cannot handle, the details are kept here.',
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom),
              children: [
                Readable(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Kept on this device only, newest first; your home folder and e-mail addresses are '
                        'left out. Attach it to a problem report so the cause can be found.',
                        style: t.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => const BugReportDialog(withCrashLog: true),
                          ),
                          icon: const Icon(Icons.bug_report_outlined),
                          label: const Text('Report a problem with it'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final e in _entries)
                        Card(
                          child: ExpansionTile(
                            leading: Icon(e.kind == 'flutter' ? Icons.warning_amber : Icons.error_outline),
                            title: Text(e.headline, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${_kinds[e.kind] ?? e.kind} · ${_local(e.when)}'),
                            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            children: [SelectableText(e.text, style: mono)],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

const _kinds = {
  'flutter': 'Screen error',
  'uncaught': 'Uncaught error',
  'startup': 'Failed to start',
  'native': 'Android crash',
};

String _local(DateTime t) {
  final l = t.toLocal();
  String two(int n) => '$n'.padLeft(2, '0');
  return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
}
