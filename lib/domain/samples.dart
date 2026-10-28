/// Ready-made rooms: offered as "Try an example" on first start, and used
/// by the tests. Each has the common mistakes the rules look for.
library;

import 'catalog.dart';
import 'space.dart';

Item _i(String id, String kind, int x, int y, {int rot = 0, bool? fixed}) {
  final k = itemKind(kind);
  return Item(id: id, kind: kind, x: x, y: y, w: k.w, d: k.d, h: k.h, rot: rot, fixed: fixed ?? k.builtIn);
}

/// A 3.6 × 3.3 m bedroom: bed head on the north wall in line with the door,
/// wardrobe blocking the window, desk with its back to the window.
Room sampleBedroom(String id) => Room(
  id: id,
  name: 'Bedroom',
  type: RoomType.bedroom,
  width: 3600,
  depth: 3300,
  openings: const [
    Opening(id: 'door', kind: OpeningKind.door, wall: Wall.bottom, offset: 300, width: 900),
    Opening(id: 'win', kind: OpeningKind.window, wall: Wall.right, offset: 900, width: 1500, sill: 900),
  ],
  items: [
    _i('ns1', 'nightstand', 0, 0),
    _i('bed', 'bed_queen', 500, 0),
    _i('ns2', 'nightstand', 2150, 0),
    _i('wardrobe', 'wardrobe', 3000, 1000, rot: 1),
    _i('desk', 'desk', 1800, 2700, rot: 2),
    _i('chair', 'office_chair', 2100, 2050),
    _i('rug', 'rug', 900, 1500),
  ],
  occupants: const Occupants(people: 2),
);

/// A 5 × 4.2 m living room with the sofa pinned to the far wall.
Room sampleLiving(String id) => Room(
  id: id,
  name: 'Living room',
  type: RoomType.living,
  width: 5000,
  depth: 4200,
  openings: const [
    Opening(id: 'door', kind: OpeningKind.door, wall: Wall.left, offset: 300, width: 900),
    Opening(id: 'win', kind: OpeningKind.window, wall: Wall.top, offset: 1500, width: 2000, sill: 600),
  ],
  items: [
    _i('sofa', 'sofa_3', 1400, 3300, rot: 2),
    _i('tv', 'tv_unit', 1700, 0),
    _i('table', 'coffee_table', 1900, 2300),
    _i('arm', 'armchair', 4100, 1500, rot: 1),
    _i('shelf', 'bookshelf', 4700, 2600, rot: 1),
    _i('rug', 'rug', 1500, 1000),
    _i('plant', 'plant_large', 0, 3700),
  ],
  occupants: const Occupants(people: 3),
);

/// A 3 × 2.8 m galley kitchen with the hob jammed against the sink.
Room sampleKitchen(String id) => Room(
  id: id,
  name: 'Kitchen',
  type: RoomType.kitchen,
  width: 3000,
  depth: 2800,
  openings: const [Opening(id: 'door', kind: OpeningKind.door, wall: Wall.bottom, offset: 1000, width: 900)],
  items: [
    _i('counter', 'counter', 0, 0, fixed: true),
    _i('sink', 'sink', 1800, 0),
    _i('hob', 'hob', 2400, 0, fixed: false),
    _i('fridge', 'fridge', 0, 2100, rot: 2),
  ],
);
