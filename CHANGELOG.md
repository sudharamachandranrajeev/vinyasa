# Changelog

## 0.1.0 (2026-10-28)

- Spaces and rooms: homes, offices, shops, clinics and studios, each with rooms of 18 kinds. A room
  has its size, which way it faces, its doors and windows, its furniture (about 60 kinds with typical
  sizes), who uses it and what matters most there.
- Plan editor: drag pieces with a 50 mm snap, turn them, resize or rename them, mark them fixed.
  Layers for clearances, walkways from the door and the Vaastu grid with its five elements.
- Analysis: about 45 rules across space, access, comfort, look and Vaastu, each finding with why it
  matters, the measured numbers and what to do. Scores per kind and overall, weighed by what the user
  chose. Picking a finding lights up the pieces on the plan.
- Arrange: finds a better arrangement off the main thread, moving things that belong together as one
  (a bed and its bedside tables, a desk and its chair). The pieces glide to their new places. Kept
  plans become steps in an order that never puts a piece where another still stands, with tips; ticking
  every step updates the room.
- 3D view of each room: walls with their doors and windows, and each kind of piece shaped (a bed with
  its headboard, a sofa with its back and arms, tables on legs, a lamp with its shade). Drag to turn,
  pinch or scroll to zoom, two fingers or the right button to move; buttons glide to a corner view, a
  view from above and the view from the door. The walls nearest the eye lower like a doll's house.
  Analysis and Arrange can switch their pictures to 3D, where findings glow and kept arrangements glide
  into place. Drawn on Flutter's own canvas, with no added libraries.
- Photos and videos of each room, kept on the device.
- Plan from photos: the AI chosen in Ask AI (Gemini, Anthropic, OpenAI, OpenRouter or a local vision
  model, with the user's own key) draws the room, its doors, windows and furniture. Photos are shrunk,
  turned upright and stripped of location and camera details first. Gemini takes short videos whole;
  otherwise frames are taken (Android's own decoder, or the ffmpeg program on computers). Sizes are
  scaled to the measured room; unsure pieces start unticked and glow on the plan for checking.
- Ideas: twelve looks with palettes, the most-loved tips, and searches on Pinterest, Houzz, Behance,
  Dribbble and Unsplash built from the room and the look.
- Photos in Ideas: a grid of photos for the room and look from Openverse (openly licensed, no key;
  registering an email raises the limit) or Unsplash (with the user's own access key). Each photo opens
  large with its creator, licence and source. Pin photos to a room's moodboard; pins sync with the room
  and travel in backups, while the photos stay at their sources.
- Storage tab: list what a room's wardrobes, shelves and cabinets hold (sort of thing, how often used,
  heavy or not). Vinyasa gives each thing a shelf: daily things on the easiest shelves nearest the door,
  heavy things low and never overhead, rarely used things out of the way, with reach set by who uses the
  room (adult, older people, wheelchair 380–1220 mm). Shoes, books, papers and clothes go to storage made
  for them. Steps follow the room: KonMari order at home, 5S red-tagging with a 7-day decision at work,
  ABC slotting in a storeroom. Labels as a printable sheet or a copied list. Kept with the room.
- Will it fit? (in Arrange): give the size of a piece you are thinking of buying and Vinyasa tries it
  against every wall and, for pieces that need no wall, out in the room. It shows the three best places,
  at least 700 mm apart, each checked by the analysis rules with the score before and after, and puts
  the piece on the plan in one tap. It also checks the piece gets through the widest doorway, on its
  side or tilted (doors assumed 2000 mm high).
- Fixed: keeping an older plan no longer undoes changes made to the room since (its name, its users,
  new pieces); only the pieces the plan moved are moved.
- Fixed: restoring a backup brings back spaces, rooms and plans removed since it was made.
- Eight themes made for interiors, a theme editor, light and dark, and a calm mode.
- Updates from GitHub releases, checked against SHA-256 sums, with a backup before each install.
  Going back to an earlier version from Settings (on Android: backup, then the release page).
- Problem reports with version history, system, theme, recent errors and an optional room plan,
  opened as a GitHub issue, copied or saved.
- Backup and restore of every space, room and plan as one JSON file. Sync and app lock from Brahma.
