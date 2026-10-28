# Vinyasa's rules

Vinyasa checks a room against a set of rules. Each rule looks at one thing,
says what is wrong and how to fix it, and names a number with a source. This
file lists those numbers and where they come from. The code keeps every number
in one place, `Limits` in `lib/domain/rules.dart`, plus the clear space each
kind of furniture needs in `lib/domain/catalog.dart`.

Units are millimetres throughout. Imperial sources are converted and rounded
to the nearest 10 mm, which is finer than the 50 mm the plan snaps to.

## How findings are weighed

Each finding has a severity and a category.

| Severity | Penalty | Meaning |
|---|---|---|
| Must fix | 30 | Safety, getting in and out, and access for the people the user said live there. |
| Should fix | 12 | Comfort and the clearances guides agree on. |
| Nice to have | 4 | Looks, and traditions the user can take or leave. |

A finding's penalty is scaled by how bad it is (0.1 to 1) and by how much the
user cares about its category (the weight sliders, 0 to 3). The planner moves
furniture to make the total penalty as small as it can.

### Priority when rules disagree

| Tier | Rules | How Vinyasa treats them |
|---|---|---|
| P0 | Safety and egress: door swing, paths, tip-over, rugs on routes | Must fix. |
| P1 | Accessibility, when the room has a wheelchair user, an older adult or children | Must fix while that profile is on; should fix otherwise. |
| P2 | Ergonomics: circulation, NKBA kitchen, bed and wardrobe clearances, desk | Should fix. |
| P3 | Vaastu rules most sources agree on | Should fix in Strict mode, nice to have in Gentle mode. Never must. |
| P4 | Interior-design rules: rugs, balance, focal point | Nice to have. |
| P5 | Disputed Vaastu, feng shui | Nice to have, shown as tips. |

Vaastu can be switched off per room; its category then weighs nothing.

### Known conflicts

| Conflict | Resolution |
|---|---|
| Vaastu bed head south vs. not in line with the door or under a window | Head east is Vaastu's second choice; never north. |
| Vaastu hob in the south-east, cook facing east vs. the NKBA work triangle | The triangle and landings are should; Vaastu is at most should and usually nice, so the triangle wins. |
| Vaastu heavy furniture in the south-west vs. a window, a door or the 900 mm path | Paths and doors are must, so heavy items go on the nearest south or west wall that keeps the path clear. |
| Vaastu desk facing north or east vs. a window glaring on the screen | Pick the north or east facing that keeps the window to the side. |
| Mirror to see the door (feng shui) vs. no mirror facing the bed (Vaastu) | Never a mirror facing the bed. |
| Decor rugs vs. trip hazards | With an older adult or wheelchair user, rugs are secured or removed (must). |
| Floating the sofa vs. the main path | Float it only with 900 mm behind it if people walk there, 300–450 mm if not. |
| Kitchen or toilet in the "wrong" zone of a rented home | Rooms cannot be moved: Vaastu zoning is reported, never scored as a must. |

## Numbers

| Limit | Value | Source |
|---|---|---|
| Main path | 900 | Planner 5D living-room guide (36 in); UK dwelling halls 900 |
| Narrowest usable path | 600 | Bedroom planning guides: 600 beside a bed, under 500 uncomfortable |
| Wheelchair path | 915 | ADA 2010 Standards 403.5.1 |
| Wheelchair turning circle | 1500 | UK guidance 1500; ADA 304.3.1 asks 1525 |
| Door clear width, wheelchair | 815 | ADA 404.2.3 (32 in) |
| Beside a bed | 600 | Bedroom planning guides: minimum 600, comfortable 700–800 |
| Beside a bed, wheelchair | 915 | ADA route width; ADA 806.2.3 clear floor space is at least 760 |
| Lamp within reach of a bed | 600 | CDC "Check for Safety": a lamp or switch reachable from bed |
| Coffee table gap | 300–460 | 12–18 in rule; Houzz 450; under 305 too close |
| Seats in a group, farthest apart | 2440 | Planner 5D: facing seats 1.2–1.5 m, at most 8 ft |
| TV distance | 1.0–2.6 × diagonal | THX 40° (1.2×) to SMPTE 30° (1.6×); general 1.5–2.5× (Planner 5D) |
| Work triangle legs | 1220–2740 | NKBA (4–9 ft) |
| Work triangle total | ≤ 7920 | NKBA (26 ft) |
| Counter between hob and sink | 460 | NKBA sink landing, 18 in on the smaller side |
| Kitchen work aisle | 1050 in front of counters | NKBA 42 in for one cook (48 in for two); Houzz 1000–1200 |
| Free floor in rooms people live in | 35% | Design guides on negative space; Vinyasa's own threshold |
| Shop entrance kept clear | 1500 | Paco Underhill, *Why We Buy*: the decompression zone |
| Office floor per person | 8 m² | High-density offices 8–10 m², standard 10–15 (Workbox; BCO) |
| Tall furniture that can tip | 1500 | Anti-tip guidance for wardrobes and shelves |

Furniture clear space in `catalog.dart`:

| Item | In front | Source |
|---|---|---|
| Hinged wardrobe | 900 | 900 with the door open; 1000–1200 comfortable |
| Sliding wardrobe | 750 | at least 700 |
| Chest of drawers | 900 | 900–1000 (drawer pull-out plus standing) |
| Dining table | 900 all round | 750 Houzz minimum, 813 NKBA, 800–900 comfortable |
| Desk | 900 | Room for the chair to roll back |
| Counter, hob, sink, fridge | 1050 | NKBA work aisle |

## The rules

### Space

| Rule | Checks | Severity |
|---|---|---|
| `inside-room` | Every item fits within the walls | must |
| `no-overlap` | No two items share floor | must |
| `door-swing-clear` | Nothing stands in a door's swing (ADA 404.2.4) | must |
| `window-not-blocked` | Nothing taller than the sill in front of a window | should |
| `clear-front` | Each item's clear space in front is free | must for storage and kitchen; should otherwise |
| `clear-sides` | Chairs can pull out from tables | should |
| `against-wall` | Wall-hugging items stand at the wall | should or nice |
| `free-floor` | Enough open floor | should |
| `clear-entrance` | The way in is open | should |
| `path-main` | A 900 mm route reaches every main item, 600 at worst | must or should |

### Access and safety

| Rule | Checks | Severity |
|---|---|---|
| `wheelchair-path` | A 915 mm route to each main item | must (wheelchair) |
| `turning-space` | A 1500 mm turning circle | must (wheelchair) |
| `door-width` | Doors clear 815 mm. A door is structure that rearranging cannot fix, so this stays should | should (wheelchair) |
| `bed-side` | 600 mm beside a bed; both sides for two sleepers; 915 for a wheelchair | must (wheelchair), should, nice |
| `bed-lamp-reach` | A lamp or nightstand beside each sleeper (CDC) | must (older adult), should |
| `tip-over` | Tall pieces against a wall and anchored | must (children), should |
| `trip-rug` | Rugs secured or removed (CDC; ageing-in-place criteria) | must (older adult, wheelchair) |

### Comfort

| Rule | Checks | Source |
|---|---|---|
| `desk-window` | Screen at right angles to the window, not facing or backing it | OSHA computer workstations eTool |
| `tv-distance` | Viewing distance in range | THX, SMPTE, Planner 5D |
| `seat-faces-focal` | Main seats face the room's focal point | Interior design guides |
| `coffee-gap` | Coffee table within reach | Houzz, Planner 5D |
| `talk-distance` | Seats in a group within 2.4 m | Planner 5D |
| `work-triangle` | Hob, sink and fridge legs and total | NKBA |
| `hob-sink-gap` | Landing counter between hob and sink | NKBA |
| `bed-commanding` | The door is visible from bed, not in line with it | Feng shui commanding position |
| `desk-door` | The door is visible from the desk | Feng shui commanding position |
| `bed-window` | The headboard is not under a window | Vaastu and feng shui sources |
| `office-density` | Floor area per person | Workbox; BCO |

### Looks

| Rule | Checks |
|---|---|
| `focal-point` | The room has one focal point |
| `visual-balance` | Heavy pieces are not all on one side |
| `rug-size` | At least the front legs of the seating are on the rug |
| `float-sofa` | In a large room the sofa comes off the wall, with a path behind it if needed |
| `near-miss` | Items almost against a wall go right up to it |

### Vaastu

Vinyasa divides the room into a 3 × 3 grid turned to the room's north. The
rules are those most Vaastu sources agree on (DesignCafe, L&T Realty,
NoBroker, Interior Company, Asian Paints Beautiful Homes, Astrosight). Where
sources disagree, Vinyasa follows the majority and does not score the
disputed choice.

| Rule | Checks |
|---|---|
| `vaastu-bed-head` | Head south, else east; never north |
| `vaastu-bed-zone` | The bed in the south-west |
| `vaastu-heavy-sw` | Heavy furniture in the south-west |
| `vaastu-ne-open` | North-east kept light and open |
| `vaastu-brahmasthan` | The centre kept open |
| `vaastu-desk-facing` | Facing north or east at a desk |
| `vaastu-hob` | The hob in the south-east |
| `vaastu-water` | Water in the north or north-east |
| `vaastu-fire-water` | Hob and sink not side by side |
| `vaastu-fridge` | The fridge not in the north-east |
| `vaastu-pooja` | The pooja unit in the north-east |
| `vaastu-mirror` | Mirrors on north or east walls, never facing the bed |
| `vaastu-safe` | The safe in the south-west, opening north |
| `vaastu-screen` | The TV and electronics in the south-east |
| `vaastu-toilet` | The WC seat facing north or south |
| `vaastu-entrance` | The main door's direction |

### Shops

| Rule | Checks | Source |
|---|---|---|
| `retail-decompression` | The first 1.5 m inside the door kept clear | Underhill |
| `checkout-exit` | The checkout near the way out | Retail layout guides |

## Tips

The tips on the Ideas page are ranked by how many independent sources repeat
them: Havenly's most common decorating mistakes, Domino's designer mistakes,
Houzz's golden rules of interior design, a roundup of Reddit room-makeover
advice, the Planner 5D layout guide, the Houzz 2026 trends report and the CDC
fall-prevention checklist. Upvote counts could not be used, so repetition
stands in for popularity.

## Sources

- ADA 2010 Standards for Accessible Design, U.S. Access Board.
- NKBA kitchen planning guidelines, as summarised by kitchen-design firms.
- CDC, *Check for Safety: A Home Fall Prevention Checklist for Older Adults*.
- Ageing-in-place criteria published by US city housing departments.
- OSHA computer workstations eTool (archived).
- EN 12464-1 lighting of indoor workplaces (DIALux summaries).
- Planner 5D, Houzz, Havenly, Domino, Arcedior and Houlte furniture and layout guides.
- Paco Underhill, *Why We Buy*.
- Workbox and the British Council for Offices on office density.
- RACGP general-practice layout toolkit (clinics).
- Vaastu: DesignCafe, L&T Realty, NoBroker, Interior Company, Asian Paints Beautiful Homes, Astrosight.
- Feng shui: Feng Shui Beginner, Anjie Cho.
