import 'package:brahma_core/brahma_core.dart';
import 'package:drift/drift.dart';

// Table names are unique across the Brahma suite: every app on an account
// reads the same change log and applies only its own tables. Vinyasa's all
// start with `vin_`.
//
// A room's shape, openings and furniture travel as one JSON document
// (domain/space.dart, versioned by its "v" field) rather than as rows per
// item: a room is edited as a whole, and one row per room keeps sync from
// ever half-applying a move.

/// A place being organised: a home, an office, a shop.
@DataClassName('SpaceRow')
class VinSpaces extends Table with SyncedRow {
  TextColumn get name => text()();

  /// home | office | shop | clinic | studio | storeroom | other
  TextColumn get kind => text().withDefault(const Constant('home'))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// ISO 8601 UTC.
  TextColumn get updated => text()();
}

/// One room or area of a space, as its Room JSON.
@DataClassName('RoomRow')
class VinRooms extends Table with SyncedRow {
  TextColumn get space => text()();
  TextColumn get name => text()();

  /// The room's purpose (RoomType.name), repeated here for lists.
  TextColumn get type => text()();
  TextColumn get json => text()();

  /// Its last overall score, 0 to 100, for lists; -1 before the first analysis.
  IntColumn get score => integer().withDefault(const Constant(-1))();
  TextColumn get updated => text()();
}

/// A suggested arrangement of a room and how far the user has got with it.
@DataClassName('PlanRow')
class VinPlans extends Table with SyncedRow {
  TextColumn get room => text()();

  /// The arranged Room JSON.
  TextColumn get json => text()();

  /// Ids of the steps already done, comma separated.
  TextColumn get done => text().withDefault(const Constant(''))();
  IntColumn get scoreBefore => integer()();
  IntColumn get scoreAfter => integer()();
  TextColumn get created => text()();
}

/// A photo or video of a room. Files stay on the device that took them, so
/// this table is not synced and is written straight, not through the Store.
@DataClassName('MediaRow')
class VinMedia extends Table {
  TextColumn get id => text()();
  TextColumn get room => text()();
  TextColumn get path => text()();

  /// photo | video
  TextColumn get kind => text()();
  TextColumn get added => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A theme made in the theme manager, stored as its export JSON.
@DataClassName('ThemeRow')
class VinThemes extends Table with SyncedRow {
  TextColumn get name => text()();
  TextColumn get json => text()();
  TextColumn get updated => text()();
}

@DataClassName('Pref')
class Prefs extends Table with SyncedRow, PrefColumns {}

@DataClassName('OutboxItem')
class Outbox extends Table with OutboxColumns {}

@DataClassName('SyncCursor')
class SyncCursors extends Table with SyncCursorColumns {}

@DataClassName('LocalSetting')
class LocalSettings extends Table with LocalSettingColumns {}
