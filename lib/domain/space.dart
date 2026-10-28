/// The room model every part of Vinyasa works on: the engine reads it, the
/// planner rearranges it, the plan editor draws it and photo analysis fills
/// it in. Lengths are whole millimetres. The plan's origin is the top-left
/// corner, x grows right and y grows down; "up" on the plan is the top wall,
/// whose compass bearing is [Room.northDeg] away from north.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'catalog.dart';
import 'json.dart';

/// The JSON version this build writes; older ones are read and upgraded.
const roomFormatVersion = 1;

/// What a whole space is.
enum SpaceKind {
  home('Home'),
  office('Office'),
  shop('Shop'),
  clinic('Clinic'),
  studio('Studio'),
  storeroom('Storeroom'),
  other('Other');

  const SpaceKind(this.label);
  final String label;

  static SpaceKind of(String name) => values.where((v) => v.name == name).firstOrNull ?? other;
}

/// What a room is for. The engine picks its rules by this.
enum RoomType {
  bedroom('Bedroom', residential: true),
  kidsRoom('Kids’ room', residential: true),
  living('Living room', residential: true),
  kitchen('Kitchen', residential: true),
  dining('Dining room', residential: true),
  study('Study / home office', residential: true),
  pooja('Pooja room', residential: true),
  bathroom('Bathroom', residential: true),
  entrance('Entrance / foyer', residential: true),
  guest('Guest room', residential: true),
  studio('Studio flat', residential: true),
  office('Office', residential: false),
  meeting('Meeting room', residential: false),
  reception('Reception', residential: false),
  retail('Shop floor', residential: false),
  storeroom('Storeroom', residential: false),
  clinic('Clinic room', residential: false),
  other('Other space', residential: false);

  const RoomType(this.label, {required this.residential});
  final String label;
  final bool residential;

  static RoomType of(String name) => values.where((v) => v.name == name).firstOrNull ?? other;
}

/// The eight compass directions, clockwise from north.
enum Dir8 {
  n('North'),
  ne('North-east'),
  e('East'),
  se('South-east'),
  s('South'),
  sw('South-west'),
  w('West'),
  nw('North-west');

  const Dir8(this.label);
  final String label;

  double get bearing => index * 45.0;

  /// The nearest direction to a bearing in degrees.
  static Dir8 ofBearing(double degrees) => values[((degrees % 360) / 45).round() % 8];

  String get short => name.toUpperCase();
}

/// The four walls of a rectangular room, as drawn on the plan.
enum Wall {
  top,
  right,
  bottom,
  left;

  /// Plan-relative bearing of the wall's outward side: top is 0, right 90.
  double get planBearing => index * 90.0;

  bool get horizontal => this == top || this == bottom;

  static Wall of(String name) => values.where((v) => v.name == name).firstOrNull ?? top;
}

enum OpeningKind {
  door('Door'),
  window('Window'),
  archway('Open archway'),
  balconyDoor('Balcony door');

  const OpeningKind(this.label);
  final String label;

  bool get passable => this != window;

  static OpeningKind of(String name) => values.where((v) => v.name == name).firstOrNull ?? door;
}

/// A door, window or gap in one wall.
class Opening {
  const Opening({
    required this.id,
    required this.kind,
    required this.wall,
    required this.offset,
    required this.width,
    this.sill = 0,
    this.swingIn = true,
    this.hingeAtStart = true,
  });

  final String id;
  final OpeningKind kind;
  final Wall wall;

  /// From the wall's start (left end of top/bottom walls, top end of
  /// left/right walls) to the opening's near edge.
  final int offset;
  final int width;

  /// Windows: height of the sill above the floor.
  final int sill;

  /// Doors: whether the leaf swings into this room, and on which end of the
  /// opening the hinge sits.
  final bool swingIn;
  final bool hingeAtStart;

  Opening copyWith({
    OpeningKind? kind,
    Wall? wall,
    int? offset,
    int? width,
    int? sill,
    bool? swingIn,
    bool? hingeAtStart,
  }) => Opening(
    id: id,
    kind: kind ?? this.kind,
    wall: wall ?? this.wall,
    offset: offset ?? this.offset,
    width: width ?? this.width,
    sill: sill ?? this.sill,
    swingIn: swingIn ?? this.swingIn,
    hingeAtStart: hingeAtStart ?? this.hingeAtStart,
  );

  Json toJson() => {
    'id': id,
    'kind': kind.name,
    'wall': wall.name,
    'offset': offset,
    'width': width,
    if (kind == OpeningKind.window) 'sill': sill,
    if (kind == OpeningKind.door || kind == OpeningKind.balconyDoor) ...{
      'swingIn': swingIn,
      'hingeAtStart': hingeAtStart,
    },
  };

  factory Opening.fromJson(Json j) => Opening(
    id: str(j['id']).isEmpty ? 'o${j.hashCode}' : str(j['id']),
    kind: OpeningKind.of(str(j['kind'])),
    wall: Wall.of(str(j['wall'])),
    offset: math.max(0, intOf(j['offset']) ?? 0),
    width: (intOf(j['width']) ?? 900).clamp(300, 6000),
    sill: (intOf(j['sill']) ?? 900).clamp(0, 2400),
    swingIn: j['swingIn'] != false,
    hingeAtStart: j['hingeAtStart'] != false,
  );
}

/// An axis-aligned rectangle in plan millimetres.
class Box {
  const Box(this.x, this.y, this.w, this.d);
  final int x, y, w, d;

  int get right => x + w;
  int get bottom => y + d;
  double get cx => x + w / 2;
  double get cy => y + d / 2;
  int get area => w * d;

  bool overlaps(Box o) => x < o.right && o.x < right && y < o.bottom && o.y < bottom;

  /// The area two boxes share, 0 when apart.
  int overlapArea(Box o) {
    final int ow = math.min(right, o.right) - math.max(x, o.x);
    final int od = math.min(bottom, o.bottom) - math.max(y, o.y);
    return ow > 0 && od > 0 ? ow * od : 0;
  }

  /// The gap between two boxes along the nearest axis; 0 when they touch or overlap.
  int gap(Box o) {
    final gx = math.max(0, math.max(o.x - right, x - o.right));
    final gy = math.max(0, math.max(o.y - bottom, y - o.bottom));
    return gx == 0 ? gy : (gy == 0 ? gx : math.sqrt(gx * gx + gy * gy).round());
  }

  Box inflate(int by) => Box(x - by, y - by, w + 2 * by, d + 2 * by);

  @override
  String toString() => 'Box($x, $y, $w×$d)';
}

/// One piece of furniture, appliance or fixture.
class Item {
  const Item({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    required this.w,
    required this.d,
    this.h = 0,
    this.rot = 0,
    this.label = '',
    this.fixed = false,
  });

  final String id;

  /// The catalog id (catalog.dart); unknown ids read as `generic`.
  final String kind;

  /// Top-left corner of the footprint as placed, which is [w]×[d] when
  /// [rot] is 0 or 2 and [d]×[w] when it is 1 or 3.
  final int x, y;

  /// Width along the front, depth front to back, height; as unrotated.
  final int w, d, h;

  /// Quarter turns clockwise. At 0 the back is against the top and the
  /// front faces down the plan; at 1 the front faces left, and so on.
  final int rot;

  /// The user's own name for it, else the catalog's.
  final String label;

  /// Built in or not to be moved (a kitchen counter, a radiator).
  final bool fixed;

  ItemKind get spec => itemKind(kind);
  String get name => label.isEmpty ? spec.label : label;

  int get footW => rot.isEven ? w : d;
  int get footD => rot.isEven ? d : w;
  Box get box => Box(x, y, footW, footD);

  /// The direction the front faces, as a plan wall the front looks towards:
  /// rot 0 looks at the bottom wall.
  Wall get facesWall => Wall.values[(2 + rot) % 4];

  /// The wall-side the back is against when the item is pushed back.
  Wall get backWall => Wall.values[rot % 4];

  /// The strip in front of the item a person needs to use it, [depth] deep.
  Box frontZone(int depth) => switch (rot % 4) {
    0 => Box(x, y + footD, footW, depth),
    1 => Box(x - depth, y, depth, footD),
    2 => Box(x, y - depth, footW, depth),
    _ => Box(x + footW, y, depth, footD),
  };

  /// Strips beside the item (left and right of a person facing it), [depth] wide.
  List<Box> sideZones(int depth) => rot.isEven
      ? [Box(x - depth, y, depth, footD), Box(x + footW, y, depth, footD)]
      : [Box(x, y - depth, footW, depth), Box(x, y + footD, footW, depth)];

  Item copyWith({
    String? kind,
    int? x,
    int? y,
    int? w,
    int? d,
    int? h,
    int? rot,
    String? label,
    bool? fixed,
  }) => Item(
    id: id,
    kind: kind ?? this.kind,
    x: x ?? this.x,
    y: y ?? this.y,
    w: w ?? this.w,
    d: d ?? this.d,
    h: h ?? this.h,
    rot: (rot ?? this.rot) % 4,
    label: label ?? this.label,
    fixed: fixed ?? this.fixed,
  );

  Json toJson() => {
    'id': id,
    'kind': kind,
    'x': x,
    'y': y,
    'w': w,
    'd': d,
    if (h > 0) 'h': h,
    if (rot != 0) 'rot': rot,
    if (label.isNotEmpty) 'label': label,
    if (fixed) 'fixed': true,
  };

  factory Item.fromJson(Json j) {
    final spec = itemKind(str(j['kind']));
    return Item(
      id: str(j['id']).isEmpty ? 'i${j.hashCode}' : str(j['id']),
      kind: spec.id,
      x: intOf(j['x']) ?? 0,
      y: intOf(j['y']) ?? 0,
      w: (intOf(j['w']) ?? spec.w).clamp(50, 20000),
      d: (intOf(j['d']) ?? spec.d).clamp(50, 20000),
      h: (intOf(j['h']) ?? spec.h).clamp(0, 6000),
      rot: (intOf(j['rot']) ?? 0) % 4,
      label: str(j['label']),
      fixed: j['fixed'] == true,
    );
  }
}

/// Who uses the room. Needs switch on stricter rules.
class Occupants {
  const Occupants({
    this.people = 1,
    this.wheelchair = false,
    this.elderly = false,
    this.children = false,
    this.leftHanded = false,
  });

  final int people;
  final bool wheelchair, elderly, children, leftHanded;

  Occupants copyWith({int? people, bool? wheelchair, bool? elderly, bool? children, bool? leftHanded}) =>
      Occupants(
        people: people ?? this.people,
        wheelchair: wheelchair ?? this.wheelchair,
        elderly: elderly ?? this.elderly,
        children: children ?? this.children,
        leftHanded: leftHanded ?? this.leftHanded,
      );

  Json toJson() => {
    'people': people,
    if (wheelchair) 'wheelchair': true,
    if (elderly) 'elderly': true,
    if (children) 'children': true,
    if (leftHanded) 'leftHanded': true,
  };

  factory Occupants.fromJson(Json j) => Occupants(
    people: (intOf(j['people']) ?? 1).clamp(1, 500),
    wheelchair: j['wheelchair'] == true,
    elderly: j['elderly'] == true,
    children: j['children'] == true,
    leftHanded: j['leftHanded'] == true,
  );
}

/// What the analysis scores, and what a user can weigh.
enum Category {
  efficiency('Space', 'How well the floor is used and how freely people move.'),
  accessibility('Access', 'Clear routes, reach and room to turn for everyone who uses the space.'),
  ergonomics('Comfort', 'Heights, distances and light that suit the body and the task.'),
  aesthetics('Look', 'Balance, focal point, proportion and calm.'),
  vaastu('Vaastu', 'Directions and zones from Vaastu Shastra.');

  const Category(this.label, this.about);
  final String label, about;
}

/// How far Vaastu is followed.
enum VaastuMode {
  off('Off'),
  gentle('Gentle'),
  strict('Strict');

  const VaastuMode(this.label);
  final String label;

  static VaastuMode of(String name) => values.where((v) => v.name == name).firstOrNull ?? gentle;
}

/// A rectangular room or area with its openings and contents.
class Room {
  const Room({
    required this.id,
    required this.name,
    required this.type,
    required this.width,
    required this.depth,
    this.height = 2700,
    this.northDeg = 0,
    this.openings = const [],
    this.items = const [],
    this.occupants = const Occupants(),
    this.weights = const {},
    this.vaastu = VaastuMode.gentle,
    this.style = '',
    this.notes = '',
  });

  final String id;
  final String name;
  final RoomType type;

  /// Inside dimensions: [width] along the top wall, [depth] down the plan.
  final int width, depth, height;

  /// Compass bearing of the plan's up direction: 0 when the top wall faces
  /// north, 90 when it faces east.
  final double northDeg;

  final List<Opening> openings;
  final List<Item> items;
  final Occupants occupants;

  /// How much each category counts, 0 to 3; missing ones count 1 (Vaastu
  /// follows [vaastu] instead).
  final Map<Category, int> weights;
  final VaastuMode vaastu;

  /// A look the user is after (ideas.dart styles), or empty.
  final String style;
  final String notes;

  Box get bounds => Box(0, 0, width, depth);
  int get area => width * depth;

  int weight(Category c) => c == Category.vaastu
      ? switch (vaastu) {
          VaastuMode.off => 0,
          VaastuMode.gentle => weights[c] ?? 1,
          VaastuMode.strict => weights[c] ?? 3,
        }
      : weights[c] ?? 1;

  Item? item(String id) => items.where((i) => i.id == id).firstOrNull;

  /// Compass bearing of the outward side of [wall].
  double wallBearing(Wall wall) => (northDeg + wall.planBearing) % 360;

  /// The compass direction of [wall].
  Dir8 wallDir(Wall wall) => Dir8.ofBearing(wallBearing(wall));

  /// The compass direction from the room's centre to a plan point, or null
  /// near the centre (the Brahmasthan, the middle ninth).
  Dir8? dirOf(double px, double py) {
    final dx = px - width / 2, dy = py - depth / 2;
    if (dx.abs() <= width / 6 && dy.abs() <= depth / 6) return null;
    // Normalised so a long room's corners still read as corners.
    final nx = dx / width, ny = dy / depth;
    final plan = math.atan2(nx, -ny) * 180 / math.pi;
    return Dir8.ofBearing(northDeg + plan);
  }

  /// The plan point at the middle of the ninth in direction [dir].
  ({double x, double y}) zoneCentre(Dir8 dir) {
    final plan = (dir.bearing - northDeg) * math.pi / 180;
    var nx = math.sin(plan), ny = -math.cos(plan);
    // Out to the edge of the 3×3 grid's middle ring.
    final scale = 1 / math.max(nx.abs(), ny.abs());
    nx *= scale;
    ny *= scale;
    return (x: width / 2 + nx * width / 3, y: depth / 2 + ny * depth / 3);
  }

  /// The compass direction the item's front faces.
  Dir8 facing(Item i) => wallDir(i.facesWall);

  Room copyWith({
    String? name,
    RoomType? type,
    int? width,
    int? depth,
    int? height,
    double? northDeg,
    List<Opening>? openings,
    List<Item>? items,
    Occupants? occupants,
    Map<Category, int>? weights,
    VaastuMode? vaastu,
    String? style,
    String? notes,
  }) => Room(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    width: width ?? this.width,
    depth: depth ?? this.depth,
    height: height ?? this.height,
    northDeg: (northDeg ?? this.northDeg) % 360,
    openings: openings ?? this.openings,
    items: items ?? this.items,
    occupants: occupants ?? this.occupants,
    weights: weights ?? this.weights,
    vaastu: vaastu ?? this.vaastu,
    style: style ?? this.style,
    notes: notes ?? this.notes,
  );

  /// The room with one item replaced (matched by id).
  Room withItem(Item item) => copyWith(items: [for (final i in items) i.id == item.id ? item : i]);

  Json toJson() => {
    'v': roomFormatVersion,
    'id': id,
    'name': name,
    'type': type.name,
    'width': width,
    'depth': depth,
    'height': height,
    'northDeg': northDeg,
    'openings': [for (final o in openings) o.toJson()],
    'items': [for (final i in items) i.toJson()],
    'occupants': occupants.toJson(),
    if (weights.isNotEmpty) 'weights': {for (final e in weights.entries) e.key.name: e.value},
    'vaastu': vaastu.name,
    if (style.isNotEmpty) 'style': style,
    if (notes.isNotEmpty) 'notes': notes,
  };

  String encode() => jsonEncode(toJson());

  /// Reads any version of the format, keeping what makes sense of a damaged
  /// document rather than failing: rooms come from sync, files and AI.
  factory Room.fromJson(Json j) => Room(
    id: str(j['id']),
    name: str(j['name']).isEmpty ? 'Room' : str(j['name']),
    type: RoomType.of(str(j['type'])),
    width: (intOf(j['width']) ?? 4000).clamp(500, 100000),
    depth: (intOf(j['depth']) ?? 3500).clamp(500, 100000),
    height: (intOf(j['height']) ?? 2700).clamp(1800, 20000),
    northDeg: (numOf(j['northDeg']) ?? 0) % 360,
    openings: [for (final o in objs(j['openings'])) Opening.fromJson(o)],
    items: [for (final i in objs(j['items'])) Item.fromJson(i)],
    occupants: Occupants.fromJson(obj(j['occupants'])),
    weights: {
      for (final c in Category.values)
        if (obj(j['weights']).containsKey(c.name)) c: (intOf(obj(j['weights'])[c.name]) ?? 1).clamp(0, 3),
    },
    vaastu: VaastuMode.of(str(j['vaastu'])),
    style: str(j['style']),
    notes: str(j['notes']),
  );

  static Room decode(String text) => Room.fromJson(decodeObject(text));
}

/// Where along the plan an opening sits, as a box on the wall line ([thick]
/// deep into the room) so it can be drawn and tested like an item.
Box openingBox(Room room, Opening o, {int thick = 100}) => switch (o.wall) {
  Wall.top => Box(o.offset, 0, o.width, thick),
  Wall.bottom => Box(o.offset, room.depth - thick, o.width, thick),
  Wall.left => Box(0, o.offset, thick, o.width),
  Wall.right => Box(room.width - thick, o.offset, thick, o.width),
};

/// The square a door leaf sweeps inside the room, or null when it opens
/// outward or there is no leaf.
Box? doorSwing(Room room, Opening o) {
  if ((o.kind != OpeningKind.door && o.kind != OpeningKind.balconyDoor) || !o.swingIn) return null;
  final leaf = o.width;
  return switch (o.wall) {
    Wall.top => Box(o.offset, 0, o.width, leaf),
    Wall.bottom => Box(o.offset, room.depth - leaf, o.width, leaf),
    Wall.left => Box(0, o.offset, leaf, o.width),
    Wall.right => Box(room.width - leaf, o.offset, leaf, o.width),
  };
}
