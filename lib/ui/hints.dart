/// Vinyasa's hints, by id, on top of the shared ones (coreHints).
/// Page banners (ids starting `page.`) explain a whole screen once.
const vinyasaHints = <String, String>{
  'nav.spaces': 'Your homes, offices and shops, and the rooms in each.',
  'nav.ideas': 'Looks, palettes and tips, with searches on Pinterest, Houzz and more.',
  'nav.themes': 'Pick, make and share themes.',
  'nav.settings': 'Updates, backups, problem reports, sync and security.',
  'room.score':
      'Each score starts at 100 and loses points for every problem found: 30 for a must-fix, 12 for a '
      'should-fix, 4 for a nice-to-have. The overall score weighs the five by what you said matters.',
  'room.weights':
      'How much each kind of advice counts when Vinyasa scores and rearranges this room. Zero turns a kind '
      'off.',
  'room.north':
      'Which way the top of the plan faces. Stand at the bottom wall facing the top one and read a compass, '
      'or use the phone’s compass. Vaastu advice and the sun’s path need it.',
  'room.vaastu':
      'Gentle gives Vaastu advice as nice-to-haves that never outweigh comfort or safety. Strict counts it '
      'as should-fix. Off hides it.',
  'plan.drag': 'Drag a piece to move it, tap it to select, and use the buttons to turn or remove it.',
  'plan.layers':
      'Clearances show the room each piece needs in front of it. Walkways show where a person can walk '
      'from the door. The Vaastu grid shows the nine zones and their elements.',
  '3d.how':
      'Drag to turn the room, pinch or scroll to zoom, and drag with two fingers, the right mouse button or '
      'Shift held to move it. The walls nearest you are lowered so you can see in.',
  'arrange.how':
      'Vinyasa tries thousands of small changes, keeps those that fix problems without moving more than '
      'needed, and moves things that belong together (a bed and its bedside tables) as one.',
  'arrange.steps': 'Tick each step as you go; the ticks are kept with the plan.',
  'photos.what':
      'Photos and videos stay on this device unless you tap “Make a plan from these”. Then they go, '
      'smaller and without location data, to the AI chosen in Ask AI’s settings, and the plan it draws '
      'waits for you to check.',
  'page.spaces':
      'Add a space, then its rooms: size, doors and windows, and the furniture in it. Vinyasa checks the '
      'room against about fifty rules and can rearrange it, step by step.',
  'page.ideas':
      'Pick a look to see its palette and what makes it work. The search buttons open Pinterest, Houzz, '
      'Behance, Dribbble or Unsplash with a search for that look.',
  'page.themes':
      'Themes set the colours, the corner roundness and the font. Make your own from scratch or from a '
      'copy, and share them as a small JSON file.',
};
