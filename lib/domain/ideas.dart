/// Ideas: looks to aim for, searches on the big inspiration sites, and the
/// tips people most often rate as the ones that changed their rooms.
///
/// Pinterest, Behance and Dribbble offer no public search API (Pinterest's
/// v5 API cannot search pins, Dribbble's v2 lists only your own shots, and
/// Behance takes no new API clients), so ideas open as searches on their
/// sites, built from the room and the chosen look.
library;

import 'space.dart';

/// A look the user can aim for.
class Look {
  const Look(this.id, this.name, this.about, this.palette);
  final String id, name, about;

  /// A few colours that carry it, as 0xRRGGBB.
  final List<int> palette;
}

const looks = <Look>[
  Look('japandi', 'Japandi', 'Japanese calm meets Scandinavian warmth: low pieces, pale wood, few things.', [
    0xE8E2D6,
    0xB89F7E,
    0x5C5248,
    0x2F2B28,
  ]),
  Look('scandinavian', 'Scandinavian', 'Light, airy and practical: white walls, light oak, soft textiles.', [
    0xF4F2EE,
    0xD9CBB3,
    0x9AA5A1,
    0x3F4A4C,
  ]),
  Look('minimal', 'Minimal', 'Only what is used: clear surfaces, hidden storage, one focal point.', [
    0xFAFAFA,
    0xE0E0E0,
    0x9E9E9E,
    0x212121,
  ]),
  Look(
    'indian-contemporary',
    'Indian contemporary',
    'Warm woods, brass and handloom textiles with clean modern lines.',
    [0xF3E3C3, 0xC9822B, 0x8A3B12, 0x1F4E5F],
  ),
  Look(
    'traditional-indian',
    'Traditional Indian',
    'Carved wood, jaali screens, floor seating and rich colour.',
    [0xF6D7A7, 0xB5452D, 0x6E2C1A, 0x2E5E4E],
  ),
  Look('mid-century', 'Mid-century modern', 'Tapered legs, teak, mustard and teal, graphic shapes.', [
    0xF2E8D5,
    0xD9A441,
    0x2F7C78,
    0x6B3E26,
  ]),
  Look('boho', 'Bohemian', 'Layered rugs, rattan, plants and collected things.', [
    0xF0E2CF,
    0xC97B4A,
    0x7A8B57,
    0x4A3426,
  ]),
  Look('industrial', 'Industrial', 'Exposed brick and metal, leather and reclaimed wood.', [
    0xD8D3CC,
    0x9C6B4E,
    0x4D4D4D,
    0x1E1E1E,
  ]),
  Look('biophilic', 'Biophilic', 'Plants, daylight, natural materials and views out.', [
    0xEEF1E6,
    0x9DB07D,
    0x55704A,
    0x2D3B2A,
  ]),
  Look('wabi-sabi', 'Wabi-sabi', 'Imperfect, handmade and aged: lime plaster, linen, stoneware.', [
    0xE9E1D5,
    0xBFAE97,
    0x8C7B67,
    0x4B4237,
  ]),
  Look('coastal', 'Coastal', 'Breezy whites, sandy neutrals and sea blues.', [
    0xF7F5F0,
    0xD8CBB0,
    0x7FA7B8,
    0x2C5266,
  ]),
  Look('modern-luxe', 'Modern luxe', 'Marble, velvet and brass with a tailored, hotel-like calm.', [
    0xF2EEE9,
    0xC9B79C,
    0x6B5B4E,
    0x1C1C1C,
  ]),
];

Look? lookOf(String id) => looks.where((l) => l.id == id).firstOrNull;

/// A site that takes a search in its address.
class IdeaSite {
  const IdeaSite(this.name, this.build);
  final String name;
  final Uri Function(String query) build;
}

final ideaSites = <IdeaSite>[
  IdeaSite('Pinterest', (q) => Uri.https('www.pinterest.com', '/search/pins/', {'q': q})),
  IdeaSite('Houzz', (q) => Uri.https('www.houzz.com', '/photos/query/${Uri.encodeComponent(q)}')),
  IdeaSite('Behance', (q) => Uri.https('www.behance.net', '/search/projects', {'search': q})),
  IdeaSite('Dribbble', (q) => Uri.https('dribbble.com', '/search/${Uri.encodeComponent(q)}')),
  IdeaSite(
    'Unsplash',
    (q) => Uri.https('unsplash.com', '/s/photos/${Uri.encodeComponent(q.replaceAll(' ', '-'))}'),
  ),
];

/// What to search for: the look, the room, and "small" when it is.
String ideaQuery(Room room, {Look? look, String extra = ''}) {
  final small = room.area < 10e6;
  return [
    if (look != null) look.name.toLowerCase(),
    if (small) 'small',
    room.type.label.toLowerCase().replaceAll('’', ''),
    if (extra.isNotEmpty) extra else 'layout ideas',
  ].join(' ');
}

/// A tip people keep coming back to, and why it works.
class Tip {
  const Tip(this.title, this.why, {this.types});
  final String title, why;

  /// The room types it is for; null for any.
  final Set<RoomType>? types;
}

/// Ranked by how many independent guides and "best advice" threads repeat
/// them; docs/rules.md lists the sources and the rule each one maps to.
const tips = <Tip>[
  Tip(
    'Buy a bigger rug',
    'At least the front legs of every seat on it. A small rug makes the furniture float and the room shrink.',
    types: {RoomType.living, RoomType.bedroom, RoomType.studio},
  ),
  Tip(
    'Layer three kinds of light',
    'Do not rely on the ceiling light: add two to four lamps or sconces for ambient, task and accent light.',
  ),
  Tip(
    'Hang curtains high and wide',
    'Rod near the ceiling, 150–250 mm past the frame and floor-length: windows and ceilings look bigger.',
  ),
  Tip(
    'Float the furniture off the walls',
    'A conversation group in the middle feels bigger and friendlier than seating lining the walls. '
        'Leave 900 mm behind it if people walk there.',
    types: {RoomType.living, RoomType.studio},
  ),
  Tip('Hang art at eye level', 'Centre about 1.45–1.5 m from the floor; most people hang it too high.'),
  Tip(
    'Size art to the furniture below',
    'About two-thirds of its width. Undersized art looks lost; go bigger or hang one gallery group.',
  ),
  Tip(
    'Skip matching sets',
    'Mix materials, eras and shapes so the room looks lived in, not like a showroom.',
  ),
  Tip(
    'Measure and tape it out before you buy',
    'Wrong-size furniture is behind most layout failures. Mark the footprint on the floor and walk round it.',
  ),
  Tip(
    'Coffee table 300–450 mm from the sofa',
    'Close enough to reach a cup, far enough for knees; about half to two-thirds the sofa’s length.',
    types: {RoomType.living, RoomType.studio},
  ),
  Tip(
    'Keep seats within talking distance',
    'Facing seats about 1.2–1.5 m apart, and none of a group more than 2.4 m from the others.',
    types: {RoomType.living, RoomType.studio},
  ),
  Tip('Add one large plant', 'A statement plant per room brings life, colour and height.'),
  Tip(
    'Warm bulbs where you relax',
    'About 2700–3000 K in living rooms and bedrooms; cool light reads clinical at night.',
  ),
  Tip(
    'Give the bed a headboard and dress it',
    'A solid headboard, a throw and pillows finish it. Put the headboard on a solid wall, not under a window.',
    types: {RoomType.bedroom, RoomType.guest, RoomType.studio},
  ),
  Tip(
    'Sconces either side of the bed',
    'Each sleeper gets a light within reach, and the nightstands stay free.',
    types: {RoomType.bedroom, RoomType.guest},
  ),
  Tip(
    'Wall-mount mirrors in small rooms',
    'A leaning floor mirror takes floor; on the wall it gives the light back without it.',
  ),
  Tip(
    'Size the pendant to the table',
    'Half to two-thirds of the table’s width keeps it in scale.',
    types: {RoomType.dining, RoomType.kitchen},
  ),
  Tip(
    'Leave some shelves sparse',
    'Group objects, in odd numbers and varied heights, and let negative space rest the eye.',
  ),
  Tip('Use the 60-30-10 colour rule', 'One main colour, one secondary, one accent keeps a palette calm.'),
  Tip(
    'Warm up neutral rooms with texture',
    'Throws, cushions, wood and woven pieces stop all-white or grey rooms feeling flat.',
  ),
  Tip(
    'Declutter before you decorate',
    'Arranging clutter never works: give everything a home near where it is used.',
  ),
  Tip(
    'Go vertical and multi-purpose',
    'Tall shelves, wall storage, under-bed drawers and fold-away furniture free the floor.',
  ),
  Tip(
    'Zone a studio with rugs and shelves',
    'Open shelving or a rug marks sleeping, working and living areas without walls.',
    types: {RoomType.studio},
  ),
  Tip(
    'Keep the work triangle tight',
    'Hob, sink and fridge 1.2–2.7 m apart, under 7.9 m in all, with nothing cutting across.',
    types: {RoomType.kitchen},
  ),
  Tip(
    'Window to the side of the desk',
    'A screen facing or backing onto a window glares; side light avoids it and the shadow of your hand.',
    types: {RoomType.study, RoomType.office},
  ),
  Tip(
    'Safe paths for older parents',
    'Clear routes, no cords or loose rugs, a lamp by the bed and a night-light to the bathroom.',
  ),
  Tip(
    'Sleep with your head south or east',
    'The Vaastu rule people follow most, and the easiest to keep. Never north.',
    types: {RoomType.bedroom, RoomType.guest, RoomType.kidsRoom},
  ),
  Tip(
    'Light, open north-east',
    'Vaastu’s most kept rule: keep the north-east corner and the centre clean and bright.',
  ),
  Tip(
    'No mirror facing the bed',
    'The Vaastu mirror rule every source agrees on; hang mirrors on north or east walls.',
  ),
  Tip('Heavy to the south-west', 'Wardrobes, safes and the bed in the south-west steady a room in Vaastu.'),
  Tip(
    'Keep the entrance open',
    'In shops, a clear first 1.5 m lets people slow down before they look.',
    types: {RoomType.retail},
  ),
];
