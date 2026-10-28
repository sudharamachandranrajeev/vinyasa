import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/material.dart';

import '../ui/ideas_page.dart';
import '../ui/spaces_page.dart';
import '../ui/themes_page.dart';
import 'settings_page.dart';

Destination _d(
  String id,
  String label,
  IconData icon,
  IconData selected,
  Widget page, {
  bool primary = false,
}) => Destination(
  id: id,
  label: label,
  icon: icon,
  selectedIcon: selected,
  primary: primary,
  page: (_) => page,
);

final spacesModule = AppModule(
  id: 'spaces',
  name: 'Spaces',
  destinations: [
    _d('spaces', 'Spaces', Icons.chair_outlined, Icons.chair, const SpacesPage(), primary: true),
    _d('ideas', 'Ideas', Icons.lightbulb_outline, Icons.lightbulb, const IdeasPage(), primary: true),
    _d('themes', 'Themes', Icons.palette_outlined, Icons.palette, const ThemesPage(), primary: true),
  ],
);

final modules = <AppModule>[spacesModule];

/// Settings is app-wide, so it comes after every module's screens.
final settingsDestination = _d(
  'settings',
  'Settings',
  Icons.settings_outlined,
  Icons.settings,
  const SettingsPage(),
);

List<Destination> get allDestinations => [for (final m in modules) ...m.destinations, settingsDestination];
