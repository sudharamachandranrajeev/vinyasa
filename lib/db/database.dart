import 'package:brahma_core/brahma_core.dart';
import 'package:drift/drift.dart';

import 'tables.dart';

export 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [VinSpaces, VinRooms, VinPlans, VinMedia, VinThemes, Prefs, Outbox, SyncCursors, LocalSettings],
)
class AppDatabase extends _$AppDatabase with SyncedDatabase {
  AppDatabase(super.e);

  /// Opens Vinyasa's encrypted database (see [openEncryptedDatabase]).
  AppDatabase.open(String key) : this(openEncryptedDatabase('vinyasa', key));

  /// vin_media is left out: its files live on one device only.
  @override
  final syncedTables = const ['vin_spaces', 'vin_rooms', 'vin_plans', 'vin_themes', 'prefs'];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      for (final sql in _indexes) {
        await customStatement(sql);
      }
    },
  );

  static const _indexes = [
    'CREATE INDEX vin_rooms_space ON vin_rooms (space)',
    'CREATE INDEX vin_plans_room ON vin_plans (room)',
    'CREATE INDEX vin_media_room ON vin_media (room)',
  ];
}
