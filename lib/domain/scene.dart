/// A room as solid shapes for the 3D view (ui/room_3d.dart): a floor, walls
/// with their doors and windows cut out, and each piece built from a few
/// boxes so a bed has its headboard and a sofa its back and arms.
///
/// Millimetres, with x to the right along the plan, y down the plan and z up
/// from the floor. Drawing is back to front (the painter's algorithm), which
/// is exact here because the room is a box seen from outside it or from
/// within: walls whose inside faces the eye stand behind everything in the
/// room, walls seen from outside stand in front of it, and only the pieces
/// need sorting among themselves.
library;

import 'dart:math' as math;

import 'catalog.dart';
import 'space.dart';

class V3 {
  const V3(this.x, this.y, this.z);
  final double x, y, z;

  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator -(V3 o) => V3(x - o.x, y - o.y, z - o.z);
  V3 operator *(double k) => V3(x * k, y * k, z * k);
  double dot(V3 o) => x * o.x + y * o.y + z * o.z;
  V3 cross(V3 o) => V3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => math.sqrt(dot(this));
  V3 get unit {
    final l = length;
    return l == 0 ? this : this * (1 / l);
  }

  @override
  String toString() => 'V3(${x.round()}, ${y.round()}, ${z.round()})';
}

/// What a face is made of, for its colour.
enum Surface { floor, wall, cut, glass, item, soft, screen, plant }

/// One flat, convex face.
class Face {
  const Face(this.points, this.normal, this.surface, {this.item, this.twoSided = false});
  final List<V3> points;

  /// Outward; faces turned away from the eye are not drawn.
  final V3 normal;
  final Surface surface;

  /// The piece this face belongs to.
  final String? item;
  final bool twoSided;

  V3 get centre {
    var s = const V3(0, 0, 0);
    for (final p in points) {
      s = s + p;
    }
    return s * (1 / points.length);
  }

  bool facing(V3 eye) => twoSided || (eye - centre).dot(normal) > 0;
}

/// A piece of furniture as faces, with where it stands for sorting.
class Piece {
  const Piece(this.item, this.centre, this.faces, {this.flat = false});
  final Item item;
  final V3 centre;
  final List<Face> faces;

  /// Lies on the floor (a rug): drawn before anything stands on it.
  final bool flat;
}

class Scene {
  const Scene(this.floor, this.behind, this.pieces, this.before, this.cut);
  final List<Face> floor;

  /// Walls seen from inside the room, and walls seen from outside it.
  final List<Face> behind, before;
  final List<Piece> pieces;

  /// The walls lowered so the eye can see over them, like a doll's house.
  final Set<Wall> cut;

  /// Every face the eye can see, furthest first.
  List<Face> drawOrder(V3 eye) {
    double far(V3 p) => (p - eye).length;
    List<Face> sorted(Iterable<Face> faces) =>
        faces.where((f) => f.facing(eye)).toList()..sort((a, b) => far(b.centre).compareTo(far(a.centre)));
    final standing = pieces.where((p) => !p.flat).toList()
      ..sort((a, b) => far(b.centre).compareTo(far(a.centre)));
    return [
      ...sorted(floor),
      ...sorted(behind),
      for (final p in pieces.where((p) => p.flat)) ...sorted(p.faces),
      for (final p in standing) ...sorted(p.faces),
      ...sorted(before),
    ];
  }
}

/// How thick the walls are drawn, and how high a lowered wall stands.
const wallThickness = 100.0;
const cutHeight = 150.0;

/// Top of a door, archway or window opening.
const _headHeight = 2100.0;

/// [room] seen from [eye]. With [from], pieces stand part way from where
/// they stood there to where they stand in [room], [t] running 0 → 1.
Scene buildScene(Room room, {required V3 eye, Room? from, double t = 1}) {
  final w = room.width.toDouble(), d = room.depth.toDouble();
  final cut = {
    if (eye.y < 0) Wall.top,
    if (eye.x > w) Wall.right,
    if (eye.y > d) Wall.bottom,
    if (eye.x < 0) Wall.left,
  };
  final floor = [
    Face([const V3(0, 0, 0), V3(w, 0, 0), V3(w, d, 0), V3(0, d, 0)], const V3(0, 0, 1), Surface.floor),
  ];
  final behind = <Face>[], before = <Face>[];
  for (final wall in Wall.values) {
    (cut.contains(wall) ? before : behind).addAll(_wall(room, wall, cut.contains(wall)));
  }
  final pieces = <Piece>[];
  for (final item in room.items) {
    final was = t >= 1 ? null : from?.item(item.id);
    if (_hiddenOnCutWall(room, item, cut)) continue;
    pieces.add(_piece(room, item, was, t));
  }
  return Scene(floor, behind, pieces, before, cut);
}

/// A picture or TV on a lowered wall would float in the air.
bool _hiddenOnCutWall(Room room, Item i, Set<Wall> cut) {
  if (!_mounted(i) || !cut.contains(i.backWall)) return false;
  final b = i.box;
  final gap = switch (i.backWall) {
    Wall.top => b.y,
    Wall.right => room.width - b.right,
    Wall.bottom => room.depth - b.bottom,
    Wall.left => b.x,
  };
  return gap < 200;
}

bool _mounted(Item i) => i.spec.wall == WallNeed.must && !i.spec.blocks && i.d <= 100;

// ---- walls ----

/// One wall as slabs: full height between openings, and below and above
/// each opening. Lowered walls keep their door gaps.
List<Face> _wall(Room room, Wall wall, bool lowered) {
  final w = room.width.toDouble(), d = room.depth.toDouble();
  final h = lowered ? cutHeight : room.height.toDouble();
  // Where the wall starts on its inside, which way it runs and which way
  // is into the room.
  final (start, along, inward, length) = switch (wall) {
    Wall.top => (const V3(0, 0, 0), const V3(1, 0, 0), const V3(0, 1, 0), w),
    Wall.right => (V3(w, 0, 0), const V3(0, 1, 0), const V3(-1, 0, 0), d),
    Wall.bottom => (V3(0, d, 0), const V3(1, 0, 0), const V3(0, -1, 0), w),
    Wall.left => (const V3(0, 0, 0), const V3(0, 1, 0), const V3(1, 0, 0), d),
  };
  // Top and bottom walls run on over the corners.
  final over = wall.horizontal ? wallThickness : 0.0;
  final faces = <Face>[];
  final openings = room.openings.where((o) => o.wall == wall).toList()
    ..sort((a, b) => a.offset.compareTo(b.offset));

  void slab(double s0, double s1, double z0, double z1, {bool ends = false}) {
    if (s1 - s0 < 1 || z1 - z0 < 1) return;
    V3 at(double s, double z, double depth) => start + along * s + inward * -depth + V3(0, 0, z);
    final out = inward * -1;
    faces
      ..add(Face([at(s0, z0, 0), at(s1, z0, 0), at(s1, z1, 0), at(s0, z1, 0)], inward, Surface.wall))
      ..add(
        Face(
          [
            at(s0, z0, wallThickness),
            at(s1, z0, wallThickness),
            at(s1, z1, wallThickness),
            at(s0, z1, wallThickness),
          ],
          out,
          Surface.wall,
        ),
      );
    if (z1 >= h - 0.5) {
      faces.add(
        Face(
          [at(s0, z1, 0), at(s1, z1, 0), at(s1, z1, wallThickness), at(s0, z1, wallThickness)],
          const V3(0, 0, 1),
          Surface.cut,
        ),
      );
    }
    if (z0 > 0.5) {
      faces.add(
        Face(
          [at(s0, z0, 0), at(s1, z0, 0), at(s1, z0, wallThickness), at(s0, z0, wallThickness)],
          const V3(0, 0, -1),
          Surface.wall,
        ),
      );
    }
    if (ends) {
      for (final (s, sign) in [(s0, -1.0), (s1, 1.0)]) {
        faces.add(
          Face(
            [at(s, z0, 0), at(s, z0, wallThickness), at(s, z1, wallThickness), at(s, z1, 0)],
            along * sign,
            Surface.wall,
          ),
        );
      }
    }
  }

  var s = -over;
  for (final o in openings) {
    final o0 = o.offset.toDouble().clamp(0.0, length),
        o1 = (o.offset + o.width).toDouble().clamp(0.0, length);
    if (o1 <= o0 || o0 < s) continue;
    slab(s, o0, 0, h, ends: true);
    final window = o.kind == OpeningKind.window;
    final sill = window ? math.min(o.sill.toDouble(), h) : 0.0;
    final head = window ? math.max(_headHeight, sill + 600) : _headHeight;
    slab(o0, o1, 0, sill);
    slab(o0, o1, math.min(head, h), h);
    if (window && !lowered && head > sill) {
      V3 at(double s, double z) => start + along * s + inward * -(wallThickness / 2) + V3(0, 0, z);
      final top = math.min(head, h);
      faces.add(
        Face([at(o0, sill), at(o1, sill), at(o1, top), at(o0, top)], inward, Surface.glass, twoSided: true),
      );
    }
    s = o1;
  }
  slab(s, length + over, 0, h, ends: true);
  return faces;
}

// ---- pieces ----

/// A box in a piece's own frame: x across its width, y from the back (0) to
/// the front, z up.
typedef _Part = (double x0, double x1, double y0, double y1, double z0, double z1, Surface surface);

Piece _piece(Room room, Item item, Item? was, double t) {
  final now = item.box;
  var cx = now.cx, cy = now.cy, angle = item.rot * math.pi / 2;
  var shape = item;
  if (was != null) {
    // Glide and turn the short way round, at the size it had (plan_view.dart).
    var turn = (item.rot - was.rot) % 4;
    if (turn == 3) turn = -1;
    cx = was.box.cx + (now.cx - was.box.cx) * t;
    cy = was.box.cy + (now.cy - was.box.cy) * t;
    angle = (was.rot + turn * t) * math.pi / 2;
    shape = was;
  }
  final w = shape.w.toDouble(), d = shape.d.toDouble();
  final h = math.min(room.height.toDouble(), (shape.h > 0 ? shape.h : shape.spec.h).toDouble());
  final cos = math.cos(angle), sin = math.sin(angle);
  // Turned clockwise on the plan about the centre: at a quarter turn the
  // front (+y) looks left, as Item.rot says.
  V3 turned(double u, double v, double z) => V3(u * cos - v * sin, u * sin + v * cos, z);
  V3 world(double x, double y, double z) => V3(cx, cy, 0) + turned(x - w / 2, y - d / 2, z);
  final faces = <Face>[];
  for (final (x0, x1, y0, y1, z0, z1, surface) in _shapeOf(shape, w, d, h, room.height.toDouble())) {
    if (x1 - x0 < 1 || y1 - y0 < 1 || z1 - z0 < 1) continue;
    final c = [
      for (final z in [z0, z1])
        for (final (x, y) in [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]) world(x, y, z),
    ];
    // c[0..3] the bottom, c[4..7] the top, each back-left, back-right,
    // front-right, front-left.
    void face(List<int> k, V3 n) => faces.add(Face([for (final i in k) c[i]], n, surface, item: item.id));
    face([4, 5, 6, 7], const V3(0, 0, 1));
    if (z0 > 0.5) face([0, 1, 2, 3], const V3(0, 0, -1));
    face([0, 1, 5, 4], turned(0, -1, 0));
    face([3, 2, 6, 7], turned(0, 1, 0));
    face([0, 3, 7, 4], turned(-1, 0, 0));
    face([1, 2, 6, 5], turned(1, 0, 0));
  }
  return Piece(item, V3(cx, cy, h / 2), faces, flat: !item.spec.blocks && h <= 20);
}

const _tables = {
  'desk',
  'desk_l',
  'dining_4',
  'dining_6',
  'dining_round',
  'coffee_table',
  'side_table',
  'console',
  'meeting_table',
  'display_table',
};

/// The boxes [item] is drawn with, [w]×[d]×[h] as it stands in a room
/// [ceiling] high. Unknown kinds are one box.
List<_Part> _shapeOf(Item item, double w, double d, double h, double ceiling) {
  final spec = item.spec;
  const s = Surface.item;
  if (spec.has('rug')) return [(0, w, 0, d, 0, 12, Surface.soft)];
  if (_mounted(item)) {
    final z0 = switch (item.kind) {
      'tv_wall' => 1100 - h / 2,
      'mirror_full' => 300.0,
      _ => 1500 - h / 2,
    }.clamp(0.0, math.max(0.0, ceiling - h)).toDouble();
    return [
      (0, w, 0, d, z0, z0 + h, s),
      if (spec.has('screen'))
        (w * 0.03, w * 0.97, d - 2, d + 2, z0 + h * 0.05, z0 + h * 0.95, Surface.screen),
      if (spec.has('mirror') || spec.has('art'))
        (w * 0.08, w * 0.92, d - 2, d + 2, z0 + h * 0.06, z0 + h * 0.94, Surface.glass),
    ];
  }
  if (item.kind == 'bunk_bed') {
    const post = 60.0;
    return [
      for (final (x, y) in [(0.0, 0.0), (w - post, 0.0), (w - post, d - post), (0.0, d - post)])
        (x, x + post, y, y + post, 0, h, s),
      (post, w - post, 0, d, 150, 350, s),
      (post, w - post, post, d - post, 350, 500, Surface.soft),
      (post, w - post, 0, d, h - 550, h - 350, s),
      (post, w - post, post, d - post, h - 350, h - 200, Surface.soft),
    ];
  }
  if (spec.has('bed') && !spec.has('child')) {
    final pillows = w >= 1300 ? 2 : 1;
    final pw = (w - 120) / pillows;
    return [
      (0, w, 0, d, 0, h * 0.55, s),
      (30, w - 30, 80, d - 20, h * 0.55, h, Surface.soft),
      (0, w, 0, 80, 0, math.max(h + 450, 950), s),
      for (var k = 0; k < pillows; k++)
        (60 + k * pw + 20, 60 + (k + 1) * pw - 20, 120, 420, h, h + 110, Surface.soft),
    ];
  }
  if (spec.has('sofa') || item.kind == 'armchair') {
    final arm = math.min(180.0, w * 0.14), back = math.min(220.0, d * 0.25);
    return [
      (0, w, 0, d, 0, h * 0.5, s),
      (0, w, 0, back, h * 0.5, h, Surface.soft),
      (0, arm, back, d, h * 0.5, h * 0.72, s),
      (w - arm, w, back, d, h * 0.5, h * 0.72, s),
      (arm, w - arm, back, d, h * 0.5, h * 0.58, Surface.soft),
    ];
  }
  if (item.kind == 'chair' || item.kind == 'office_chair') {
    final seat = math.min(460.0, h * 0.55);
    final leg = math.min(40.0, math.min(w, d) * 0.1);
    return [
      if (item.kind == 'office_chair')
        (w / 2 - 30, w / 2 + 30, d / 2 - 30, d / 2 + 30, 0, seat - 60, s)
      else
        for (final (x, y) in [(0.0, 0.0), (w - leg, 0.0), (w - leg, d - leg), (0.0, d - leg)])
          (x, x + leg, y, y + leg, 0, seat - 60, s),
      (0, w, 0, d, seat - 60, seat, Surface.soft),
      (w * 0.05, w * 0.95, 0, 60, seat, h, s),
    ];
  }
  if (_tables.contains(item.kind)) {
    const top = 40.0, leg = 50.0, inset = 30.0;
    return [
      (0, w, 0, d, h - top, h, s),
      for (final (x, y) in [
        (inset, inset),
        (w - inset - leg, inset),
        (w - inset - leg, d - inset - leg),
        (inset, d - inset - leg),
      ])
        (x, x + leg, y, y + leg, 0, h - top, s),
    ];
  }
  if (spec.has('light')) {
    final shade = math.min(350.0, h * 0.3);
    return [
      (w * 0.3, w * 0.7, d * 0.3, d * 0.7, 0, 30, s),
      (w / 2 - 15, w / 2 + 15, d / 2 - 15, d / 2 + 15, 30, h - shade, s),
      (w * 0.1, w * 0.9, d * 0.1, d * 0.9, h - shade, h, Surface.soft),
    ];
  }
  if (spec.has('plant')) {
    return [(w * 0.25, w * 0.75, d * 0.25, d * 0.75, 0, h * 0.3, s), (0, w, 0, d, h * 0.3, h, Surface.plant)];
  }
  return [(0, w, 0, d, 0, math.max(h, 12.0), s)];
}

// ---- the eye ----

/// Where the eye is: [distance] from [target], turned [yaw] round the room
/// (0 looks from below the plan, a quarter turn from its right) and raised
/// [pitch] above the floor. Angles in radians.
class Camera {
  const Camera({required this.target, required this.yaw, required this.pitch, required this.distance});
  final V3 target;
  final double yaw, pitch, distance;

  static const minPitch = 4 * math.pi / 180, maxPitch = 89 * math.pi / 180;

  /// Vertical field of view.
  static const fov = 45 * math.pi / 180;

  V3 get eye =>
      target +
      V3(math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch)) * distance;

  Camera copyWith({V3? target, double? yaw, double? pitch, double? distance}) => Camera(
    target: target ?? this.target,
    yaw: yaw ?? this.yaw,
    pitch: (pitch ?? this.pitch).clamp(minPitch, maxPitch),
    distance: distance ?? this.distance,
  );

  /// Part way to [o], turning the short way round.
  Camera lerp(Camera o, double t) {
    var turn = (o.yaw - yaw) % (2 * math.pi);
    if (turn > math.pi) turn -= 2 * math.pi;
    double mix(double a, double b) => a + (b - a) * t;
    return Camera(
      target: target + (o.target - target) * t,
      yaw: yaw + turn * t,
      pitch: mix(pitch, o.pitch),
      distance: mix(distance, o.distance),
    );
  }

  /// Far enough back to see the whole of [room] in a view [aspect] wide
  /// (width over height).
  static double fit(Room room, double aspect) {
    final r = 0.5 * math.sqrt(room.width * room.width + room.depth * room.depth + room.height * room.height);
    final half = math.atan(math.tan(fov / 2) * math.min(1, aspect));
    return r / math.sin(half) * 1.02;
  }

  static V3 _middle(Room room, double z) => V3(room.width / 2, room.depth / 2, z);

  /// Looking down on the room, the top of the plan at the top.
  factory Camera.above(Room room, double aspect) =>
      Camera(target: _middle(room, room.height / 2), yaw: 0, pitch: maxPitch, distance: fit(room, aspect));

  /// From above the bottom-right corner.
  factory Camera.corner(Room room, double aspect) => Camera(
    target: _middle(room, room.height * 0.25),
    yaw: 35 * math.pi / 180,
    pitch: 38 * math.pi / 180,
    distance: fit(room, aspect),
  );

  /// Standing in the doorway at eye height; from the bottom wall when the
  /// room has no door.
  factory Camera.door(Room room) {
    final door = room.openings.where((o) => o.kind.passable).firstOrNull;
    final w = room.width.toDouble(), d = room.depth.toDouble();
    final s = door == null ? w / 2 : door.offset + door.width / 2;
    final eye = switch (door?.wall ?? Wall.bottom) {
      Wall.top => V3(s, -400, 1600),
      Wall.right => V3(w + 400, s, 1600),
      Wall.bottom => V3(s, d + 400, 1600),
      Wall.left => V3(-400, s, 1600),
    };
    final target = _middle(room, 900);
    final v = eye - target;
    return Camera(
      target: target,
      yaw: math.atan2(v.x, v.y),
      pitch: math.asin(v.z / v.length).clamp(minPitch, maxPitch),
      distance: v.length,
    );
  }
}

/// Turns points into screen positions for a view [width]×[height] from
/// [camera].
class Projection {
  factory Projection(Camera camera, double width, double height) {
    final eye = camera.eye;
    final forward = (camera.target - eye).unit;
    const up = V3(0, 0, 1);
    final right = up.cross(forward).unit;
    return Projection._(
      eye,
      right,
      forward.cross(right),
      forward,
      width / 2,
      height / 2,
      height / 2 / math.tan(Camera.fov / 2),
    );
  }
  const Projection._(this.eye, this._right, this._up, this._forward, this._cx, this._cy, this._focal);

  final V3 eye;
  final V3 _right, _up, _forward;
  final double _cx, _cy, _focal;

  /// Nothing nearer than this is drawn.
  static const near = 50.0;

  V3 _view(V3 p) {
    final v = p - eye;
    return V3(v.dot(_right), v.dot(_up), v.dot(_forward));
  }

  (double, double) _screen(V3 v) => (_cx + v.x * _focal / v.z, _cy - v.y * _focal / v.z);

  /// Where [p] lands, or null when it is behind the eye.
  (double, double)? point(V3 p) {
    final v = _view(p);
    return v.z < near ? null : _screen(v);
  }

  /// The outline of [points] on screen, cut where it passes behind the eye;
  /// null when none of it is in front.
  List<(double, double)>? polygon(List<V3> points) {
    final view = [for (final p in points) _view(p)];
    if (view.every((v) => v.z >= near)) return [for (final v in view) _screen(v)];
    final kept = <V3>[];
    for (var i = 0; i < view.length; i++) {
      final a = view[i], b = view[(i + 1) % view.length];
      final aIn = a.z >= near, bIn = b.z >= near;
      if (aIn) kept.add(a);
      if (aIn != bIn) kept.add(a + (b - a) * ((near - a.z) / (b.z - a.z)));
    }
    return kept.length < 3 ? null : [for (final v in kept) _screen(v)];
  }
}
