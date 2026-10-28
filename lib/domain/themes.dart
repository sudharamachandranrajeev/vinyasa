/// Themes: the built-in ones (themes/builtin.json) and the user's own, all
/// in one JSON format so a theme can be shared as a file or pasted text.
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show Color;

const themeFormat = 'vinyasa-theme';
const themesFormat = 'vinyasa-themes';

/// A theme as the format describes it.
class VinTheme {
  const VinTheme({
    required this.id,
    required this.name,
    required this.seed,
    required this.accent,
    required this.furniture,
    required this.zone,
    required this.lightBackground,
    required this.darkBackground,
    this.radius = 16,
    this.font = 'sans',
    this.builtIn = false,
  });

  final String id;
  final String name;

  /// The primary colour every other surface is tinted from.
  final Color seed;
  final Color accent;

  /// Plan colours: furniture, and zones (clearances, walkways, glass).
  final Color furniture;
  final Color zone;
  final Color lightBackground;
  final Color darkBackground;

  /// Corner radius of cards and buttons, 0 to 32.
  final double radius;

  /// sans | mono
  final String font;
  final bool builtIn;

  VinTheme copyWith({
    String? id,
    String? name,
    Color? seed,
    Color? accent,
    Color? furniture,
    Color? zone,
    Color? lightBackground,
    Color? darkBackground,
    double? radius,
    String? font,
    bool? builtIn,
  }) => VinTheme(
    id: id ?? this.id,
    name: name ?? this.name,
    seed: seed ?? this.seed,
    accent: accent ?? this.accent,
    furniture: furniture ?? this.furniture,
    zone: zone ?? this.zone,
    lightBackground: lightBackground ?? this.lightBackground,
    darkBackground: darkBackground ?? this.darkBackground,
    radius: radius ?? this.radius,
    font: font ?? this.font,
    builtIn: builtIn ?? this.builtIn,
  );

  Map<String, Object?> toJson() => {
    'format': themeFormat,
    'version': 1,
    'id': id,
    'name': name,
    'seed': hexOf(seed),
    'accent': hexOf(accent),
    'furniture': hexOf(furniture),
    'zone': hexOf(zone),
    'light': {'background': hexOf(lightBackground)},
    'dark': {'background': hexOf(darkBackground)},
    'radius': radius.round(),
    'font': font,
  };

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// Reads one theme; throws [FormatException] naming the first bad field.
  /// The 'format' field is only checked when [standalone] (a pasted or
  /// imported theme); entries of the built-in list have none.
  factory VinTheme.fromJson(Object? json, {bool standalone = true, bool builtIn = false}) {
    if (json is! Map) throw const FormatException('A theme is a JSON object.');
    if (standalone && json['format'] != themeFormat) {
      throw const FormatException('This is not a Vinyasa theme (format "vinyasa-theme").');
    }
    final id = json['id'];
    if (id is! String || !RegExp(r'^[a-z0-9-]{1,40}$').hasMatch(id)) {
      throw const FormatException('The id must be 1 to 40 lower-case letters, digits or dashes.');
    }
    final name = json['name'];
    if (name is! String || name.trim().isEmpty || name.length > 40) {
      throw const FormatException('The name must be 1 to 40 characters.');
    }
    Color colour(String field, Object? value) {
      final c = value is String ? parseHex(value) : null;
      if (c == null) throw FormatException('"$field" must be a colour like #1FB5E0.');
      return c;
    }

    final radius = json['radius'] ?? 16;
    if (radius is! num || radius < 0 || radius > 32) {
      throw const FormatException('"radius" must be a number from 0 to 32.');
    }
    final font = json['font'] ?? 'sans';
    if (font != 'sans' && font != 'mono') throw const FormatException('"font" must be "sans" or "mono".');
    return VinTheme(
      id: id,
      name: name.trim(),
      seed: colour('seed', json['seed']),
      accent: colour('accent', json['accent']),
      furniture: colour('furniture', json['furniture']),
      zone: colour('zone', json['zone']),
      lightBackground: colour('light.background', (json['light'] as Map?)?['background']),
      darkBackground: colour('dark.background', (json['dark'] as Map?)?['background']),
      radius: radius.toDouble(),
      font: font as String,
      builtIn: builtIn,
    );
  }

  static VinTheme decode(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      throw const FormatException('That is not valid JSON.');
    }
    return VinTheme.fromJson(json);
  }
}

/// The built-in list (themes/builtin.json).
List<VinTheme> parseBuiltInThemes(String text) {
  final root = jsonDecode(text);
  if (root is! Map || root['format'] != themesFormat) throw const FormatException('Not a theme list.');
  return [for (final t in root['themes'] as List) VinTheme.fromJson(t, standalone: false, builtIn: true)];
}

Color? parseHex(String text) {
  final m = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(text.trim());
  return m == null ? null : Color(0xFF000000 | int.parse(m[1]!, radix: 16));
}

String hexOf(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// A theme id from a name, kept clear of [taken] ("My theme" → my-theme,
/// my-theme-2, …).
String themeIdFor(String name, Set<String> taken) {
  var base = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  if (base.isEmpty) base = 'theme';
  if (base.length > 34) base = base.substring(0, 34);
  var id = base;
  for (var n = 2; taken.contains(id); n++) {
    id = '$base-$n';
  }
  return id;
}

/// A fresh theme around one random hue: the accent opposite it, furniture
/// and zone a third of the way round either side, and backgrounds barely
/// tinted with it, so any hue comes out readable.
VinTheme generateTheme(math.Random random, {required String id, required String name}) {
  final hue = random.nextDouble() * 360;
  Color hsl(double h, double s, double l) {
    final a = s * math.min(l, 1 - l);
    double f(double n) {
      final k = (n + h / 30) % 12;
      return l - a * math.max(-1, math.min(math.min(k - 3, 9 - k), 1));
    }

    int c(double v) => (v * 255).round().clamp(0, 255);
    return Color.fromARGB(255, c(f(0)), c(f(8)), c(f(4)));
  }

  return VinTheme(
    id: id,
    name: name,
    seed: hsl(hue, 0.65, 0.45),
    accent: hsl((hue + 180) % 360, 0.75, 0.55),
    furniture: hsl((hue + 330) % 360, 0.7, 0.52),
    zone: hsl((hue + 120) % 360, 0.75, 0.56),
    lightBackground: hsl(hue, 0.35, 0.965),
    darkBackground: hsl(hue, 0.35, 0.065),
    radius: (random.nextInt(5) * 6 + 4).toDouble(),
  );
}

/// WCAG contrast ratio between two colours, 1 to 21.
double contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final x = lum(a), y = lum(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}
