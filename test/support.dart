import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:vinyasa/db/database.dart';
import 'package:vinyasa/domain/themes.dart';

/// A fresh in-memory database (the bundled SQLite3MultipleCiphers works
/// unkeyed in memory).
AppDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// The built-in themes, read from the repository.
List<VinTheme> builtInThemes() => parseBuiltInThemes(File('themes/builtin.json').readAsStringSync());
