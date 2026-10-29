import 'dart:convert';
import 'dart:typed_data';

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:vinyasa/domain/photo_prep.dart';
import 'package:vinyasa/domain/samples.dart';
import 'package:vinyasa/domain/space.dart';
import 'package:vinyasa/domain/stored.dart';
import 'package:vinyasa/domain/vision.dart';

/// A plan as an AI might draw it: the room a little off in size, one item
/// partly outside, one kind it cannot name.
String planJson({int width = 3000, int depth = 2500}) => jsonEncode({
  'type': 'bedroom',
  'width': width,
  'depth': depth,
  'height': 2700,
  'openings': [
    {'kind': 'door', 'wall': 'bottom', 'offset': 200, 'width': 900, 'sill': 0, 'confidence': 0.9},
    {'kind': 'window', 'wall': 'nowhere', 'offset': 0, 'width': 900, 'sill': 900, 'confidence': 0.9},
  ],
  'items': [
    {
      'kind': 'bed_double',
      'label': '',
      'x': 900,
      'y': 0,
      'w': 1400,
      'd': 2000,
      'h': 500,
      'rot': 0,
      'confidence': 0.95,
    },
    {
      'kind': 'wardrobe',
      'label': '',
      'x': 2900,
      'y': 2200,
      'w': 1000,
      'd': 600,
      'h': 2000,
      'rot': 1,
      'confidence': 0.4,
    },
    {
      'kind': 'piano',
      'label': 'Piano',
      'x': 0,
      'y': 1500,
      'w': 1500,
      'd': 600,
      'h': 1200,
      'rot': 0,
      'confidence': 0.7,
    },
  ],
  'notes': 'The left wall was hidden.',
});

final _photo = VisionMedia(Uint8List.fromList([1, 2, 3]), 'image/jpeg');

/// An AI's answer listing what a wardrobe holds.
String storageJson() => jsonEncode({
  'things': [
    {'name': '  Winter   coats ', 'stuff': 'clothes', 'use': 'rare', 'heavy': false, 'confidence': 0.9},
    {'name': 'Toolbox', 'stuff': 'tools', 'use': 'weekly', 'heavy': true, 'confidence': 0.3},
    {'name': '', 'stuff': 'misc', 'use': 'daily', 'heavy': false, 'confidence': 0.9},
  ],
  'notes': 'The top shelf was dark.',
});

void main() {
  final room = sampleBedroom('b');

  test('the plan is scaled to the known size and kept inside the walls', () {
    final d = parseDraft(room, planJson(), const KnownSize(width: 3600, depth: 3300));
    expect((d.room.width, d.room.depth), (3600, 3300));
    expect(d.openings, hasLength(1), reason: 'an opening on no wall is dropped');
    final bed = d.items.firstWhere((i) => i.value.kind == 'bed_double').value;
    expect(bed.x, 1080, reason: '900 × 3600/3000');
    expect(bed.w, 1680);
    for (final s in d.items) {
      final b = s.value.box;
      expect(b.x >= 0 && b.y >= 0 && b.right <= 3600 && b.bottom <= 3300, isTrue, reason: s.value.kind);
    }
    final piano = d.items.firstWhere((i) => i.value.name == 'Piano');
    expect(piano.value.kind, 'generic');
    expect(d.items.where((i) => i.unsure).map((i) => i.value.kind), ['wardrobe']);
    expect(d.notes, 'The left wall was hidden.');
    expect(d.room.name, room.name, reason: 'the room keeps its own details');
  });

  test('without a known size the AI’s own is used; fences and junk around JSON are fine', () {
    final d = parseDraft(room, 'Here you go:\n```json\n${planJson()}\n```', const KnownSize());
    expect((d.room.width, d.room.depth), (3000, 2500));
    expect(d.room.type, RoomType.bedroom);
    expect(() => parseDraft(room, 'I cannot see a room.', const KnownSize()), throwsA(isA<AskAiException>()));
  });

  test('photos are resized, turned upright and lose their metadata', () {
    final big = img.Image(width: 4000, height: 1000);
    big.exif.imageIfd['Make'] = img.IfdValueAscii('PhoneCo');
    big.exif.gpsIfd['GPSLatitudeRef'] = img.IfdValueAscii('N');
    final bytes = img.encodeJpg(big);
    expect(img.decodeJpg(bytes)!.exif.isEmpty, isFalse, reason: 'the test photo has EXIF');
    final clean = img.decodeJpg(cleanPhoto(bytes)!)!;
    expect((clean.width, clean.height), (2576, 644));
    expect(clean.exif.isEmpty, isTrue);
    expect(cleanPhoto(Uint8List.fromList([0, 1, 2])), isNull);
  });

  test('stored things are read, tidied and marked when unsure; junk is refused', () {
    final d = parseStorage('```json\n${storageJson()}\n```');
    expect(d.things, hasLength(2), reason: 'a nameless entry is dropped');
    final coats = d.things.first;
    expect(
      (coats.value.name, coats.value.stuff, coats.value.use, coats.unsure),
      ('Winter coats', Stuff.clothes, Use.rare, false),
    );
    expect((d.things.last.value.heavy, d.things.last.unsure), (true, true));
    expect(d.notes, 'The top shelf was dark.');
    final odd = parseStorage(
      jsonEncode({
        'things': [
          {'name': 'x' * 80, 'stuff': 'spaceships', 'use': 'hourly'},
        ],
      }),
    );
    expect(
      (odd.things.single.value.name.length, odd.things.single.value.stuff, odd.things.single.value.use),
      (60, Stuff.misc, Use.weekly),
    );
    expect(() => parseStorage('{"plan": []}'), throwsA(isA<AskAiException>()));
  });

  group('requests', () {
    late http.Request sent;
    VisionAsker asker(HelpAi via, Map<String, Object?> reply) => VisionAsker(
      HelpAiSetup(via: via, model: via == HelpAi.openai ? 'gpt-vision' : ''),
      key: 'k',
      client: MockClient((r) async {
        sent = r;
        return http.Response(jsonEncode(reply), 200);
      }),
    );
    Map<String, Object?> body() => jsonDecode(sent.body) as Map<String, Object?>;

    test('Anthropic: image blocks and a JSON schema', () async {
      final d = await asker(HelpAi.anthropic, {
        'stop_reason': 'end_turn',
        'content': [
          {'type': 'text', 'text': planJson()},
        ],
      }).read(room, [_photo], const KnownSize());
      expect(sent.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(sent.headers['x-api-key'], 'k');
      final b = body();
      expect(b['model'], 'claude-opus-5-5');
      final config = b['output_config'] as Map;
      expect((config['format'] as Map)['type'], 'json_schema');
      final content = ((b['messages'] as List).single as Map)['content'] as List;
      expect((content.first as Map)['type'], 'image');
      expect(((content.first as Map)['source'] as Map)['data'], base64Encode([1, 2, 3]));
      expect(d.items, hasLength(3));
    });

    test('storage: the same providers, asked for things in their own JSON shape', () async {
      final d = await asker(HelpAi.openai, {
        'choices': [
          {
            'message': {'content': storageJson()},
          },
        ],
      }).readStorage([_photo]);
      final b = body();
      expect(((b['response_format'] as Map)['json_schema'] as Map)['name'], 'stored_things');
      expect(((b['messages'] as List).first as Map)['content'], contains('storage'));
      expect(d.things.map((t) => t.value.name), ['Winter coats', 'Toolbox']);
    });

    test('Anthropic: a refusal is reported, not parsed', () async {
      final a = asker(HelpAi.anthropic, {'stop_reason': 'refusal', 'content': <Object>[]});
      expect(a.read(room, [_photo], const KnownSize()), throwsA(isA<AskAiException>()));
    });

    test('Gemini: inline data, video as it is, and a response schema', () async {
      final video = VisionMedia(Uint8List.fromList([9]), 'video/mp4');
      await asker(HelpAi.gemini, {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': planJson()},
              ],
            },
          },
        ],
      }).read(room, [_photo, video], const KnownSize());
      expect(sent.url.path, endsWith(':generateContent'));
      final b = body();
      final parts = (((b['contents'] as List).single as Map)['parts'] as List).cast<Map>();
      expect(
        [for (final p in parts.take(2)) (p['inline_data'] as Map)['mime_type']],
        ['image/jpeg', 'video/mp4'],
      );
      expect((b['generationConfig'] as Map)['responseMimeType'], 'application/json');
    });

    test('OpenAI-compatible: data URLs and a strict JSON schema', () async {
      await asker(HelpAi.openai, {
        'choices': [
          {
            'message': {'content': planJson()},
          },
        ],
      }).read(room, [_photo], const KnownSize());
      expect(sent.url.toString(), 'https://api.openai.com/v1/chat/completions');
      expect(sent.headers['authorization'], 'Bearer k');
      final b = body();
      final user = (b['messages'] as List).last as Map;
      final image = (user['content'] as List).first as Map;
      expect((image['image_url'] as Map)['url'], startsWith('data:image/jpeg;base64,'));
      expect((b['response_format'] as Map)['type'], 'json_schema');
    });

    test('providers that cannot see, and missing keys, are refused before sending', () async {
      final chat = VisionAsker(const HelpAiSetup(), client: MockClient((_) => throw StateError('sent')));
      expect(chat.read(room, [_photo], const KnownSize()), throwsA(isA<AskAiException>()));
      final noKey = VisionAsker(
        const HelpAiSetup(via: HelpAi.gemini),
        client: MockClient((_) => throw StateError('sent')),
      );
      expect(noKey.read(room, [_photo], const KnownSize()), throwsA(isA<AskAiException>()));
    });

    test('an error answer becomes a plain message', () async {
      final a = VisionAsker(
        const HelpAiSetup(via: HelpAi.anthropic),
        key: 'bad',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {'message': 'invalid x-api-key'},
            }),
            401,
          ),
        ),
      );
      expect(
        a.read(room, [_photo], const KnownSize()),
        throwsA(isA<AskAiException>().having((e) => '$e', 'message', contains('key was refused'))),
      );
    });
  });
}
