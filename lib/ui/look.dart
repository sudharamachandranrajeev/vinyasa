import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';

import '../domain/themes.dart';

// Vinyasa's look: an architect's drawing table. Every colour comes from the
// chosen theme (domain/themes.dart): its background, a seed that tints the
// surfaces, an accent, a colour for furniture on the plans and one for the
// zones laid over them (clearances, Vaastu ninths). Behind the pages a faint
// nine-square mandala drifts with a slow glow of the seed colour. Motion
// stops when the system asks for reduced motion or the user picks Calm.

const headingFont = 'PlusJakartaSans';
const bodyFont = 'Inter';
const _monoFallback = ['monospace', 'Consolas', 'DejaVu Sans Mono', 'Menlo'];

/// The theme's own colours, beside the Material scheme.
class VinColors extends ThemeExtension<VinColors> {
  const VinColors({
    required this.furniture,
    required this.zone,
    required this.accent,
    required this.grid,
    required this.line,
    required this.radius,
  });

  final Color furniture;
  final Color zone;
  final Color accent;

  /// Plan grid lines and the mandala behind the pages.
  final Color grid;

  /// Hairline borders.
  final Color line;
  final double radius;

  static VinColors of(BuildContext context) => Theme.of(context).extension<VinColors>()!;

  @override
  VinColors copyWith({
    Color? furniture,
    Color? zone,
    Color? accent,
    Color? grid,
    Color? line,
    double? radius,
  }) => VinColors(
    furniture: furniture ?? this.furniture,
    zone: zone ?? this.zone,
    accent: accent ?? this.accent,
    grid: grid ?? this.grid,
    line: line ?? this.line,
    radius: radius ?? this.radius,
  );

  @override
  VinColors lerp(VinColors? other, double t) => other == null
      ? this
      : VinColors(
          furniture: Color.lerp(furniture, other.furniture, t)!,
          zone: Color.lerp(zone, other.zone, t)!,
          accent: Color.lerp(accent, other.accent, t)!,
          grid: Color.lerp(grid, other.grid, t)!,
          line: Color.lerp(line, other.line, t)!,
          radius: radius + (other.radius - radius) * t,
        );
}

Color _mix(Color base, Color over, double amount) => Color.alphaBlend(over.withValues(alpha: amount), base);

ThemeData vinTheme(VinTheme t, Brightness b) {
  final dark = b == Brightness.dark;
  final base = buildTheme(b, seed: t.seed, accent: t.accent);
  final bg = dark ? t.darkBackground : t.lightBackground;
  final ink = dark ? const Color(0xFFE8EEF0) : const Color(0xFF14191B);
  final scheme = base.colorScheme.copyWith(
    surface: bg,
    surfaceContainerLowest: _mix(bg, t.seed, 0.02),
    surfaceContainerLow: _mix(bg, t.seed, dark ? 0.06 : 0.035),
    surfaceContainer: _mix(bg, t.seed, dark ? 0.09 : 0.06),
    surfaceContainerHigh: _mix(bg, t.seed, dark ? 0.12 : 0.08),
    surfaceContainerHighest: _mix(bg, t.seed, dark ? 0.16 : 0.11),
    onSurface: ink,
    onSurfaceVariant: _mix(ink, bg, 0.38),
    tertiary: t.accent,
  );
  final line = _mix(bg, ink, dark ? 0.12 : 0.1);
  final mono = t.font == 'mono';
  final text = base.textTheme.apply(
    fontFamily: mono ? 'monospace' : bodyFont,
    fontFamilyFallback: mono ? _monoFallback : null,
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  TextStyle? heading(TextStyle? s, FontWeight w, [double spacing = -0.3]) => mono
      ? s?.copyWith(fontWeight: w)
      : s?.copyWith(fontFamily: headingFont, fontWeight: w, letterSpacing: spacing);
  final type = text.copyWith(
    displaySmall: heading(text.displaySmall, FontWeight.w700, -0.8),
    headlineMedium: heading(text.headlineMedium, FontWeight.w700, -0.6),
    headlineSmall: heading(text.headlineSmall, FontWeight.w700),
    titleLarge: heading(text.titleLarge, FontWeight.w700),
    titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  );
  final radius = BorderRadius.circular(t.radius);
  final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(math.min(t.radius, 14)));
  return base.copyWith(
    colorScheme: scheme,
    textTheme: type,
    listTileTheme: ListTileThemeData(leadingAndTrailingTextStyle: type.bodyLarge),
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: type.headlineSmall?.copyWith(fontSize: 22),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow.withValues(alpha: dark ? 0.82 : 0.9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: line),
      ),
    ),
    dividerTheme: DividerThemeData(color: line, space: 1),
    chipTheme: base.chipTheme.copyWith(
      shape: controlShape,
      side: BorderSide(color: line),
      backgroundColor: Colors.transparent,
      selectedColor: t.seed.withValues(alpha: 0.2),
      checkmarkColor: dark ? Colors.white : t.seed,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: controlShape,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: controlShape,
        side: BorderSide(color: line),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: controlShape)),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: controlShape,
        side: BorderSide(color: line),
        selectedBackgroundColor: t.seed.withValues(alpha: 0.22),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: controlShape,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: scheme.surfaceContainer,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(math.min(t.radius, 14))),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(math.min(t.radius, 14)),
        borderSide: BorderSide(color: line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _mix(dark ? bg : const Color(0xFF12181A), t.seed, 0.14),
      surfaceTintColor: Colors.transparent,
      indicatorColor: t.seed,
      indicatorShape: controlShape,
      elevation: 0,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Colors.white : Colors.white70),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: t.seed.withValues(alpha: 0.22),
      indicatorShape: controlShape,
      selectedIconTheme: IconThemeData(color: dark ? Colors.white : t.seed),
      selectedLabelTextStyle: type.labelLarge?.copyWith(color: scheme.onSurface),
      unselectedLabelTextStyle: type.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    extensions: [
      VinColors(
        furniture: t.furniture,
        zone: t.zone,
        accent: t.accent,
        grid: _mix(bg, t.seed, dark ? 0.16 : 0.12),
        line: line,
        radius: t.radius,
      ),
    ],
  );
}

/// Whether ambient motion runs: not when the system asks for less motion,
/// nor when the user chose Calm (Settings › Look). Main sets it.
final ambientMotion = ValueNotifier(true);

/// The canvas behind every page: the background, a glow of the seed colour
/// drifting slowly across it, and a faint Vaastu mandala of nine squares.
class Backdrop extends StatefulWidget {
  const Backdrop({super.key, required this.child});
  final Widget child;

  @override
  State<Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop> with SingleTickerProviderStateMixin {
  late final _drift = AnimationController(vsync: this, duration: const Duration(seconds: 40));

  @override
  void initState() {
    super.initState();
    ambientMotion.addListener(_update);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  void _update() {
    final run = ambientMotion.value && !Motion.reduced(context);
    if (run && !_drift.isAnimating) {
      _drift.repeat();
    } else if (!run && _drift.isAnimating) {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    ambientMotion.removeListener(_update);
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vin = VinColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.surface),
      child: CustomPaint(
        painter: _Mandala(_drift, scheme.primary, vin.accent, vin.grid),
        child: widget.child,
      ),
    );
  }
}

class _Mandala extends CustomPainter {
  _Mandala(this.t, this.glow, this.accent, this.grid) : super(repaint: t);
  final Animation<double> t;
  final Color glow, accent, grid;

  @override
  void paint(Canvas canvas, Size size) {
    final a = t.value * math.pi * 2;
    // Two glows on slow orbits.
    for (final (colour, phase, alpha) in [(glow, 0.0, 0.13), (accent, math.pi, 0.07)]) {
      final centre = Offset(
        size.width * (0.75 + 0.18 * math.cos(a + phase)),
        size.height * (0.12 + 0.1 * math.sin(a + phase)),
      );
      final reach = size.longestSide * 0.8;
      canvas.drawCircle(
        centre,
        reach,
        Paint()
          ..shader = RadialGradient(
            colors: [
              colour.withValues(alpha: alpha),
              colour.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: centre, radius: reach)),
      );
    }
    // The mandala: a square of nine, a circle inscribed, in one corner.
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = grid.withValues(alpha: 0.5);
    final side = math.min(size.shortestSide * 0.9, 640.0);
    final origin = Offset(size.width - side * 0.62, -side * 0.3);
    canvas.save();
    canvas.translate(origin.dx + side / 2, origin.dy + side / 2);
    canvas.rotate(a / 16);
    final half = side / 2;
    for (var k = 0; k <= 3; k++) {
      final p = -half + k * side / 3;
      canvas.drawLine(Offset(p, -half), Offset(p, half), line);
      canvas.drawLine(Offset(-half, p), Offset(half, p), line);
    }
    canvas.drawCircle(Offset.zero, half, line);
    canvas.drawCircle(Offset.zero, half / 3, line);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Mandala old) => old.glow != glow || old.grid != grid || old.accent != accent;
}

/// The colour for a 0–100 score: green from 80, amber from 60, red below.
Color scoreColor(int score) => score >= 80
    ? StatusColors.good
    : score >= 60
    ? StatusColors.warning
    : score >= 40
    ? StatusColors.serious
    : StatusColors.critical;

/// A 0–100 score as a ring that fills up to it, the number in the middle and
/// a label under it. A negative score (not measured yet) shows a dash.
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.label, this.size = 64});
  final int score;
  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final track = VinColors.of(context).grid;
    final ring = TweenAnimationBuilder<double>(
      tween: Tween(end: score < 0 ? 0 : score / 100),
      duration: Motion.reduced(context) ? Duration.zero : const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (context, v, _) => CustomPaint(
        painter: _Ring(v.clamp(0, 1), score < 0 ? track : scoreColor((v * 100).round()), track),
        child: Center(
          child: Text(
            score < 0 ? '–' : '${(v * 100).round().clamp(0, 100)}',
            style: (size >= 56 ? t.textTheme.titleMedium : t.textTheme.labelMedium)
                ?.merge(tabular)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
    return Semantics(
      label: '${label ?? 'Score'} ${score < 0 ? 'not measured' : '$score out of 100'}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(dimension: size, child: ring),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label!, style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _Ring extends CustomPainter {
  _Ring(this.value, this.colour, this.track);
  final double value;
  final Color colour, track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.max(4.0, size.width * 0.1);
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    if (value > 0) canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, paint..color = colour);
  }

  @override
  bool shouldRepaint(_Ring old) => old.value != value || old.colour != colour || old.track != track;
}

/// A thin bar for a share of something (a plan, a list row).
class Meter extends StatelessWidget {
  const Meter({super.key, required this.value, this.color, this.height = 8});
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final vin = VinColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: vin.grid,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// A small coloured dot and label for chart legends.
class LegendDot extends StatelessWidget {
  const LegendDot(this.color, this.label, {super.key});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}
