import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/crash_log.dart';
import '../domain/update.dart';
import '../ui/common.dart';
import 'crash_log_page.dart';
import 'providers.dart';
import 'session.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => PageScaffold(
    title: 'Settings',
    children: [
      if (ref.watch(updaterProvider) case final updater?) _UpdateCard(updater),
      const _LookCard(),
      const _BackupCard(),
      const _ReportCard(),
      const AppLockCard(),
      const HintsCard(),
      const SyncCard(),
      const SecurityCard(
        network:
            'Vinyasa works out every score and arrangement on this device. It goes online only to look for '
            'updates on GitHub, to open idea searches you tap in the browser, and to talk to your sync server '
            'if you sign in. Photos and videos never leave this device.',
      ),
      const AboutCard(
        description:
            'Space organiser: plans for rooms at home, at work or in a shop, checked against rules from '
            'ergonomics, accessibility, design and Vaastu, and rearranged step by step.',
      ),
    ],
  );
}

/// Calm turns off the drifting backdrop; the system's reduce-motion setting
/// turns off every animation.
class _LookCard extends ConsumerWidget {
  const _LookCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = ref.watch(appearanceProvider).value;
    return SectionCard(
      title: 'Motion',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Calm background'),
            subtitle: const Text('Keeps the backdrop still. Page and plan animations stay.'),
            value: look?.calm ?? false,
            onChanged: (v) => chooseCalm(ref, v),
          ),
        ],
      ),
    );
  }
}

/// This version, and a newer one when GitHub has it, installed from here;
/// or an earlier one to go back to.
class _UpdateCard extends ConsumerWidget {
  const _UpdateCard(this.updater);
  final Updater updater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(updateProvider);
    final release = update.value;
    final onStart = ref.watch(updateOnStartProvider).value ?? true;
    final asked = ref.watch(updateAskedProvider);
    const name = 'Vinyasa';
    return SectionCard(
      title: 'Updates',
      trailing: TextButton(
        onPressed: update.isLoading
            ? null
            : () {
                ref.read(updateAskedProvider.notifier).ask();
                ref.invalidate(updateProvider);
              },
        child: Text(asked || onStart ? 'Check again' : 'Check now'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(switch (update) {
            AsyncLoading() => '$name ${updater.current}. Looking for a newer version…',
            AsyncError(:final error) => '$name ${updater.current}. Could not check: ${describeError(error)}',
            _ when release == null && !asked && !onStart => '$name ${updater.current}.',
            _ when release == null => '$name ${updater.current} is the newest version.',
            _ => '$name ${release.version} is out (this is ${updater.current}).',
          }),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Look for updates when the app starts'),
            subtitle: const Text('Asks before anything is downloaded.'),
            value: onStart,
            onChanged: (v) => ref.mutate((s) => s.book.setUpdateOnStart(v)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (release != null && !update.isLoading)
                FilledButton.icon(
                  onPressed: () => installUpdate(context, ref, updater, release),
                  icon: const Icon(Icons.system_update_outlined),
                  label: const Text('Update now'),
                ),
              OutlinedButton.icon(
                onPressed: () => goBack(context, ref, updater),
                icon: const Icon(Icons.history),
                label: const Text('Go back to an earlier version'),
              ),
              TextButton.icon(
                onPressed: () => openLink(context, releasesPage),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('All releases'),
              ),
            ],
          ),
          if (release != null && release.notes.isNotEmpty && !update.isLoading) ...[
            const SizedBox(height: 12),
            Text(release.notes, maxLines: 8, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

/// Asks whether to install [release] now; installs it on yes.
Future<void> offerUpdate(BuildContext context, WidgetRef ref, Updater updater, Release release) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Vinyasa ${release.version} is out'),
      scrollable: true,
      content: SizedBox(
        width: 480,
        child: Text(
          [
            'You have ${updater.current}. Update now? Your data stays as it is, and you can go back to this '
                'version from Settings › Updates.',
            if (release.notes.isNotEmpty) release.notes,
          ].join('\n\n'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Later')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update now')),
      ],
    ),
  );
  if (go == true && context.mounted) await installUpdate(context, ref, updater, release);
}

/// A copy of everything in the app's own folder, made before an update or
/// going back, so a version that reads the data differently loses nothing.
/// Returns the file.
Future<File> safetyBackup(AppSession session, String version) async {
  final dir = Directory('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}backups');
  await dir.create(recursive: true);
  final stamp = DateTime.now().toIso8601String().substring(0, 19).replaceAll(':', '-');
  final file = File('${dir.path}${Platform.pathSeparator}vinyasa-$version-$stamp.json');
  await file.writeAsString(await session.book.exportAll());
  // Keep the newest five.
  final old = dir.listSync().whereType<File>().toList()..sort((a, b) => b.path.compareTo(a.path));
  for (final f in old.skip(5)) {
    await f.delete().catchError((_) => f);
  }
  return file;
}

/// Backs up, downloads, checks and installs [release], then offers a
/// restart on Linux.
Future<void> installUpdate(BuildContext context, WidgetRef ref, Updater updater, Release release) async {
  final session = ref.read(sessionProvider);
  final said = await runTask(
    context,
    title: 'Installing ${release.version}',
    status: 'Backing up your data…',
    task: (progress) async {
      await safetyBackup(session, updater.current);
      final file = await updater.download(
        release,
        onProgress: (d) => progress('Downloading… ${(d * 100).round()}%'),
      );
      progress('Installing…');
      return updater.install(file);
    },
  );
  if (said == null || !context.mounted) return;
  if (updater.os != 'linux') return showMessage(context, said);
  final restart = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Vinyasa ${release.version} is installed'),
      content: const Text('Restart the app to use it. Your data stays as it is.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Later')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restart now')),
      ],
    ),
  );
  if (restart == true) await Updater.restartLinux();
}

/// Rollback: pick an earlier release and install it over this one. The
/// version left behind is not offered again at start (a newer one is).
/// Android cannot install an older version over a newer one, so there the
/// data is saved to a file of the user's choosing and the release page
/// opens: uninstall, install the older APK, and restore the file.
Future<void> goBack(BuildContext context, WidgetRef ref, Updater updater) async {
  final picked = await showDialog<Release>(context: context, builder: (_) => _EarlierDialog(updater));
  if (picked == null || !context.mounted) return;
  final session = ref.read(sessionProvider);
  if (!updater.canGoBackInPlace) {
    final text = await session.book.exportAll();
    if (!context.mounted) return;
    final saved = await saveBytes(
      context,
      'vinyasa-backup.json',
      Uint8List.fromList(utf8.encode(text)),
      mime: 'application/json',
    );
    if (!saved || !context.mounted) return;
    await ref.read(sessionProvider).book.skipUpdate(updater.current);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Going back to ${picked.version}'),
        content: const Text(
          'Android only installs an older version after the newer one is removed. Your data is saved in the '
          'file you chose. Next: uninstall Vinyasa, install the older APK from the release page, then restore '
          'the file from Settings › Backup.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openLink(context, picked.page.isEmpty ? releasesPage : picked.page);
            },
            child: const Text('Open the release page'),
          ),
        ],
      ),
    );
    return;
  }
  await session.book.skipUpdate(updater.current);
  if (context.mounted) await installUpdate(context, ref, updater, picked);
}

class _EarlierDialog extends ConsumerWidget {
  const _EarlierDialog(this.updater);
  final Updater updater;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(earlierReleasesProvider);
    return AlertDialog(
      title: const Text('Go back to an earlier version'),
      content: SizedBox(
        width: 480,
        child: AsyncView(
          list,
          onRetry: () => ref.invalidate(earlierReleasesProvider),
          builder: (releases) => releases.isEmpty
              ? Text(
                  'There is no earlier version of Vinyasa ${updater.current} for this device to go back to.',
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Your data is backed up first. This version will not be offered again when the app '
                      'starts; a newer one will.',
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final r in releases)
                            ListTile(
                              leading: const Icon(Icons.history),
                              title: Text('Vinyasa ${r.version}'),
                              subtitle: r.notes.isEmpty
                                  ? null
                                  : Text(r.notes, maxLines: 2, overflow: TextOverflow.ellipsis),
                              onTap: () => Navigator.pop(context, r),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
    );
  }
}

/// Every space, room and kept plan as one JSON file, and back.
class _BackupCard extends ConsumerWidget {
  const _BackupCard();

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final text = await ref.read(sessionProvider).book.exportAll();
    if (!context.mounted) return;
    final day = DateTime.now().toIso8601String().substring(0, 10);
    await saveBytes(
      context,
      'vinyasa-$day.json',
      Uint8List.fromList(utf8.encode(text)),
      mime: 'application/json',
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFiles(
      dialogTitle: 'A Vinyasa backup',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = picked.firstOrNull?.path;
    if (path == null || !context.mounted) return;
    try {
      final n = await ref.mutate((s) async => s.book.importAll(await File(path).readAsString()));
      if (context.mounted) showMessage(context, 'Restored $n ${n == 1 ? 'room' : 'rooms'}.');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => SectionCard(
    title: 'Backup',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Save every space, room and kept plan as one file, or restore from one: rooms with the same id are '
          'replaced, others added. Photos stay where they are.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => _export(context, ref),
              icon: const Icon(Icons.save_alt),
              label: const Text('Save a backup'),
            ),
            OutlinedButton.icon(
              onPressed: () => _import(context, ref),
              icon: const Icon(Icons.restore),
              label: const Text('Restore'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Problems and ideas',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'A problem report gathers what you write with details of this device and version that you can '
          'read and change, then opens a GitHub issue for you to send, or saves it as a file.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => showDialog<void>(context: context, builder: (_) => const BugReportDialog()),
              icon: const Icon(Icons.bug_report_outlined),
              label: const Text('Report a problem'),
            ),
            OutlinedButton.icon(
              onPressed: () => showReport(context, kind: ReportKind.feature),
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Suggest a feature'),
            ),
            if (CrashLog.current case final log?)
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CrashLogPage(log))),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Crash log'),
              ),
          ],
        ),
      ],
    ),
  );
}

/// The problem report: what happened, the steps, and the diagnostics the
/// user chooses to include, shown in full before anything leaves.
class BugReportDialog extends ConsumerStatefulWidget {
  const BugReportDialog({super.key, this.withCrashLog = false});

  /// Starts with the crash log ticked, even when this run has met no error.
  final bool withCrashLog;

  @override
  ConsumerState<BugReportDialog> createState() => _BugReportDialogState();
}

class _BugReportDialogState extends ConsumerState<BugReportDialog> {
  final _title = TextEditingController();
  final _details = TextEditingController();
  final _steps = TextEditingController();
  bool _device = true;
  bool _errors = AppErrors.recent.isNotEmpty;
  final _crashes = CrashLog.current?.entries().length ?? 0;
  late bool _crashLog = widget.withCrashLog || (CrashLog.current?.unseen().isNotEmpty ?? false);
  String? _room;
  String _version = '';
  String? _roomJson;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _version = p.version);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    for (final c in [_title, _details, _steps]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickRoom(String? id) async {
    setState(() {
      _room = id;
      _roomJson = null;
    });
    if (id == null) return;
    final row = await ref.read(sessionProvider).book.roomRow(id);
    if (mounted && _room == id) setState(() => _roomJson = row?.json);
  }

  String _diagnostics() {
    final look = ref.read(appearanceProvider).value;
    final versions = ref.read(versionsProvider).value ?? const [];
    final rooms = ref.read(allRoomsProvider).value ?? const [];
    return [
      '- Version: $_version',
      if (versions.length > 1) '- Versions run on this device: ${versions.join(' → ')}',
      '- System: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      '- Locale: ${Platform.localeName}',
      '- Theme: ${look?.theme.id ?? '?'}, ${look?.mode.name ?? '?'}${look?.calm == true ? ', calm' : ''}',
      '- Spaces: ${ref.read(spacesProvider).value?.length ?? 0}, rooms: ${rooms.length}',
    ].join('\n');
  }

  String get _body {
    final extra = [
      if (_device) ...['### Device', _diagnostics()],
      if (_roomJson != null) ...['', '### Room', '```json', _roomJson!, '```'],
      // The newest few: the whole log would not fit in an issue.
      if (_crashLog && _crashes > 0) ...[
        '',
        '### Crash log',
        '```text',
        CrashLog.current!.report(limit: 3),
        '```',
      ],
    ].join('\n');
    return reportBody(
      kind: ReportKind.bug,
      app: 'Vinyasa',
      version: _version,
      platform: Platform.operatingSystem,
      details: [
        _details.text.trim(),
        if (extra.isNotEmpty) ...['', extra],
      ].join('\n'),
      steps: _steps.text.trim(),
      error: _errors ? AppErrors.recent.join('\n\n') : null,
    );
  }

  bool get _ready => _title.text.trim().isNotEmpty && _details.text.trim().isNotEmpty;

  Future<void> _github() async {
    // The address has a length limit; the clipboard keeps the whole report.
    await Clipboard.setData(ClipboardData(text: _body));
    if (!mounted) return;
    await openLink(
      context,
      issueLink(
        repo: issueRepo(vinyasaIdentity),
        kind: ReportKind.bug,
        title: _title.text.trim(),
        body: _body,
      ).toString(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(allRoomsProvider).value ?? const [];
    final t = Theme.of(context);
    return AlertDialog(
      title: const Text('Report a problem'),
      scrollable: true,
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'In a few words',
                hintText: 'The plan does not save',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _details,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'What happened, and what you expected'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _steps,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Steps to see it (optional)',
                hintText: '1. Open…\n2. Tap…',
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include version, system and theme'),
              value: _device,
              onChanged: (v) => setState(() => _device = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Include the last ${AppErrors.recent.length} errors'),
              subtitle: AppErrors.recent.isEmpty ? const Text('None so far.') : null,
              value: _errors,
              onChanged: AppErrors.recent.isEmpty ? null : (v) => setState(() => _errors = v ?? false),
            ),
            if (_crashes > 0)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include the crash log'),
                subtitle: Text(
                  'The newest ${_crashes < 3 ? _crashes : 3} of $_crashes entries, with their full stack.',
                ),
                value: _crashLog,
                onChanged: (v) => setState(() => _crashLog = v ?? false),
              ),
            DropdownButtonFormField<String?>(
              initialValue: _room,
              decoration: const InputDecoration(labelText: 'Attach a room’s plan (optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                for (final r in rooms) DropdownMenuItem(value: r.id, child: Text(r.name)),
              ],
              onChanged: _pickRoom,
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Read the whole report'),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _body,
                    style: t.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Nothing is sent from the app. GitHub opens with the report filled in; you sign in and submit it '
              'there. The full text is also copied, in case it is too long for the address.',
              style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: _ready ? () => copyText(context, _body, what: 'Report copied.') : null,
          child: const Text('Copy'),
        ),
        TextButton(
          onPressed: _ready
              ? () => saveBytes(
                  context,
                  'vinyasa-report.md',
                  Uint8List.fromList(utf8.encode(_body)),
                  mime: 'text/markdown',
                )
              : null,
          child: const Text('Save'),
        ),
        FilledButton.icon(
          onPressed: _ready ? _github : null,
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Open on GitHub'),
        ),
      ],
    );
  }
}
