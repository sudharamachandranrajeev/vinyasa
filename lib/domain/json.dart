import 'dart:convert';

/// Lenient readers for JSON from GitHub and the platform channels:
/// a missing or wrongly typed field reads as empty, never as a crash.
typedef Json = Map<String, Object?>;

String str(Object? v) => switch (v) {
  String s => s.trim(),
  num n => '$n',
  _ => '',
};

int? intOf(Object? v) => switch (v) {
  num n when n.isFinite => n.round(),
  String s => num.tryParse(s.replaceAll(RegExp(r'[^0-9.\-]'), ''))?.round(),
  _ => null,
};

double? numOf(Object? v) => switch (v) {
  num n when n.isFinite => n.toDouble(),
  String s => double.tryParse(s),
  _ => null,
};

Json obj(Object? v) => v is Map ? v.cast<String, Object?>() : const {};

List<Json> objs(Object? v) => v is List ? [for (final e in v) obj(e)] : const [];

List<String> strs(Object? v) =>
    v is List ? [for (final e in v) str(e)].where((s) => s.isNotEmpty).toList() : const [];

/// Decodes a JSON object stored as text; empty or broken text reads as {}.
Json decodeObject(String text) {
  if (text.trim().isEmpty) return const {};
  try {
    return obj(jsonDecode(text));
  } on FormatException {
    return const {};
  }
}

List<Object?> decodeList(String text) {
  if (text.trim().isEmpty) return const [];
  try {
    final v = jsonDecode(text);
    return v is List ? v : const [];
  } on FormatException {
    return const [];
  }
}
