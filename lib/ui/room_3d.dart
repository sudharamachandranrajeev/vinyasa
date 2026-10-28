import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/scene.dart';
import '../domain/space.dart';
import 'look.dart';
import 'plan_view.dart';

/// A room in 3D (domain/scene.dart), painted back to front on the canvas, so
/// it needs nothing from the system beyond Flutter itself. When
/// [interactive], dragging turns and tilts it, pinching or scrolling zooms,
/// two fingers or the right button move it, and buttons glide to set views.
/// [from], [morph], [highlight] and [pulse] work as on PlanView.
class Room3D extends StatefulWidget {
  const Room3D({
    super.key,
    required this.room,
    this.from,
    this.morph,
    this.highlight = const {},
    this.pulse,
    this.interactive = false,
  });

  final Room room;
  final Room? from;
  final Animation<double>? morph;
  final Set<String> highlight;
  final Animation<double>? pulse;
  final bool interactive;

  @override
  State<Room3D> createState() => _Room3DState();
}

class _Room3DState extends State<Room3D> with SingleTickerProviderStateMixin {
  late final AnimationController _fly =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..addListener(
        () => setState(() => _camera = _flyFrom.lerp(_flyTo, Curves.easeInOutCubic.transform(_fly.value))),
      );
  Camera? _camera;
  late Camera _flyFrom, _flyTo;
  Size _size = Size.zero;
  double _lastScale = 1;
  int _buttons = 0;

  /// The user turned or moved the view, so a change in the room's size
  /// leaves it be.
  bool _moved = false;

  double get _aspect => _size.height <= 0 ? 1 : _size.width / _size.height;
  double get _fit => Camera.fit(widget.room, _aspect);

  @override
  void didUpdateWidget(Room3D old) {
    super.didUpdateWidget(old);
    final a = old.room, b = widget.room;
    if (!_moved && (a.width != b.width || a.depth != b.depth || a.height != b.height)) _camera = null;
  }

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  void _go(Camera to) {
    _moved = true;
    if (Motion.reduced(context)) {
      setState(() => _camera = to);
      return;
    }
    _flyFrom = _camera ?? to;
    _flyTo = to;
    _fly.forward(from: 0);
  }

  void _set(Camera c) {
    _fly.stop();
    _moved = true;
    setState(() => _camera = c.copyWith(distance: c.distance.clamp(_fit * 0.12, _fit * 3)));
  }

  void _pan(Offset delta) {
    final c = _camera!;
    // Millimetres on the floor per pixel, at the target.
    final k = 2 * c.distance * math.tan(Camera.fov / 2) / math.max(1, _size.height);
    final right = V3(math.cos(c.yaw), -math.sin(c.yaw), 0);
    final away = V3(-math.sin(c.yaw), -math.cos(c.yaw), 0);
    final r = widget.room;
    final t = c.target - right * (delta.dx * k) + away * (delta.dy * k);
    _set(
      c.copyWith(target: V3(t.x.clamp(0, r.width.toDouble()), t.y.clamp(0, r.depth.toDouble()), c.target.z)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final vin = VinColors.of(context);
    final picture = LayoutBuilder(
      builder: (context, box) {
        _size = box.biggest;
        final camera = _camera ??= Camera.corner(widget.room, _aspect);
        return RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ScenePainter(
              room: widget.room,
              from: widget.from,
              morph: widget.morph,
              pulse: widget.pulse,
              camera: camera,
              highlight: widget.highlight,
              colours: _Colours(
                floor: Color.lerp(t.colorScheme.surfaceContainerLow, vin.furniture, 0.1)!,
                wall: Color.lerp(t.colorScheme.surfaceContainerHighest, vin.furniture, 0.05)!,
                cut: Color.lerp(t.colorScheme.onSurface, t.colorScheme.surface, 0.3)!,
                grid: vin.grid,
                glass: vin.zone,
                furniture: vin.furniture,
                fixed: Color.lerp(t.colorScheme.onSurfaceVariant, t.colorScheme.surface, 0.4)!,
                accent: vin.accent,
                alert: t.colorScheme.error,
                ink: t.colorScheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
    if (!widget.interactive) return picture;
    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            onPointerDown: (e) => _buttons = e.buttons,
            onPointerSignal: (e) {
              if (e is PointerScrollEvent && _camera != null) {
                _set(_camera!.copyWith(distance: _camera!.distance * math.exp(e.scrollDelta.dy * 0.0015)));
              }
            },
            child: GestureDetector(
              onScaleStart: (_) => _lastScale = 1,
              onScaleUpdate: (d) {
                final c = _camera;
                if (c == null) return;
                final panning =
                    d.pointerCount >= 2 ||
                    _buttons & (kSecondaryMouseButton | kMiddleMouseButton) != 0 ||
                    HardwareKeyboard.instance.isShiftPressed;
                if (!panning) {
                  _set(
                    c.copyWith(
                      yaw: c.yaw - d.focalPointDelta.dx * 0.008,
                      pitch: c.pitch + d.focalPointDelta.dy * 0.006,
                    ),
                  );
                  return;
                }
                if (d.scale != _lastScale && d.scale > 0) {
                  _set(c.copyWith(distance: c.distance * _lastScale / d.scale));
                  _lastScale = d.scale;
                }
                _pan(d.focalPointDelta);
              },
              child: picture,
            ),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'From a corner',
                    onPressed: () => _go(Camera.corner(widget.room, _aspect)),
                    icon: const Icon(Icons.view_in_ar_outlined),
                  ),
                  IconButton(
                    tooltip: 'From above',
                    onPressed: () => _go(Camera.above(widget.room, _aspect)),
                    icon: const Icon(Icons.crop_free),
                  ),
                  IconButton(
                    tooltip: 'From the door',
                    onPressed: () => _go(Camera.door(widget.room)),
                    icon: const Icon(Icons.door_front_door_outlined),
                  ),
                  Hint(
                    '3d.how',
                    child: Icon(Icons.info_outline, size: 18, color: t.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Whether the room pictures on Analysis and Arrange are in 3D.
class In3D extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final in3DProvider = NotifierProvider<In3D, bool>(In3D.new);

/// The room as a plan or in 3D, with a button to switch; the choice holds
/// for every such picture until changed. The 3D picture leaves out [layers].
class RoomPicture extends ConsumerWidget {
  const RoomPicture({
    super.key,
    required this.room,
    this.from,
    this.morph,
    this.layers = const {},
    this.highlight = const {},
    this.pulse,
  });

  final Room room;
  final Room? from;
  final Animation<double>? morph;
  final Set<PlanLayer> layers;
  final Set<String> highlight;
  final Animation<double>? pulse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final in3D = ref.watch(in3DProvider);
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: Motion.medium,
            child: in3D
                ? Room3D(
                    key: const ValueKey('3d'),
                    room: room,
                    from: from,
                    morph: morph,
                    highlight: highlight,
                    pulse: pulse,
                  )
                : PlanView(
                    key: const ValueKey('plan'),
                    room: room,
                    from: from,
                    morph: morph,
                    layers: layers,
                    highlight: highlight,
                    pulse: pulse,
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            tooltip: in3D ? 'Show the plan' : 'Show in 3D',
            onPressed: ref.read(in3DProvider.notifier).toggle,
            icon: Icon(in3D ? Icons.grid_view_outlined : Icons.view_in_ar_outlined),
          ),
        ),
      ],
    );
  }
}

class _Colours {
  const _Colours({
    required this.floor,
    required this.wall,
    required this.cut,
    required this.grid,
    required this.glass,
    required this.furniture,
    required this.fixed,
    required this.accent,
    required this.alert,
    required this.ink,
  });
  final Color floor, wall, cut, grid, glass, furniture, fixed, accent, alert, ink;
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.room,
    required this.from,
    required this.morph,
    required this.pulse,
    required this.camera,
    required this.highlight,
    required this.colours,
  }) : super(repaint: Listenable.merge([?morph, ?pulse]));

  final Room room;
  final Room? from;
  final Animation<double>? morph;
  final Animation<double>? pulse;
  final Camera camera;
  final Set<String> highlight;
  final _Colours colours;

  /// Light from high up over the top-left of the plan.
  static final _light = const V3(-0.35, -0.55, 0.76).unit;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.clipRect(Offset.zero & size);
    final t = morph == null ? 1.0 : Curves.easeInOutCubic.transform(morph!.value);
    final view = Projection(camera, size.width, size.height);
    final scene = buildScene(room, eye: view.eye, from: from, t: t);
    final fixed = {
      for (final i in room.items)
        if (i.fixed) i.id,
    };
    final glow = pulse?.value ?? 1;
    final fill = Paint()..isAntiAlias = true;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..isAntiAlias = true;
    var gridDrawn = false;
    for (final face in scene.drawOrder(view.eye)) {
      if (!gridDrawn && face.surface != Surface.floor) {
        _grid(canvas, view);
        gridDrawn = true;
      }
      final points = view.polygon(face.points);
      if (points == null) continue;
      final path = Path()..moveTo(points.first.$1, points.first.$2);
      for (final (x, y) in points.skip(1)) {
        path.lineTo(x, y);
      }
      path.close();
      final colour = _colour(face, fixed, glow);
      canvas.drawPath(path, fill..color = colour);
      if (face.surface != Surface.floor && face.surface != Surface.glass) {
        canvas.drawPath(path, edge..color = Color.lerp(colour, colours.ink, 0.3)!.withValues(alpha: 0.55));
      }
    }
    if (!gridDrawn) _grid(canvas, view);
  }

  /// A line every metre across the floor.
  void _grid(Canvas canvas, Projection view) {
    final line = Paint()
      ..color = colours.grid
      ..strokeWidth = 1;
    final w = room.width.toDouble(), d = room.depth.toDouble();
    void draw(V3 a, V3 b) {
      final p = view.point(a), q = view.point(b);
      if (p != null && q != null) canvas.drawLine(Offset(p.$1, p.$2), Offset(q.$1, q.$2), line);
    }

    for (var x = 1000.0; x < w; x += 1000) {
      draw(V3(x, 0, 0), V3(x, d, 0));
    }
    for (var y = 1000.0; y < d; y += 1000) {
      draw(V3(0, y, 0), V3(w, y, 0));
    }
  }

  Color _colour(Face face, Set<String> fixed, double glow) {
    final base = switch (face.surface) {
      Surface.floor => colours.floor,
      Surface.wall => colours.wall,
      Surface.cut => colours.cut,
      Surface.glass => colours.glass.withValues(alpha: 0.3),
      Surface.screen => const Color(0xFF1C2024),
      Surface.plant => Color.lerp(const Color(0xFF4E8A58), colours.furniture, 0.15)!,
      Surface.item => fixed.contains(face.item) ? colours.fixed : colours.furniture,
      Surface.soft => Color.lerp(
        fixed.contains(face.item) ? colours.fixed : colours.furniture,
        const Color(0xFFFFFFFF),
        0.45,
      )!,
    };
    if (face.surface == Surface.glass) return base;
    var c = base;
    if (face.item != null && highlight.contains(face.item)) {
      c = Color.lerp(c, colours.alert, 0.3 + 0.35 * glow)!;
    }
    // Lit from above, never darker than two thirds.
    final lit = 0.68 + 0.32 * math.max(0.0, face.normal.dot(_light));
    return Color.lerp(const Color(0xFF000000), c, lit)!.withValues(alpha: c.a);
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.room != room ||
      old.from != from ||
      old.camera != camera ||
      old.highlight != highlight ||
      old.colours != colours ||
      old.morph != morph ||
      old.pulse != pulse;
}
