import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../domain/catalog.dart';
import '../domain/grid.dart';
import '../domain/rules.dart' show Limits, mm;
import '../domain/space.dart';
import 'look.dart';

/// What to lay over the plan.
enum PlanLayer {
  vaastu('Vaastu grid', Icons.grid_3x3),
  clearance('Clearances', Icons.select_all),
  path('Walkways', Icons.directions_walk);

  const PlanLayer(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Maps between plan millimetres and the widget's pixels.
class PlanFit {
  factory PlanFit(Size size, Room room, {double pad = 28}) {
    final scale = math.max(
      0.0001,
      math.min((size.width - 2 * pad) / room.width, (size.height - 2 * pad) / room.depth),
    );
    return PlanFit._(
      scale,
      Offset((size.width - room.width * scale) / 2, (size.height - room.depth * scale) / 2),
    );
  }
  const PlanFit._(this.scale, this._origin);

  final double scale;
  final Offset _origin;

  Offset toPx(double x, double y) => _origin + Offset(x * scale, y * scale);
  Rect rectPx(Box b) =>
      Rect.fromLTWH(_origin.dx + b.x * scale, _origin.dy + b.y * scale, b.w * scale, b.d * scale);
  Offset toMm(Offset px) => (px - _origin) / scale;
}

/// A room drawn from above. When [from] is given, items glide from where
/// they stand there to where they stand in [room] as [morph] runs 0 → 1.
class PlanView extends StatelessWidget {
  const PlanView({
    super.key,
    required this.room,
    this.from,
    this.morph,
    this.layers = const {},
    this.selected,
    this.highlight = const {},
    this.pulse,
    this.showLabels = true,
  });

  final Room room;
  final Room? from;
  final Animation<double>? morph;
  final Set<PlanLayer> layers;
  final String? selected;
  final Set<String> highlight;

  /// Drives the glow on highlighted items.
  final Animation<double>? pulse;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final vin = VinColors.of(context);
    Uint8List? path;
    FloorGrid? grid;
    if (layers.contains(PlanLayer.path)) {
      grid = FloorGrid.of(room);
      path = grid.reachable(room.occupants.wheelchair ? Limits.pathWheelchair : Limits.pathMain);
    }
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _PlanPainter(
          room: room,
          from: from,
          morph: morph,
          pulse: pulse,
          layers: layers,
          selected: selected,
          highlight: highlight,
          showLabels: showLabels,
          grid: grid,
          path: path,
          colours: _Colours(
            floor: t.colorScheme.surfaceContainerLow,
            wall: t.colorScheme.onSurface,
            line: vin.grid,
            furniture: vin.furniture,
            zone: vin.zone,
            accent: vin.accent,
            ink: t.colorScheme.onSurface,
            soft: t.colorScheme.onSurfaceVariant,
            alert: t.colorScheme.error,
          ),
          text: t.textTheme.labelSmall ?? const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}

class _Colours {
  const _Colours({
    required this.floor,
    required this.wall,
    required this.line,
    required this.furniture,
    required this.zone,
    required this.accent,
    required this.ink,
    required this.soft,
    required this.alert,
  });
  final Color floor, wall, line, furniture, zone, accent, ink, soft, alert;
}

/// Tints of the five elements for the Vaastu ninths: water in the
/// north-east, fire in the south-east, earth in the south-west, air in the
/// north-west, space in the centre.
Color elementOf(Dir8? d) => switch (d) {
  null => const Color(0xFF8E7CC3),
  Dir8.ne || Dir8.n => const Color(0xFF3B8ED0),
  Dir8.se || Dir8.s => const Color(0xFFE0703A),
  Dir8.sw || Dir8.w => const Color(0xFF9C7A4E),
  Dir8.nw || Dir8.e => const Color(0xFF8FA3A8),
};

class _PlanPainter extends CustomPainter {
  _PlanPainter({
    required this.room,
    required this.from,
    required this.morph,
    required this.pulse,
    required this.layers,
    required this.selected,
    required this.highlight,
    required this.showLabels,
    required this.grid,
    required this.path,
    required this.colours,
    required this.text,
  }) : super(repaint: Listenable.merge([?morph, ?pulse]));

  final Room room;
  final Room? from;
  final Animation<double>? morph;
  final Animation<double>? pulse;
  final Set<PlanLayer> layers;
  final String? selected;
  final Set<String> highlight;
  final bool showLabels;
  final FloorGrid? grid;
  final Uint8List? path;
  final _Colours colours;
  final TextStyle text;

  @override
  void paint(Canvas canvas, Size size) {
    final fit = PlanFit(size, room);
    final s = fit.scale;
    final floor = fit.rectPx(room.bounds);

    // Floor with a 500 mm grid.
    canvas.drawRRect(
      RRect.fromRectAndRadius(floor, const Radius.circular(2)),
      Paint()..color = colours.floor,
    );
    final fine = Paint()
      ..color = colours.line.withValues(alpha: 0.6)
      ..strokeWidth = 0.6;
    for (var x = 500; x < room.width; x += 500) {
      canvas.drawLine(fit.toPx(x.toDouble(), 0), fit.toPx(x.toDouble(), room.depth.toDouble()), fine);
    }
    for (var y = 500; y < room.depth; y += 500) {
      canvas.drawLine(fit.toPx(0, y.toDouble()), fit.toPx(room.width.toDouble(), y.toDouble()), fine);
    }

    if (layers.contains(PlanLayer.vaastu)) _vaastu(canvas, fit);
    if (layers.contains(PlanLayer.path) && grid != null && path != null) _path(canvas, fit);

    // Where each item is drawn this frame.
    final t = morph == null ? 1.0 : Curves.easeInOutCubic.transform(morph!.value);
    final placed = <(Item, Rect, double)>[];
    for (final item in room.items) {
      final was = from?.item(item.id);
      final now = fit.rectPx(item.box);
      if (was == null || t >= 1) {
        placed.add((item, now, item.rot * math.pi / 2));
        continue;
      }
      final before = fit.rectPx(was.box);
      // Turn the short way round.
      var turn = (item.rot - was.rot) % 4;
      if (turn == 3) turn = -1;
      final centre = Offset.lerp(before.center, now.center, t)!;
      // Drawn unrotated at the item's own size, then turned on canvas.
      placed.add((
        was,
        Rect.fromCenter(center: centre, width: was.box.w * s, height: was.box.d * s),
        (was.rot + turn * t) * math.pi / 2,
      ));
    }

    if (layers.contains(PlanLayer.clearance)) {
      final fill = Paint()..color = colours.zone.withValues(alpha: 0.12);
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = colours.zone.withValues(alpha: 0.6);
      for (final i in room.items.where((i) => i.spec.front > 0)) {
        final r = fit.rectPx(i.frontZone(i.spec.front)).intersect(floor);
        if (r.width <= 0 || r.height <= 0) continue;
        canvas.drawRect(r, fill);
        _dashed(canvas, r, edge);
      }
    }

    // Rugs and other floor-level things first, then furniture on top.
    final ordered = [...placed]
      ..sort((a, b) => (a.$1.spec.blocks ? 1 : 0).compareTo(b.$1.spec.blocks ? 1 : 0));
    final glow = pulse?.value ?? 1;
    for (final (item, rect, angle) in ordered) {
      _item(canvas, item, rect, angle, s, glow);
    }

    _walls(canvas, fit);
    _compass(canvas, size);
    _dimensions(canvas, fit);
  }

  void _item(Canvas canvas, Item item, Rect rect, double angle, double s, double glow) {
    // Draw in the item's own frame: front edge at the bottom.
    final w = item.w * s, d = item.d * s;
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(angle);
    final box = Rect.fromCenter(center: Offset.zero, width: w, height: d);
    final r = RRect.fromRectAndRadius(box, Radius.circular(math.min(8, math.min(w, d) * 0.12)));
    final floorLevel = !item.spec.blocks;
    final base = item.fixed ? colours.soft : colours.furniture;
    if (highlight.contains(item.id)) {
      canvas.drawRRect(
        r.inflate(4 + 3 * glow),
        Paint()
          ..color = colours.alert.withValues(alpha: 0.18 + 0.2 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    if (item.id == selected) {
      canvas.drawRRect(
        r.inflate(5),
        Paint()
          ..color = colours.accent.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawRRect(r, Paint()..color = base.withValues(alpha: floorLevel ? 0.18 : 0.82));
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = item.id == selected ? 2.2 : 1.2
      ..color = item.id == selected
          ? colours.accent
          : highlight.contains(item.id)
          ? colours.alert
          : Color.lerp(base, colours.ink, 0.35)!;
    if (floorLevel) {
      _dashed(canvas, box, outline);
    } else {
      canvas.drawRRect(r, outline);
    }
    // What tells front from back.
    final mark = Paint()..color = Colors.white.withValues(alpha: 0.55);
    if (item.spec.has('bed')) {
      // Pillows at the head (the back).
      final pw = (w - 12) / (item.w >= 1300 ? 2 : 1);
      for (var k = 0; k < (item.w >= 1300 ? 2 : 1); k++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(box.left + 4 + k * (pw + 4), box.top + 4, pw - 4, d * 0.13),
            const Radius.circular(4),
          ),
          mark,
        );
      }
    } else if (item.spec.has('sofa') || item.kind == 'armchair') {
      canvas.drawRect(
        Rect.fromLTWH(box.left, box.top, w, d * 0.25),
        Paint()..color = Colors.black.withValues(alpha: 0.12),
      );
    } else if (item.spec.blocks && item.spec.front > 0) {
      canvas.drawLine(
        Offset(box.left + 3, box.bottom - 2),
        Offset(box.right - 3, box.bottom - 2),
        Paint()
          ..color = colours.accent
          ..strokeWidth = 2,
      );
    }
    canvas.restore();

    if (!showLabels) return;
    final label = TextPainter(
      text: TextSpan(
        text: item.name,
        style: text.copyWith(color: floorLevel ? colours.soft : Colors.white, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      textAlign: TextAlign.center,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0, rect.width - 6));
    if (label.height < rect.height - 4 && rect.width > 28) {
      label.paint(canvas, rect.center - Offset(label.width / 2, label.height / 2));
    }
  }

  void _walls(Canvas canvas, PlanFit fit) {
    final thick = math.max(3.0, 120 * fit.scale);
    final wall = Paint()
      ..color = colours.wall
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.square;
    final w = room.width.toDouble(), d = room.depth.toDouble();
    final corners = {
      Wall.top: (fit.toPx(0, 0), fit.toPx(w, 0)),
      Wall.right: (fit.toPx(w, 0), fit.toPx(w, d)),
      Wall.bottom: (fit.toPx(0, d), fit.toPx(w, d)),
      Wall.left: (fit.toPx(0, 0), fit.toPx(0, d)),
    };
    for (final side in Wall.values) {
      final (a, b) = corners[side]!;
      final len = side.horizontal ? w : d;
      // Gaps where the openings are, walls in between.
      final gaps = [
        for (final o in room.openings.where((o) => o.wall == side))
          (o.offset.toDouble(), (o.offset + o.width).toDouble()),
      ]..sort((x, y) => x.$1.compareTo(y.$1));
      var at = 0.0;
      for (final (g0, g1) in [...gaps, (len, len)]) {
        if (g0 > at) canvas.drawLine(Offset.lerp(a, b, at / len)!, Offset.lerp(a, b, g0 / len)!, wall);
        at = math.max(at, g1);
      }
    }
    for (final o in room.openings) {
      final (a, b) = corners[o.wall]!;
      final len = o.wall.horizontal ? w : d;
      final p0 = Offset.lerp(a, b, o.offset / len)!, p1 = Offset.lerp(a, b, (o.offset + o.width) / len)!;
      switch (o.kind) {
        case OpeningKind.window:
          final glass = Paint()
            ..color = colours.zone
            ..strokeWidth = 2;
          final n = o.wall.horizontal ? Offset(0, thick / 3) : Offset(thick / 3, 0);
          canvas.drawLine(p0 - n, p1 - n, glass);
          canvas.drawLine(p0 + n, p1 + n, glass);
        case OpeningKind.archway:
          break;
        case OpeningKind.door || OpeningKind.balconyDoor:
          final swing = doorSwing(room, o);
          final leaf = Paint()
            ..color = colours.wall.withValues(alpha: 0.8)
            ..strokeWidth = 2;
          final arc = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = colours.soft.withValues(alpha: 0.7);
          if (swing == null) {
            canvas.drawLine(p0, p1, arc);
            continue;
          }
          final hinge = o.hingeAtStart ? p0 : p1;
          final free = o.hingeAtStart ? p1 : p0;
          final inward = switch (o.wall) {
            Wall.top => const Offset(0, 1),
            Wall.bottom => const Offset(0, -1),
            Wall.left => const Offset(1, 0),
            Wall.right => const Offset(-1, 0),
          };
          final radius = (free - hinge).distance;
          final open = hinge + inward * radius;
          canvas.drawLine(hinge, open, leaf);
          final start = math.atan2(free.dy - hinge.dy, free.dx - hinge.dx);
          final end = math.atan2(open.dy - hinge.dy, open.dx - hinge.dx);
          var sweep = end - start;
          if (sweep > math.pi) sweep -= 2 * math.pi;
          if (sweep < -math.pi) sweep += 2 * math.pi;
          canvas.drawArc(Rect.fromCircle(center: hinge, radius: radius), start, sweep, false, arc);
      }
    }
  }

  void _vaastu(Canvas canvas, PlanFit fit) {
    final w = room.width / 3, d = room.depth / 3;
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        final cell = Box((c * w).round(), (r * d).round(), w.round(), d.round());
        final dir = room.dirOf(cell.cx, cell.cy);
        final rect = fit.rectPx(cell);
        canvas.drawRect(rect, Paint()..color = elementOf(dir).withValues(alpha: 0.1));
        _dashed(
          canvas,
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..color = elementOf(dir).withValues(alpha: 0.45),
        );
        final label = TextPainter(
          text: TextSpan(
            text: dir?.short ?? 'Brahma',
            style: text.copyWith(color: elementOf(dir).withValues(alpha: 0.9), fontWeight: FontWeight.w700),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(canvas, rect.topLeft + const Offset(6, 4));
      }
    }
  }

  void _path(Canvas canvas, PlanFit fit) {
    final g = grid!, mask = path!;
    final paint = Paint()..color = colours.zone.withValues(alpha: 0.16);
    final px = g.cell * fit.scale;
    for (var r = 0; r < g.rows; r++) {
      for (var c = 0; c < g.cols; c++) {
        if (mask[r * g.cols + c] == 0) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            fit.toPx(c * g.cell.toDouble(), 0).dx,
            fit.toPx(0, r * g.cell.toDouble()).dy,
            px + 0.5,
            px + 0.5,
          ),
          paint,
        );
      }
    }
  }

  void _compass(Canvas canvas, Size size) {
    final c = Offset(size.width - 26, 26);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colours.soft.withValues(alpha: 0.6);
    canvas.drawCircle(c, 16, ring);
    // North on the plan is up turned back by the room's bearing.
    final a = -room.northDeg * math.pi / 180;
    final tip = c + Offset(math.sin(a), -math.cos(a)) * 14;
    final tail = c - Offset(math.sin(a), -math.cos(a)) * 10;
    final side = Offset(math.cos(a), math.sin(a)) * 5;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(c.dx + side.dx, c.dy + side.dy)
        ..lineTo(tail.dx, tail.dy)
        ..lineTo(c.dx - side.dx, c.dy - side.dy)
        ..close(),
      Paint()..color = colours.alert,
    );
    final n = TextPainter(
      text: TextSpan(
        text: 'N',
        style: text.copyWith(color: colours.ink, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final at = c + Offset(math.sin(a), -math.cos(a)) * 25;
    n.paint(canvas, at - Offset(n.width / 2, n.height / 2));
  }

  void _dimensions(Canvas canvas, PlanFit fit) {
    final style = text.copyWith(color: colours.soft);
    final top = TextPainter(
      text: TextSpan(text: mm(room.width), style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final mid = fit.toPx(room.width / 2, 0);
    top.paint(canvas, mid - Offset(top.width / 2, top.height + 10));
    final side = TextPainter(
      text: TextSpan(text: mm(room.depth), style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final left = fit.toPx(0, room.depth / 2);
    canvas.save();
    canvas.translate(left.dx - side.height - 10, left.dy + side.width / 2);
    canvas.rotate(-math.pi / 2);
    side.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _dashed(Canvas canvas, Rect r, Paint p) {
    const dash = 5.0, gap = 4.0;
    void line(Offset a, Offset b) {
      final len = (b - a).distance;
      final dir = (b - a) / len;
      for (var at = 0.0; at < len; at += dash + gap) {
        canvas.drawLine(a + dir * at, a + dir * math.min(len, at + dash), p);
      }
    }

    line(r.topLeft, r.topRight);
    line(r.topRight, r.bottomRight);
    line(r.bottomRight, r.bottomLeft);
    line(r.bottomLeft, r.topLeft);
  }

  @override
  bool shouldRepaint(_PlanPainter old) =>
      old.room != room ||
      old.from != from ||
      old.layers != layers ||
      old.selected != selected ||
      old.highlight != highlight ||
      old.colours.furniture != colours.furniture ||
      old.colours.floor != colours.floor;
}

/// The item under a point, in plan millimetres: furniture before rugs,
/// the smallest first so a lamp on a rug is still pickable.
Item? itemAt(Room room, Offset mmPoint) {
  final hits =
      [
        for (final i in room.items)
          if (i.box.inflate(60).contains(mmPoint)) i,
      ]..sort((a, b) {
        if (a.spec.blocks != b.spec.blocks) return a.spec.blocks ? -1 : 1;
        return a.box.area.compareTo(b.box.area);
      });
  return hits.firstOrNull;
}

extension on Box {
  bool contains(Offset p) => p.dx >= x && p.dx <= right && p.dy >= y && p.dy <= bottom;
}

/// A small plan for cards and lists, with no labels.
class PlanThumb extends StatelessWidget {
  const PlanThumb(this.room, {super.key, this.height = 120});
  final Room room;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: IgnorePointer(child: PlanView(room: room, showLabels: false)),
  );
}

/// Kinds of furniture as icons, for pickers and lists.
IconData kindIcon(ItemKind k) => switch (k.group) {
  KindGroup.sleep => Icons.bed_outlined,
  KindGroup.seating => Icons.weekend_outlined,
  KindGroup.tables => Icons.table_restaurant_outlined,
  KindGroup.storage => Icons.door_sliding_outlined,
  KindGroup.work => Icons.desk_outlined,
  KindGroup.kitchen => Icons.kitchen_outlined,
  KindGroup.bath => Icons.bathtub_outlined,
  KindGroup.media => Icons.tv_outlined,
  KindGroup.decor =>
    k.has('plant')
        ? Icons.local_florist_outlined
        : (k.has('light') ? Icons.light_outlined : Icons.palette_outlined),
  KindGroup.worship => Icons.temple_hindu_outlined,
  KindGroup.business => Icons.storefront_outlined,
  KindGroup.other => Icons.category_outlined,
};
