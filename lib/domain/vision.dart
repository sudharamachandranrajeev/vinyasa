/// Reading a room from photos and video with the user's own AI.
///
/// The provider, model and key are the ones chosen in Ask AI's settings
/// (brahma_core). Core's asker sends text only, so this sends the images
/// itself, asks for one fixed JSON shape, and turns the answer into a draft
/// room the user checks before it replaces anything.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:brahma_core/brahma_core.dart';
import 'package:http/http.dart' as http;

import 'catalog.dart';
import 'space.dart';
import 'stored.dart';

/// A photo or a video ready to send: JPEG photos already resized and
/// stripped of their metadata.
class VisionMedia {
  const VisionMedia(this.bytes, this.mime);
  final Uint8List bytes;
  final String mime;

  bool get video => mime.startsWith('video/');
}

/// What the user knows for sure, so the AI's guesses can be scaled to it.
class KnownSize {
  const KnownSize({this.width, this.depth, this.type});

  /// Inside width (along the wall facing the camera in the first photo) and
  /// depth, in millimetres.
  final int? width, depth;
  final RoomType? type;
}

/// One thing the AI saw, with how sure it was (0 to 1).
class Seen<T> {
  const Seen(this.value, this.confidence);
  final T value;
  final double confidence;

  bool get unsure => confidence < 0.5;
}

/// The AI's room, scaled and clamped inside its walls.
class RoomDraft {
  const RoomDraft({required this.room, required this.openings, required this.items, this.notes = ''});

  /// The room with everything seen in it.
  final Room room;
  final List<Seen<Opening>> openings;
  final List<Seen<Item>> items;
  final String notes;
}

/// Providers that can look at images. The chat website and the command-line
/// ones cannot be sent pictures from here.
bool canSee(HelpAi via) =>
    via == HelpAi.gemini ||
    via == HelpAi.anthropic ||
    via == HelpAi.openai ||
    via == HelpAi.openrouter ||
    via == HelpAi.local;

/// Only Gemini takes a video as it is; the others get frames from it.
bool takesVideo(HelpAi via) => via == HelpAi.gemini;

/// Gemini's limit for a request sent in one piece (larger needs its File API).
const geminiInlineLimit = 20 * 1024 * 1024;

const _system = '''
You read rooms from photos and video and draw them as a floor plan.

The plan is a rectangle seen from above. Its top wall is the wall facing the
camera in the first image; right, bottom and left follow clockwise. x runs
along the top wall from its left end, y runs down the plan from the top wall,
in millimetres. An item's x and y are the top-left corner of its footprint.
rot is quarter turns clockwise: 0 means the item's back is towards the top
wall and its front faces the bottom wall; 1 faces left; 2 faces the top wall;
3 faces right. w is the item's width across its front, d its depth front to
back, h its height, all as if unturned.

An opening's offset is from the wall's start (the left end of the top and
bottom walls, the top end of the left and right walls) to its near edge.

Judge sizes from things of known size: doors are about 2000-2100 mm tall and
800-900 mm wide, worktops 900 mm high, beds and sofas come in standard sizes.
Use the measurements the user gives exactly. Only include what you can see;
give each thing a confidence from 0 to 1. Use the closest kind from the list;
"generic" when none fits, with a label saying what it is. Leave items out of
the plan rather than guess wildly.''';

/// The JSON shape asked for. No numeric limits: not every provider
/// accepts them, so the answer is clamped here instead.
Map<String, Object?> draftSchema() {
  Map<String, Object?> obj(Map<String, Object?> props) => {
    'type': 'object',
    'properties': props,
    'required': props.keys.toList(),
    'additionalProperties': false,
  };
  const integer = {'type': 'integer'}, number = {'type': 'number'}, string = {'type': 'string'};
  final wall = {
    'type': 'string',
    'enum': [for (final w in Wall.values) w.name],
  };
  return obj({
    'type': {
      'type': 'string',
      'enum': [for (final t in RoomType.values) t.name],
    },
    'width': integer,
    'depth': integer,
    'height': integer,
    'openings': {
      'type': 'array',
      'items': obj({
        'kind': {
          'type': 'string',
          'enum': [for (final k in OpeningKind.values) k.name],
        },
        'wall': wall,
        'offset': integer,
        'width': integer,
        'sill': integer,
        'confidence': number,
      }),
    },
    'items': {
      'type': 'array',
      'items': obj({
        'kind': {
          'type': 'string',
          'enum': ['generic', for (final k in catalog) k.id],
        },
        'label': string,
        'x': integer,
        'y': integer,
        'w': integer,
        'd': integer,
        'h': integer,
        'rot': {
          'type': 'integer',
          'enum': [0, 1, 2, 3],
        },
        'confidence': number,
      }),
    },
    'notes': string,
  });
}

String _ask(KnownSize known, int images, bool video) {
  final told = [
    if (known.type != null) 'It is a ${known.type!.label.toLowerCase()}.',
    if (known.width != null) 'The top wall is exactly ${known.width} mm long.',
    if (known.depth != null) 'The left wall is exactly ${known.depth} mm long.',
  ];
  return [
    video
        ? 'Here is a video of one room.'
        : 'Here ${images == 1 ? 'is a photo' : 'are $images photos and video frames'} of one room.',
    ...told,
    'Draw its floor plan as JSON in the given shape. In "notes", say in one or two '
        'sentences what you were unsure of.',
  ].join(' ');
}

/// One question about some pictures: the instructions, the request and the
/// JSON shape the answer must take.
class _Question {
  const _Question(this.system, this.prompt, this.schema, this.name);
  final String system, prompt;
  final Map<String, Object?> schema;
  final String name;
}

/// Sends the media to the chosen AI and reads back a draft. [key] is the
/// keychain's key for providers that need one.
class VisionAsker {
  VisionAsker(this.setup, {this.key, http.Client? client}) : _http = client ?? http.Client();
  final HelpAiSetup setup;
  final String? key;
  final http.Client _http;

  /// Reading pictures takes longer than a text answer.
  static const _timeout = Duration(minutes: 3);

  Future<RoomDraft> read(Room room, List<VisionMedia> media, KnownSize known) async {
    _check();
    if (media.isEmpty) throw AskAiException('Add a photo or a video of the room first.');
    final q = _Question(
      _system,
      _ask(known, media.length, media.any((m) => m.video)),
      draftSchema(),
      'room_plan',
    );
    return parseDraft(room, await _answer(media, q), known);
  }

  /// What the storage in [media] holds, for the user to check.
  Future<StorageDraft> readStorage(List<VisionMedia> media) async {
    _check();
    if (media.isEmpty) throw AskAiException('Add a photo of the open cupboard or shelves first.');
    final q = _Question(
      _storageSystem,
      'Here ${media.length == 1 ? 'is a photo' : 'are ${media.length} photos'} of storage. '
          'List what is kept in it as JSON in the given shape. In "notes", say in one sentence what you '
          'could not make out.',
      storageSchema(),
      'stored_things',
    );
    return parseStorage(await _answer(media, q));
  }

  void _check() {
    if (!canSee(setup.via)) {
      throw AskAiException(
        '${setup.via.label} cannot look at photos. Choose another way in Ask AI\'s settings.',
      );
    }
    if (setup.via.needsKey && (key ?? '').trim().isEmpty) {
      throw AskAiException('Add your ${setup.via.label} key first.');
    }
  }

  Future<String> _answer(List<VisionMedia> media, _Question q) => switch (setup.via) {
    HelpAi.gemini => _gemini(media, q),
    HelpAi.anthropic => _anthropic(media, q),
    _ => _openAi(media, q),
  };

  static const _geminiBase = 'https://generativelanguage.googleapis.com/v1beta';

  Future<String> _gemini(List<VisionMedia> media, _Question q) async {
    final j = await _send(
      http.Request('POST', Uri.parse('$_geminiBase/models/${setup.effectiveModel}:generateContent'))
        ..headers.addAll({'x-goog-api-key': (key ?? '').trim(), 'content-type': 'application/json'})
        ..body = jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': q.system},
            ],
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                for (final m in media)
                  {
                    'inline_data': {'mime_type': m.mime, 'data': base64Encode(m.bytes)},
                  },
                {'text': q.prompt},
              ],
            },
          ],
          'generationConfig': {'responseMimeType': 'application/json', 'responseJsonSchema': q.schema},
        }),
    );
    final parts = _list(_map(_map(_list(j['candidates']).firstOrNull)['content'])['parts']);
    return _text([for (final p in parts) _map(p)['text']]);
  }

  Future<String> _anthropic(List<VisionMedia> media, _Question q) async {
    final j = await _send(
      http.Request('POST', Uri.parse('https://api.anthropic.com/v1/messages'))
        ..headers.addAll({
          'x-api-key': (key ?? '').trim(),
          'anthropic-version': '2026-10-21',
          'anthropic-beta': 'server-side-fallback-2026-07-01',
          'content-type': 'application/json',
        })
        ..body = jsonEncode({
          'model': setup.effectiveModel,
          'max_tokens': 16000,
          'output_config': {
            'effort': 'medium',
            'format': {'type': 'json_schema', 'schema': q.schema},
          },
          'fallbacks': 'default',
          'system': q.system,
          'messages': [
            {
              'role': 'user',
              'content': [
                for (final m in media)
                  {
                    'type': 'image',
                    'source': {'type': 'base64', 'media_type': m.mime, 'data': base64Encode(m.bytes)},
                  },
                {'type': 'text', 'text': q.prompt},
              ],
            },
          ],
        }),
    );
    if (j['stop_reason'] == 'refusal') throw AskAiException('Claude declined to read these photos.');
    if (j['stop_reason'] == 'max_tokens') throw AskAiException('The answer was cut short. Try fewer photos.');
    return _text([
      for (final b in _list(j['content']))
        if (_map(b)['type'] == 'text') _map(b)['text'],
    ]);
  }

  Future<String> _openAi(List<VisionMedia> media, _Question q) async {
    if (setup.effectiveModel.isEmpty) throw AskAiException('Pick a model first.');
    final j = await _send(
      http.Request('POST', Uri.parse('${_base()}/chat/completions'))
        ..headers.addAll({
          if ((key ?? '').trim().isNotEmpty) 'authorization': 'Bearer ${key!.trim()}',
          'content-type': 'application/json',
        })
        ..body = jsonEncode({
          'model': setup.effectiveModel,
          'messages': [
            {'role': 'system', 'content': q.system},
            {
              'role': 'user',
              'content': [
                for (final m in media)
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:${m.mime};base64,${base64Encode(m.bytes)}'},
                  },
                {'type': 'text', 'text': q.prompt},
              ],
            },
          ],
          'response_format': {
            'type': 'json_schema',
            'json_schema': {'name': q.name, 'strict': true, 'schema': q.schema},
          },
        }),
    );
    return _text([_map(_map(_list(j['choices']).firstOrNull)['message'])['content']]);
  }

  String _base() {
    final base = setup.effectiveBase.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(base);
    if (uri == null || !uri.hasAuthority) throw AskAiException('That is not a server address.');
    if (uri.scheme == 'https' || (uri.scheme == 'http' && isLocalServerHost(uri.host))) return base;
    throw AskAiException('Use https:// for servers outside this computer and your home network.');
  }

  Future<Map<String, Object?>> _send(http.Request request) async {
    final http.Response r;
    try {
      r = await http.Response.fromStream(await _http.send(request).timeout(_timeout));
    } on TimeoutException {
      throw AskAiException('${setup.via.label} did not answer in time.');
    } on SocketException {
      throw AskAiException(
        setup.via == HelpAi.local
            ? 'Nothing answers at ${setup.effectiveBase}. Is the AI server running?'
            : 'No connection. Check the internet connection.',
      );
    } on http.ClientException catch (e) {
      throw AskAiException('No connection: ${e.message}');
    }
    final Object? j;
    try {
      j = jsonDecode(utf8.decode(r.bodyBytes));
    } on FormatException {
      throw AskAiException('${setup.via.label} answered ${r.statusCode} in an unexpected form.');
    }
    if (r.statusCode == 200 && j is Map) return j.cast<String, Object?>();
    final said = switch (j) {
      {'error': {'message': final String m}} => m,
      {'error': final String m} => m,
      _ => '',
    };
    throw AskAiException(switch (r.statusCode) {
      400 when said.toLowerCase().contains('image') => 'This model cannot read images. $said'.trim(),
      401 || 403 => 'The key was refused. Check it in Ask AI\'s settings. $said'.trim(),
      404 => 'Not found: check the model name. $said'.trim(),
      413 => 'The photos are too large to send together. Try fewer.',
      429 => 'The usage limit is reached for now. Try again later. $said'.trim(),
      _ => '${setup.via.label} answered ${r.statusCode}. $said'.trim(),
    });
  }

  String _text(List<Object?> parts) {
    final text = parts.whereType<String>().join().trim();
    if (text.isEmpty) throw AskAiException('${setup.via.label} gave an empty answer. Try again.');
    return text;
  }
}

List<Object?> _list(Object? v) => v is List ? v : const [];
Map<Object?, Object?> _map(Object? v) => v is Map ? v : const {};

int _int(Object? v, int fallback) => switch (v) {
  final int i => i,
  final num n when n.isFinite => n.round(),
  final String s => int.tryParse(s.trim()) ?? fallback,
  _ => fallback,
};

double _conf(Object? v) => switch (v) {
  final num n when n.isFinite => n.toDouble().clamp(0, 1),
  _ => 0.5,
};

/// Turns the AI's [text] into a draft of [room]: sizes kept to sane ranges,
/// stretched to the sizes the user [known], and everything inside the walls.
/// Throws an [AskAiException] when the answer is not a plan at all.
RoomDraft parseDraft(Room room, String text, KnownSize known) {
  Object? j;
  try {
    // Some local models wrap JSON in a code fence despite being asked not to.
    final start = text.indexOf('{'), end = text.lastIndexOf('}');
    j = start < 0 || end < start ? null : jsonDecode(text.substring(start, end + 1));
  } on FormatException {
    j = null;
  }
  if (j is! Map) throw AskAiException('The answer was not a floor plan. Try again or try another model.');

  final seenW = _int(j['width'], room.width).clamp(1000, 30000);
  final seenD = _int(j['depth'], room.depth).clamp(1000, 30000);
  final width = known.width ?? seenW, depth = known.depth ?? seenD;
  // The AI's room may not match the true size: stretch what it saw to fit.
  final sx = width / seenW, sy = depth / seenD;

  final openings = <Seen<Opening>>[];
  for (final (n, raw) in _list(j['openings']).indexed) {
    final o = _map(raw);
    final wall = Wall.values.where((w) => w.name == o['wall']).firstOrNull;
    if (wall == null) continue;
    final along = wall == Wall.top || wall == Wall.bottom ? sx : sy;
    final wallLen = wall == Wall.top || wall == Wall.bottom ? width : depth;
    final w = (_int(o['width'], 900) * along).round().clamp(400, wallLen);
    openings.add(
      Seen(
        Opening(
          id: 'seen-o$n',
          kind: OpeningKind.of('${o['kind']}'),
          wall: wall,
          offset: (_int(o['offset'], 0) * along).round().clamp(0, wallLen - w),
          width: w,
          sill: _int(o['sill'], 900).clamp(0, 2000),
        ),
        _conf(o['confidence']),
      ),
    );
  }

  final items = <Seen<Item>>[];
  for (final (n, raw) in _list(j['items']).indexed) {
    final i = _map(raw);
    final kind = itemKind('${i['kind']}');
    final rot = _int(i['rot'], 0) % 4;
    // Footprint axes swap when turned a quarter.
    final (fx, fy) = rot.isEven ? (sx, sy) : (sy, sx);
    final w = (_int(i['w'], kind.w) * fx).round().clamp(100, 6000);
    final d = (_int(i['d'], kind.d) * fy).round().clamp(100, 6000);
    final footW = rot.isEven ? w : d, footD = rot.isEven ? d : w;
    if (footW > width || footD > depth) continue;
    final label = '${i['label'] ?? ''}'.trim();
    items.add(
      Seen(
        Item(
          id: 'seen-i$n',
          kind: kind.id,
          x: (_int(i['x'], 0) * sx).round().clamp(0, width - footW),
          y: (_int(i['y'], 0) * sy).round().clamp(0, depth - footD),
          w: w,
          d: d,
          h: _int(i['h'], kind.h).clamp(10, 3500),
          rot: rot,
          label: label.toLowerCase() == kind.label.toLowerCase() ? '' : label,
          fixed: kind.builtIn,
        ),
        _conf(i['confidence']),
      ),
    );
  }

  final named = j['type'];
  final type = known.type ?? RoomType.values.where((t) => t.name == named).firstOrNull ?? room.type;
  return RoomDraft(
    room: room.copyWith(
      type: type,
      width: width,
      depth: depth,
      height: _int(j['height'], room.height).clamp(2000, 6000),
      openings: [for (final o in openings) o.value],
      items: [for (final i in items) i.value],
    ),
    openings: openings,
    items: items,
    notes: '${j['notes'] ?? ''}'.trim(),
  );
}

/// Scale for a photo of [w]×[h] so its long edge is at most [edge].
double fitScale(int w, int h, {int edge = 2576}) => math.min(1, edge / math.max(w, h));

const _storageSystem = '''
You list what is kept in storage (wardrobes, shelves, cabinets, drawers,
racks) from photos, so the owner can organise it. Group alike things into one
entry with a short plain name ("winter coats", "cookbooks", "spare bulbs")
rather than listing every single item; at most 40 entries. For each, pick the
closest sort from the list; guess how often it is used (daily, weekly or
rare) from what it is, and whether it is heavy (needs two hands, or more than
about 10 kg). Give each a confidence from 0 to 1. Only list what you can see.
Do not describe people or anything private such as documents' contents.''';

/// The JSON shape asked for when reading storage.
Map<String, Object?> storageSchema() {
  Map<String, Object?> obj(Map<String, Object?> props) => {
    'type': 'object',
    'properties': props,
    'required': props.keys.toList(),
    'additionalProperties': false,
  };
  return obj({
    'things': {
      'type': 'array',
      'items': obj({
        'name': {'type': 'string'},
        'stuff': {
          'type': 'string',
          'enum': [for (final s in Stuff.values) s.name],
        },
        'use': {
          'type': 'string',
          'enum': [for (final u in Use.values) u.name],
        },
        'heavy': {'type': 'boolean'},
        'confidence': {'type': 'number'},
      }),
    },
    'notes': {'type': 'string'},
  });
}

/// The things the AI saw in some storage.
class StorageDraft {
  const StorageDraft(this.things, {this.notes = ''});
  final List<Seen<Thing>> things;
  final String notes;
}

/// Turns the AI's [text] into things to check. Names are trimmed and kept
/// short; nameless entries are dropped. Throws an [AskAiException] when the
/// answer is not a list of things at all.
StorageDraft parseStorage(String text) {
  Object? j;
  try {
    final start = text.indexOf('{'), end = text.lastIndexOf('}');
    j = start < 0 || end < start ? null : jsonDecode(text.substring(start, end + 1));
  } on FormatException {
    j = null;
  }
  if (j is! Map || j['things'] is! List) {
    throw AskAiException('The answer was not a list of things. Try again or try another model.');
  }
  final things = <Seen<Thing>>[];
  for (final (n, raw) in _list(j['things']).take(40).indexed) {
    final t = _map(raw);
    var name = '${t['name'] ?? ''}'.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (name.isEmpty) continue;
    if (name.length > 60) name = '${name.substring(0, 59)}…';
    things.add(
      Seen(
        Thing(
          id: 'seen-t$n',
          name: name,
          stuff: Stuff.of('${t['stuff']}'),
          use: Use.of('${t['use']}'),
          heavy: t['heavy'] == true,
        ),
        _conf(t['confidence']),
      ),
    );
  }
  return StorageDraft(things, notes: '${j['notes'] ?? ''}'.trim());
}
