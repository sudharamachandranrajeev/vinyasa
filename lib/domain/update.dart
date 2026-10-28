import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'json.dart';

/// A failure updating, worded for the user.
class UpdateException implements Exception, UserFacingError {
  UpdateException(this.message);
  @override
  final String message;
  @override
  String toString() => message;
}

/// The list, not /releases/latest: that one skips pre-releases, and every
/// v0.* release is published as one.
final releasesUrl = Uri.parse(
  'https://api.github.com/repos/sudharamachandranrajeev/vinyasa/releases?per_page=20',
);
const releasesPage = 'https://github.com/sudharamachandranrajeev/vinyasa/releases';

/// The file each release publishes its checksums in (release.yml).
const checksumsName = 'SHA256SUMS.txt';

/// Android's installer is handed the APK through this (MainActivity.kt).
const _channel = MethodChannel('dev.brahma.vinyasa/update');

typedef Asset = ({String name, Uri url, int size});

/// A published release.
class Release {
  const Release({
    required this.version,
    required this.notes,
    required this.assets,
    this.page = '',
    this.prerelease = false,
  });

  factory Release.fromJson(Json j) => Release(
    version: str(j['tag_name']).replaceFirst(RegExp(r'^[vV]'), ''),
    notes: str(j['body']).trim(),
    page: str(j['html_url']),
    prerelease: j['prerelease'] == true,
    assets: {
      for (final a in objs(j['assets']))
        str(a['name']): (
          name: str(a['name']),
          url: Uri.parse(str(a['browser_download_url'])),
          size: intOf(a['size']) ?? 0,
        ),
    },
  );

  final String version;
  final String notes;
  final Map<String, Asset> assets;

  /// Its page on GitHub.
  final String page;
  final bool prerelease;

  /// The file that installs on [os], when the release has one.
  Asset? installerFor(String os) {
    final suffix = switch (os) {
      'android' => '-android.apk',
      'windows' => '-windows-x64-setup.exe',
      'linux' => '-linux-x64.tar.gz',
      _ => null,
    };
    if (suffix == null) return null;
    return assets.values.where((a) => a.name.endsWith(suffix)).firstOrNull;
  }
}

/// "v0.10.2-beta.1" → [0, 10, 2]; anything after a '-' is dropped and a part
/// that is not a number counts as 0.
List<int> versionParts(String version) => [
  for (final p in version.trim().replaceFirst(RegExp(r'^[vV]'), '').split('-').first.split('.'))
    int.tryParse(p) ?? 0,
];

/// Whether [candidate] is newer than [current], number by number.
bool isNewer(String candidate, String current) {
  final a = versionParts(candidate), b = versionParts(current);
  for (var i = 0; i < a.length || i < b.length; i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

/// The newest release in GitHub's list (pre-releases count, drafts do not).
Release? newestRelease(Object? list) {
  Release? best;
  for (final j in list is List ? list : const []) {
    if (obj(j)['draft'] == true) continue;
    final r = Release.fromJson(obj(j));
    if (r.version.isNotEmpty && (best == null || isNewer(r.version, best.version))) best = r;
  }
  return best;
}

/// The oldest version to go back to: it and every later one read this
/// version's database and room files. Raise it whenever the database schema
/// changes in a way an older build cannot open.
const oldestToGoBackTo = '0.1.0';

/// The releases in GitHub's [list] older than [current], back to
/// [oldestToGoBackTo], with a file for [os]; newest first, drafts left out.
List<Release> earlierReleases(Object? list, String current, String os) {
  final out =
      [
        for (final j in list is List ? list : const [])
          if (obj(j)['draft'] != true) Release.fromJson(obj(j)),
      ].where(
        (r) =>
            r.version.isNotEmpty &&
            isNewer(current, r.version) &&
            !isNewer(oldestToGoBackTo, r.version) &&
            r.installerFor(os) != null,
      );
  return out.toList()
    ..sort((a, b) => isNewer(a.version, b.version) ? -1 : (isNewer(b.version, a.version) ? 1 : 0));
}

/// SHA256SUMS.txt as file name → checksum (`sum  name` or `sum *name` lines).
Map<String, String> parseChecksums(String text) => {
  for (final line in const LineSplitter().convert(text))
    if (RegExp(r'^([0-9a-fA-F]{64})\s+\*?(\S.*)$').firstMatch(line.trim()) case final m?)
      m[2]!: m[1]!.toLowerCase(),
};

/// Finds, downloads, checks and installs a newer Vinyasa from the GitHub
/// releases the release workflow publishes. Nothing is installed unless it
/// matches the release's SHA256SUMS.txt.
class Updater {
  Updater(this._http, {required this.current, required this.os, required this.dir});

  final http.Client _http;

  /// This build's version.
  final String current;

  /// android, windows or linux.
  final String os;

  /// Where downloads go.
  final Directory dir;

  static const _agent = {'user-agent': 'Vinyasa-updater'};

  /// The newest release when it is newer than this build and has a file for
  /// this device, otherwise null. A version the user went back from
  /// ([skipped]) is not offered again; a newer one than that is.
  Future<Release?> check({String skipped = ''}) async {
    final r = newestRelease(await _list());
    if (r == null || !isNewer(r.version, current) || r.installerFor(os) == null) return null;
    if (skipped.isNotEmpty && !isNewer(r.version, skipped)) return null;
    return r;
  }

  /// The earlier versions this device can go back to, newest first.
  Future<List<Release>> earlier() async => earlierReleases(await _list(), current, os);

  /// Android will not install an older version over a newer one: going back
  /// there means uninstalling first.
  bool get canGoBackInPlace => os != 'android';

  Future<Object?> _list() async {
    final http.Response response;
    try {
      response = await _http
          .get(releasesUrl, headers: {..._agent, 'accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw UpdateException('GitHub did not answer in time.');
    } on SocketException {
      throw UpdateException('No connection to GitHub. Check the internet connection.');
    } on http.ClientException catch (e) {
      throw UpdateException('No connection to GitHub: ${e.message}');
    }
    if (response.statusCode != 200) {
      throw UpdateException('GitHub answered with error ${response.statusCode}.');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// Downloads this device's file of [release] and checks it against the
  /// published checksum. [onProgress] hears 0 to 1.
  Future<File> download(Release release, {void Function(double done)? onProgress}) async {
    final asset = release.installerFor(os);
    final sums = release.assets[checksumsName];
    if (asset == null) {
      throw UpdateException('Vinyasa ${release.version} has no file for this device.');
    }
    if (sums == null) {
      throw UpdateException(
        'Vinyasa ${release.version} publishes no checksums, so it is not installed from here.',
      );
    }
    final expected = parseChecksums(utf8.decode(await _get(sums.url)))[asset.name];
    if (expected == null) throw UpdateException('${asset.name} is missing from the release checksums.');

    await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}${asset.name}');
    final part = File('${file.path}.part');
    final response = await _send(asset.url);
    final total = response.contentLength ?? asset.size;
    final sink = part.openWrite();
    var got = 0;
    try {
      await for (final bytes in response.stream.timeout(const Duration(seconds: 60))) {
        sink.add(bytes);
        got += bytes.length;
        if (total > 0) onProgress?.call((got / total).clamp(0, 1));
      }
      await sink.close();
    } on Object catch (e) {
      await sink.close().catchError((_) {});
      await part.delete().catchError((_) => part);
      if (e is TimeoutException || e is SocketException || e is http.ClientException) {
        throw UpdateException('The download stopped. Try again.');
      }
      rethrow;
    }
    // Hashed as it is read, so a large file is never held in memory.
    final actual = (await sha256.bind(part.openRead()).first).toString();
    if (actual != expected) {
      await part.delete();
      throw UpdateException('The download did not match its checksum, so it was not installed.');
    }
    return part.rename(file.path);
  }

  /// Installs a checked [file]. Android opens its installer, Windows runs the
  /// setup (which closes this copy), and Linux runs the tarball's install.sh
  /// (which swaps the new version in for the next start). Returns what to
  /// tell the user.
  Future<String> install(File file) async {
    switch (os) {
      case 'android':
        await _channel.invokeMethod<bool>('installApk', {'path': file.path});
        return 'Confirm the update in Android\'s installer.';
      case 'windows':
        // The setup wizard closes this copy and offers to start the new one.
        await Process.start(file.path, ['/CURRENTUSER', '/NORESTART'], mode: ProcessStartMode.detached);
        exit(0);
      case 'linux':
        final into = Directory('${dir.path}/unpacked');
        if (await into.exists()) await into.delete(recursive: true);
        await into.create(recursive: true);
        await _run('tar', ['xzf', file.path, '-C', into.path]);
        final unpacked = into.listSync().whereType<Directory>().firstOrNull;
        if (unpacked == null) throw UpdateException('The download held no Vinyasa folder.');
        await _run('${unpacked.path}/install.sh', const []);
        await into.delete(recursive: true);
        return 'Installed. Restart Vinyasa to use the new version.';
    }
    throw UpdateException('Vinyasa cannot update itself on $os.');
  }

  /// Starts the installed Linux copy and closes this one.
  static Future<Never> restartLinux() async {
    final home = Platform.environment['HOME'] ?? '';
    await Process.start('$home/.local/lib/vinyasa/vinyasa', const [], mode: ProcessStartMode.detached);
    exit(0);
  }

  Future<void> _run(String exe, List<String> args) async {
    final r = await Process.run(exe, args);
    if (r.exitCode != 0) {
      throw UpdateException('Installing failed: ${'${r.stderr}'.trim().split('\n').last}');
    }
  }

  Future<List<int>> _get(Uri url) async {
    final r = await _send(url);
    return r.stream.toBytes().timeout(const Duration(seconds: 30));
  }

  Future<http.StreamedResponse> _send(Uri url) async {
    try {
      final r = await _http
          .send(http.Request('GET', url)..headers.addAll(_agent))
          .timeout(const Duration(seconds: 30));
      if (r.statusCode != 200) {
        r.stream.listen(null).cancel().ignore();
        throw UpdateException('The download answered with error ${r.statusCode}.');
      }
      return r;
    } on TimeoutException {
      throw UpdateException('The download did not start in time.');
    } on SocketException {
      throw UpdateException('No connection to GitHub. Check the internet connection.');
    } on http.ClientException catch (e) {
      throw UpdateException('No connection to GitHub: ${e.message}');
    }
  }
}
