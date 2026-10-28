/// Ideas photos found inside the app: Openverse (openly licensed photos,
/// no setup needed) and Unsplash (with the user's own access key). Only
/// the search words go out; the photos load from the sources' own servers,
/// as their rules ask, and every photo keeps its credit and licence.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart';
import 'package:http/http.dart' as http;

import 'json.dart';

enum PhotoSource {
  openverse('Openverse'),
  unsplash('Unsplash');

  const PhotoSource(this.label);
  final String label;

  static PhotoSource of(String name) => values.where((v) => v.name == name).firstOrNull ?? openverse;
}

/// One photo and who made it.
class IdeaPhoto {
  const IdeaPhoto({
    required this.source,
    required this.id,
    required this.thumb,
    required this.image,
    required this.page,
    this.title = '',
    this.creator = '',
    this.creatorUrl = '',
    this.licence = '',
    this.licenceUrl = '',
    this.colour,
    this.width = 0,
    this.height = 0,
    this.downloadPing = '',
  });

  final PhotoSource source;
  final String id;

  /// A small picture for grids, a large one to look at, and the photo's own
  /// page at its source.
  final String thumb, image, page;
  final String title, creator, creatorUrl;

  /// "CC BY 2.0", "Unsplash License".
  final String licence, licenceUrl;

  /// The photo's average colour (0xRRGGBB), shown while it loads.
  final int? colour;
  final int width, height;

  /// Unsplash: the address to tell when a photo is kept.
  final String downloadPing;

  double get aspect => width > 0 && height > 0 ? width / height : 4 / 3;

  /// "Photo by Ana on Unsplash", "“Loft” by Ana, CC BY 2.0".
  String get credit {
    final by = creator.isEmpty ? 'unknown' : creator;
    return switch (source) {
      PhotoSource.unsplash => 'Photo by $by on Unsplash',
      PhotoSource.openverse => [
        if (title.isNotEmpty) '“$title” by $by' else 'By $by',
        if (licence.isNotEmpty) licence,
      ].join(', '),
    };
  }

  Json toJson() => {
    'source': source.name,
    'id': id,
    'thumb': thumb,
    'image': image,
    'page': page,
    if (title.isNotEmpty) 'title': title,
    if (creator.isNotEmpty) 'creator': creator,
    if (creatorUrl.isNotEmpty) 'creatorUrl': creatorUrl,
    if (licence.isNotEmpty) 'licence': licence,
    if (licenceUrl.isNotEmpty) 'licenceUrl': licenceUrl,
    'colour': ?colour,
    if (width > 0) 'width': width,
    if (height > 0) 'height': height,
  };

  factory IdeaPhoto.fromJson(Json j) => IdeaPhoto(
    source: PhotoSource.of(str(j['source'])),
    id: str(j['id']),
    thumb: _web(j['thumb']),
    image: _web(j['image']),
    page: _web(j['page']),
    title: str(j['title']),
    creator: str(j['creator']),
    creatorUrl: _web(j['creatorUrl']),
    licence: str(j['licence']),
    licenceUrl: _web(j['licenceUrl']),
    colour: intOf(j['colour']),
    width: intOf(j['width']) ?? 0,
    height: intOf(j['height']) ?? 0,
  );
}

/// Only https addresses are kept: a synced pin or a search answer must not
/// smuggle in another scheme to open.
String _web(Object? v) {
  final s = str(v);
  return Uri.tryParse(s)?.scheme == 'https' ? s : '';
}

class PhotoPage {
  const PhotoPage(this.photos, {required this.more});
  final List<IdeaPhoto> photos;
  final bool more;
}

class PhotoSearchException implements UserFacingError, Exception {
  const PhotoSearchException(this.message, {this.limited = false});
  @override
  final String message;

  /// Out of searches for now; registering (Openverse) would help.
  final bool limited;

  @override
  String toString() => message;
}

/// What lets Vinyasa use Openverse beyond its 5 searches an hour: the app
/// registered for this user, kept in the keychain.
class OpenverseApp {
  const OpenverseApp({required this.clientId, required this.secret, required this.email});
  final String clientId, secret, email;

  String encode() => jsonEncode({'id': clientId, 'secret': secret, 'email': email});

  static OpenverseApp? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      final j = decodeObject(text);
      final app = OpenverseApp(clientId: str(j['id']), secret: str(j['secret']), email: str(j['email']));
      return app.clientId.isEmpty || app.secret.isEmpty ? null : app;
    } on FormatException {
      return null;
    }
  }
}

/// Keychain entries for the photo sources, beside Ask AI's keys.
extension PhotoKeys on KeyVault {
  String _key(PhotoSource s) => '${app.id}.photos.${s.name}';

  /// Unsplash's access key, or Openverse's registered app (encoded).
  Future<String?> photoKey(PhotoSource s) => store.read(_key(s));

  Future<void> setPhotoKey(PhotoSource s, String value) =>
      value.isEmpty ? store.delete(_key(s)) : store.write(_key(s), value);
}

const _openverse = 'api.openverse.org';
const _unsplash = 'api.unsplash.com';

/// Unsplash asks for these on every link back to it.
const _utm = {'utm_source': 'vinyasa', 'utm_medium': 'referral'};

/// Adds Unsplash's referral tags to a link.
String unsplashLink(String url) {
  final u = Uri.tryParse(url);
  return u == null || url.isEmpty
      ? url
      : u.replace(queryParameters: {...u.queryParameters, ..._utm}).toString();
}

/// Searches the sources. Answers are remembered for the run, so going back
/// to a look costs no search.
class PhotoFinder {
  PhotoFinder(this.client, {this.unsplashKey, this.openverse});
  final http.Client client;
  final String? unsplashKey;
  final OpenverseApp? openverse;

  static const _timeout = Duration(seconds: 20);
  final _seen = <(PhotoSource, String, int), PhotoPage>{};
  String? _token;
  DateTime _tokenUntil = DateTime(0);

  bool ready(PhotoSource s) => s == PhotoSource.openverse || (unsplashKey ?? '').isNotEmpty;

  /// Page [page] (from 1) of photos for [query].
  Future<PhotoPage> search(PhotoSource source, String query, {int page = 1}) async {
    final q = query.trim();
    final key = (source, q.toLowerCase(), page);
    final known = _seen[key];
    if (known != null) return known;
    final found = switch (source) {
      PhotoSource.openverse => await _searchOpenverse(q, page),
      PhotoSource.unsplash => await _searchUnsplash(q, page),
    };
    return _seen[key] = found;
  }

  /// Headers for loading Openverse thumbnails within the registered limit.
  Map<String, String> imageHeaders(IdeaPhoto p) =>
      p.source == PhotoSource.openverse && _token != null ? {'Authorization': 'Bearer $_token'} : const {};

  Future<PhotoPage> _searchOpenverse(String q, int page) async {
    final token = await _openverseToken();
    final size = token == null ? 20 : 30;
    final uri = Uri.https(_openverse, '/v1/images/', {
      'q': q,
      'category': 'photograph',
      'page_size': '$size',
      'page': '$page',
    });
    final j = await _get(uri, PhotoSource.openverse, {
      'Authorization': ?(token == null ? null : 'Bearer $token'),
    });
    final photos = [
      for (final r in objs(j['results']))
        if (_web(r['url']).isNotEmpty)
          IdeaPhoto(
            source: PhotoSource.openverse,
            id: str(r['id']),
            thumb: _web(r['thumbnail']).isEmpty ? _web(r['url']) : _web(r['thumbnail']),
            image: _web(r['url']),
            page: _web(r['foreign_landing_url']),
            title: str(r['title']),
            creator: str(r['creator']),
            creatorUrl: _web(r['creator_url']),
            licence: _licence(str(r['license']), str(r['license_version'])),
            licenceUrl: _web(r['license_url']),
            width: intOf(r['width']) ?? 0,
            height: intOf(r['height']) ?? 0,
          ),
    ];
    return PhotoPage(photos, more: page < (intOf(j['page_count']) ?? 0));
  }

  Future<PhotoPage> _searchUnsplash(String q, int page) async {
    final key = unsplashKey ?? '';
    if (key.isEmpty) {
      throw const PhotoSearchException('Add your Unsplash access key under Photo sources first.');
    }
    final uri = Uri.https(_unsplash, '/search/photos', {
      'query': q,
      'per_page': '30',
      'page': '$page',
      'content_filter': 'high',
    });
    final j = await _get(uri, PhotoSource.unsplash, {
      'Authorization': 'Client-ID $key',
      'Accept-Version': 'v1',
    });
    final photos = [
      for (final r in objs(j['results']))
        if (_web(obj(r['urls'])['regular']).isNotEmpty)
          IdeaPhoto(
            source: PhotoSource.unsplash,
            id: str(r['id']),
            thumb: _web(obj(r['urls'])['small']),
            image: _web(obj(r['urls'])['regular']),
            page: unsplashLink(_web(obj(r['links'])['html'])),
            title: str(r['alt_description']),
            creator: str(obj(r['user'])['name']),
            creatorUrl: unsplashLink(_web(obj(obj(r['user'])['links'])['html'])),
            licence: 'Unsplash License',
            licenceUrl: 'https://unsplash.com/license',
            colour: _hex(str(r['color'])),
            width: intOf(r['width']) ?? 0,
            height: intOf(r['height']) ?? 0,
            downloadPing: _web(obj(r['links'])['download_location']),
          ),
    ];
    return PhotoPage(photos, more: page < (intOf(j['total_pages']) ?? 0));
  }

  /// Tells Unsplash a photo was kept, as its API rules ask. Failures are
  /// ignored: keeping the pin matters more.
  Future<void> kept(IdeaPhoto p) async {
    if (p.source != PhotoSource.unsplash || p.downloadPing.isEmpty || (unsplashKey ?? '').isEmpty) return;
    try {
      await client
          .get(
            Uri.parse(p.downloadPing),
            headers: {'Authorization': 'Client-ID $unsplashKey', 'Accept-Version': 'v1'},
          )
          .timeout(_timeout);
    } on Exception {
      // Not worth troubling the user about.
    }
  }

  Future<String?> _openverseToken() async {
    final app = openverse;
    if (app == null) return null;
    if (_token != null && DateTime.now().isBefore(_tokenUntil)) return _token;
    final res = await _send(
      () => client.post(
        Uri.https(_openverse, '/v1/auth_tokens/token/'),
        body: {'grant_type': 'client_credentials', 'client_id': app.clientId, 'client_secret': app.secret},
      ),
      PhotoSource.openverse,
    );
    if (res.statusCode != 200) {
      // Credentials no longer accepted: search as a guest rather than fail.
      return null;
    }
    final Json j;
    try {
      j = decodeObject(res.body);
    } on FormatException {
      return null;
    }
    final life = intOf(j['expires_in']) ?? 3600;
    _token = str(j['access_token']);
    _tokenUntil = DateTime.now().add(Duration(seconds: math.max(60, life - 60)));
    return _token!.isEmpty ? null : _token;
  }

  Future<Json> _get(Uri uri, PhotoSource source, Map<String, String> headers) async {
    final res = await _send(() => client.get(uri, headers: headers), source);
    if (res.statusCode == 200) {
      try {
        return decodeObject(res.body);
      } on FormatException {
        throw PhotoSearchException('${source.label} sent an answer Vinyasa cannot read.');
      }
    }
    throw switch ((source, res.statusCode)) {
      (PhotoSource.openverse, 429) => const PhotoSearchException(
        'Openverse allows 5 searches an hour without registering. Register Vinyasa with Openverse '
        'under Photo sources for many more, or use the search links meanwhile.',
        limited: true,
      ),
      (PhotoSource.unsplash, 401) => const PhotoSearchException(
        'Unsplash did not accept the access key. Check it under Photo sources.',
      ),
      (PhotoSource.unsplash, 403 || 429) => const PhotoSearchException(
        'Unsplash allows 50 searches an hour with a new key. Try again later.',
        limited: true,
      ),
      (_, final code) => PhotoSearchException('${source.label} could not search just now (error $code).'),
    };
  }

  Future<http.Response> _send(Future<http.Response> Function() call, PhotoSource source) async {
    try {
      return await call().timeout(_timeout);
    } on Exception {
      throw PhotoSearchException('${source.label} could not be reached. Check the connection.');
    }
  }
}

/// Registers Vinyasa with Openverse for this user. Openverse emails [email]
/// a link; until it is opened, searches stay at the guest limit.
Future<OpenverseApp> registerOpenverse(http.Client client, String email) async {
  // Names must be unique across Openverse.
  final tag = List.generate(8, (_) => math.Random.secure().nextInt(16).toRadixString(16)).join();
  final http.Response res;
  try {
    res = await client
        .post(
          Uri.https(_openverse, '/v1/auth_tokens/register/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': 'Vinyasa $tag',
            'description':
                'Vinyasa, an open-source room organiser, shows interior ideas photos to one person '
                'from the searches they make in the app.',
            'email': email.trim(),
          }),
        )
        .timeout(const Duration(seconds: 20));
  } on Exception {
    throw const PhotoSearchException('Openverse could not be reached. Check the connection.');
  }
  if (res.statusCode != 201 && res.statusCode != 200) {
    final why = res.statusCode == 400 && res.body.contains('email') ? ' Check the email address.' : '';
    throw PhotoSearchException('Openverse did not register Vinyasa (error ${res.statusCode}).$why');
  }
  final Json j;
  try {
    j = decodeObject(res.body);
  } on FormatException {
    throw const PhotoSearchException('Openverse sent an answer Vinyasa cannot read.');
  }
  final app = OpenverseApp(
    clientId: str(j['client_id']),
    secret: str(j['client_secret']),
    email: email.trim(),
  );
  if (app.clientId.isEmpty || app.secret.isEmpty) {
    throw const PhotoSearchException('Openverse sent an answer Vinyasa cannot read.');
  }
  return app;
}

String _licence(String code, String version) {
  if (code.isEmpty) return '';
  final name = switch (code) {
    'cc0' => 'CC0',
    'pdm' => 'Public domain',
    _ => 'CC ${code.toUpperCase()}',
  };
  return code == 'pdm' || version.isEmpty ? name : '$name $version';
}

int? _hex(String s) {
  final v = int.tryParse(s.replaceFirst('#', ''), radix: 16);
  return v == null || s.length != 7 ? null : v;
}
