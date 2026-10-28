import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vinyasa/domain/samples.dart';
import 'package:vinyasa/domain/scene.dart';
import 'package:vinyasa/domain/space.dart';

void main() {
  // 3.6 × 3.3 m, door on the bottom wall at 300–1200, window on the right
  // wall at 900–2400 with a 900 mm sill.
  final room = sampleBedroom('b');
  const fromBottomRight = V3(6000, 7000, 4000);

  double top(Iterable<Face> faces) => faces.expand((f) => f.points).map((p) => p.z).reduce(math.max);

  test('the walls nearest the eye are lowered and drawn last, the others stand behind', () {
    final s = buildScene(room, eye: fromBottomRight);
    expect(s.cut, {Wall.right, Wall.bottom});
    expect(top(s.before), cutHeight);
    expect(top(s.behind), room.height);
    final order = s.drawOrder(fromBottomRight);
    expect(order.first.surface, Surface.floor);
    final firstItem = order.indexWhere((f) => f.item != null);
    final lastItem = order.lastIndexWhere((f) => f.item != null);
    expect(order.take(firstItem).every((f) => f.item == null), isTrue);
    expect(order.skip(lastItem + 1).every((f) => s.before.contains(f)), isTrue);
    expect(order.every((f) => f.facing(fromBottomRight)), isTrue, reason: 'faces turned away are left out');

    // From inside the room nothing is lowered.
    expect(buildScene(room, eye: const V3(1800, 1600, 1600)).cut, isEmpty);
  });

  test('doors leave a gap to the floor; windows have a sill, glass and a lintel', () {
    final s = buildScene(room, eye: const V3(-3000, -3000, 4000));
    expect(s.cut, {Wall.top, Wall.left});
    final bottom = s.behind.where((f) => f.points.every((p) => (p.y - room.depth).abs() < 1)).toList();
    bool solidAt(List<Face> faces, double along, double z, {required bool x}) => faces.any((f) {
      final a = f.points.map((p) => x ? p.x : p.y), zs = f.points.map((p) => p.z);
      return f.surface == Surface.wall &&
          a.reduce(math.min) <= along &&
          a.reduce(math.max) >= along &&
          zs.reduce(math.min) <= z &&
          zs.reduce(math.max) >= z;
    });
    expect(solidAt(bottom, 750, 1000, x: true), isFalse, reason: 'the doorway');
    expect(solidAt(bottom, 750, 2400, x: true), isTrue, reason: 'above the door');
    expect(solidAt(bottom, 2000, 1000, x: true), isTrue);
    final right = s.behind.where((f) => f.points.every((p) => (p.x - room.width).abs() < 1)).toList();
    expect(solidAt(right, 1600, 500, x: false), isTrue, reason: 'below the sill');
    expect(solidAt(right, 1600, 1500, x: false), isFalse, reason: 'the window');
    expect(s.behind.where((f) => f.surface == Surface.glass), hasLength(1));
  });

  test('pieces stay on their footprint whichever way they turn, the bed head at the back', () {
    for (var rot = 0; rot < 4; rot++) {
      const x = 500, y = 400;
      final bed = Item(id: 'bed', kind: 'bed_queen', x: x, y: y, w: 1600, d: 2100, h: 500, rot: rot);
      final r = room.copyWith(items: [bed]);
      final piece = buildScene(r, eye: fromBottomRight).pieces.single;
      final b = bed.box;
      for (final p in piece.faces.expand((f) => f.points)) {
        expect(p.x, inInclusiveRange(b.x - 0.01, b.right + 0.01), reason: 'rot $rot');
        expect(p.y, inInclusiveRange(b.y - 0.01, b.bottom + 0.01), reason: 'rot $rot');
      }
      // The headboard is the tallest part and stands against backWall.
      final head = piece.faces.reduce((a, b) => a.centre.z >= b.centre.z ? a : b).centre;
      final back = switch (bed.backWall) {
        Wall.top => head.y < b.cy,
        Wall.right => head.x > b.cx,
        Wall.bottom => head.y > b.cy,
        Wall.left => head.x < b.cx,
      };
      expect(back, isTrue, reason: 'rot $rot');
    }
  });

  test('half way through a rearrangement a piece stands half way', () {
    final before = room.copyWith(
      items: [const Item(id: 'c', kind: 'chair', x: 0, y: 0, w: 450, d: 500, h: 850)],
    );
    final after = room.copyWith(
      items: [const Item(id: 'c', kind: 'chair', x: 2000, y: 1000, w: 450, d: 500, h: 850)],
    );
    final mid = buildScene(after, eye: fromBottomRight, from: before, t: 0.5).pieces.single.centre;
    expect((mid.x, mid.y), (1225.0, 750.0));
  });

  test('a TV on a lowered wall is not left floating', () {
    final tv = const Item(id: 'tv', kind: 'tv_wall', x: 1000, y: 3220, w: 1250, d: 80, h: 720, rot: 2);
    final r = room.copyWith(items: [tv]);
    expect(buildScene(r, eye: fromBottomRight).pieces, isEmpty);
    final seen = buildScene(r, eye: const V3(-3000, -3000, 4000)).pieces.single;
    expect(seen.faces.map((f) => f.centre.z).reduce(math.min), greaterThan(500), reason: 'on the wall');
  });

  group('camera', () {
    test('the target lands in the middle of the view; behind the eye is not drawn', () {
      final c = Camera.corner(room, 1.5);
      final view = Projection(c, 900, 600);
      final (x, y) = view.point(c.target)!;
      expect(x, closeTo(450, 0.01));
      expect(y, closeTo(300, 0.01));
      expect(view.point(c.eye + (c.eye - c.target)), isNull);
      for (final p in [const V3(0, 0, 0), V3(room.width.toDouble(), room.depth.toDouble(), 0)]) {
        final (px, py) = view.point(p)!;
        expect(px, inInclusiveRange(0, 900));
        expect(py, inInclusiveRange(0, 600));
      }
    });

    test('a face crossing the eye is cut, not dropped or flipped', () {
      final c = Camera.door(room);
      final view = Projection(c, 800, 600);
      final eye = c.eye;
      // A floor-level strip from behind the eye to beyond the target.
      final strip = [
        V3(eye.x - 200, eye.y + 2000, 0),
        V3(eye.x + 200, eye.y + 2000, 0),
        V3(eye.x + 200, 0, 0),
        V3(eye.x - 200, 0, 0),
      ];
      final cut = view.polygon(strip);
      expect(cut, isNotNull);
      expect(cut!.length, greaterThanOrEqualTo(3));
      expect(view.polygon([for (final p in strip.take(2)) p, eye + const V3(0, 3000, 0)]), isNull);
    });

    test('views glide the short way round', () {
      final a = Camera(target: const V3(0, 0, 0), yaw: 350 * math.pi / 180, pitch: 0.5, distance: 1000);
      final b = a.copyWith(yaw: 10 * math.pi / 180, distance: 3000);
      final mid = a.lerp(b, 0.5);
      expect(mid.yaw % (2 * math.pi), closeTo(0, 1e-9));
      expect(mid.distance, 2000);
    });

    test('from the door the eye stands outside the doorway at eye height', () {
      final eye = Camera.door(room).eye;
      expect(eye.z, closeTo(1600, 1));
      expect(eye.y, greaterThan(room.depth));
      expect(eye.x, closeTo(750, 1));
    });
  });
}
