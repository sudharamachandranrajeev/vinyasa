import 'dart:convert';
import 'dart:io';

import 'package:brahma_core/brahma_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vinyasa/db/database.dart';
import 'package:vinyasa/domain/book.dart';
import 'package:vinyasa/domain/photos.dart';
import 'package:vinyasa/domain/samples.dart';
import 'package:vinyasa/domain/space.dart';

import 'support.dart';

/// An Openverse answer with one good photo and one on plain http.
String openverseJson({int pages = 3}) => jsonEncode({
  'result_count': 2,
  'page_count': pages,
  'results': [
    {
      'id': 'ov1',
      'title': 'Loft',
      'url': 'https://live.staticflickr.com/1/loft.jpg',
      'thumbnail': 'https://api.openverse.org/v1/images/ov1/thumb/',
      'foreign_landing_url': 'https://www.flickr.com/photos/ana/1',
      'creator': 'Ana',
      'creator_url': 'https://www.flickr.com/photos/ana',
      'license': 'by',
      'license_version': '2.0',
      'license_url': 'https://creativecommons.org/licenses/by/2.0/',
      'width': 1600,
      'height': 1200,
    },
    {'id': 'ov2', 'url': 'http://example.com/plain.jpg', 'creator': 'Bo'},
  ],
});

String unsplashJson() => jsonEncode({
  'total': 1,
  'total_pages': 1,
  'results': [
    {
      'id': 'u1',
      'color': '#a0b0c0',
      'width': 4000,
      'height': 3000,
      'alt_description': 'a calm bedroom',
      'urls': {
        'small': 'https://images.unsplash.com/u1?w=400',
        'regular': 'https://images.unsplash.com/u1?w=1080',
      },
      'links': {
        'html': 'https://unsplash.com/photos/u1',
        'download_location': 'https://api.unsplash.com/photos/u1/download?ixid=x',
      },
      'user': {
        'name': 'Cai',
        'links': {'html': 'https://unsplash.com/@cai'},
      },
    },
  ],
});

void main() {
  late List<http.Request> sent;
  http.Client answering(http.Response Function(http.Request r) reply) {
    sent = [];
    return MockClient((r) async {
      sent.add(r);
      return reply(r);
    });
  }

  test('Openverse: a guest search, credits and licences, only https, remembered', () async {
    final finder = PhotoFinder(answering((_) => http.Response(openverseJson(), 200)));
    final page = await finder.search(PhotoSource.openverse, 'japandi bedroom');
    final q = sent.single.url.queryParameters;
    expect(sent.single.url.host, 'api.openverse.org');
    expect((q['q'], q['category'], q['page_size'], q['page']), ('japandi bedroom', 'photograph', '20', '1'));
    expect(sent.single.headers.containsKey('Authorization'), isFalse);
    final p = page.photos.single;
    expect(p.credit, '“Loft” by Ana, CC BY 2.0');
    expect(p.aspect, 4 / 3);
    expect(page.more, isTrue);
    await finder.search(PhotoSource.openverse, 'Japandi bedroom ');
    expect(sent, hasLength(1), reason: 'the same search is not sent twice');
  });

  test('Openverse: out of guest searches says how to get more', () async {
    final finder = PhotoFinder(answering((_) => http.Response('{}', 429)));
    expect(
      finder.search(PhotoSource.openverse, 'loft'),
      throwsA(isA<PhotoSearchException>().having((e) => e.limited, 'limited', isTrue)),
    );
  });

  test('Openverse: a registered app gets a token and searches with it', () async {
    final client = answering(
      (r) => r.url.path.endsWith('/token/')
          ? http.Response(jsonEncode({'access_token': 'tok', 'expires_in': 43200}), 200)
          : http.Response(openverseJson(), 200),
    );
    final finder = PhotoFinder(
      client,
      openverse: const OpenverseApp(clientId: 'id', secret: 'shh', email: 'a@b.co'),
    );
    await finder.search(PhotoSource.openverse, 'loft');
    await finder.search(PhotoSource.openverse, 'loft', page: 2);
    expect(sent.map((r) => r.url.path), ['/v1/auth_tokens/token/', '/v1/images/', '/v1/images/']);
    expect(sent.first.bodyFields, {
      'grant_type': 'client_credentials',
      'client_id': 'id',
      'client_secret': 'shh',
    });
    expect(sent[1].headers['Authorization'], 'Bearer tok');
    expect(sent[1].url.queryParameters['page_size'], '30');
  });

  test('Openverse: registering sends the email and keeps what comes back', () async {
    final client = answering(
      (_) => http.Response(jsonEncode({'name': 'Vinyasa x', 'client_id': 'id', 'client_secret': 'shh'}), 201),
    );
    final app = await registerOpenverse(client, ' me@example.com ');
    final body = jsonDecode(sent.single.body) as Map;
    expect(body['email'], 'me@example.com');
    expect(body['name'], startsWith('Vinyasa '));
    expect(OpenverseApp.decode(app.encode())?.secret, 'shh');
    final refused = answering((_) => http.Response('{"email": ["Enter a valid email address."]}', 400));
    expect(registerOpenverse(refused, 'x'), throwsA(isA<PhotoSearchException>()));
  });

  test('Unsplash: the key, referral links, colour, and telling Unsplash a photo was kept', () async {
    final finder = PhotoFinder(
      answering(
        (r) =>
            r.url.path.endsWith('/download') ? http.Response('{}', 200) : http.Response(unsplashJson(), 200),
      ),
      unsplashKey: 'key',
    );
    expect(PhotoFinder(http.Client()).ready(PhotoSource.unsplash), isFalse);
    final p = (await finder.search(PhotoSource.unsplash, 'bedroom')).photos.single;
    expect(sent.single.headers['Authorization'], 'Client-ID key');
    expect(p.credit, 'Photo by Cai on Unsplash');
    expect(Uri.parse(p.page).queryParameters, {'utm_source': 'vinyasa', 'utm_medium': 'referral'});
    expect(Uri.parse(p.creatorUrl).queryParameters['utm_source'], 'vinyasa');
    expect(p.colour, 0xa0b0c0);
    await finder.kept(p);
    expect(sent.last.url.toString(), 'https://api.unsplash.com/photos/u1/download?ixid=x');
    expect(sent.last.headers['Authorization'], 'Client-ID key');
  });

  test('a stored photo keeps only https links', () {
    final p = IdeaPhoto.fromJson({
      'source': 'openverse',
      'id': 'x',
      'thumb': 'https://a.example/t.jpg',
      'image': 'https://a.example/i.jpg',
      'page': 'javascript:alert(1)',
      'creatorUrl': 'file:///etc/passwd',
    });
    expect((p.page, p.creatorUrl), ('', ''));
    expect(IdeaPhoto.fromJson(p.toJson()).image, 'https://a.example/i.jpg');
  });

  group('moodboard', () {
    late SpaceBook book;
    const photo = IdeaPhoto(
      source: PhotoSource.openverse,
      id: 'ov1',
      thumb: 'https://a.example/t.jpg',
      image: 'https://a.example/i.jpg',
      page: 'https://a.example/p',
      creator: 'Ana',
    );

    setUp(() async {
      book = SpaceBook(await Store.open(memoryDatabase()));
    });

    test('pins once per photo, go with the room, and travel in backups', () async {
      final space = await book.saveSpace(name: 'Home', kind: SpaceKind.home);
      await book.saveRoom(sampleBedroom('b'), space: space);
      await book.pin('b', photo);
      await book.pin('b', photo);
      expect(await book.pins('b'), hasLength(1));
      final backup = await book.exportAll();

      await book.unpin('b', photo);
      expect(await book.pins('b'), isEmpty);
      await book.pin('b', photo);
      expect(await book.pins('b'), hasLength(1), reason: 'pinning again brings it back');
      await book.removeRoom('b');
      await book.importAll(backup);
      expect(await book.room('b'), isNotNull, reason: 'a restore brings back a removed room');
      final back = await book.pins('b');
      expect(IdeaPhoto.fromJson(jsonDecode(back.single.json) as Map<String, Object?>).creator, 'Ana');

      await book.removeRoom('b');
      expect(await book.pins('b'), isEmpty);
    });

    test('a version 1 database gains the pins table', () async {
      final dir = await Directory.systemTemp.createTemp('vinyasa-migrate-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/v1.db');
      // Today's schema, then rolled back to how version 1 looked.
      final first = AppDatabase(NativeDatabase(file));
      await first.customSelect('SELECT 1').get();
      await first.customStatement('DROP TABLE vin_pins');
      await first.customStatement('PRAGMA user_version = 1');
      await first.close();

      final db = AppDatabase(NativeDatabase(file));
      final upgraded = SpaceBook(await Store.open(db));
      await upgraded.pin('r', photo);
      expect(await upgraded.pins('r'), hasLength(1));
      await db.close();
    });
  });
}
