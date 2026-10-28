import 'dart:convert';

import 'package:brahma_core/brahma_core.dart';
import 'package:drift/drift.dart';

import '../db/database.dart';
import 'json.dart';
import 'photos.dart';
import 'space.dart';

/// Synced preferences. The prefs table is shared by every Brahma app, so
/// Vinyasa's keys start with its id.
abstract final class PrefKeys {
  /// The look picked last on the Ideas page.
  static const ideasStyle = 'vinyasa.ideas.style';

  /// Where ideas photos come from (PhotoSource.name).
  static const photoSource = 'vinyasa.ideas.photos';
}

/// Settings that stay on this device.
abstract final class LocalKeys {
  static const theme = 'vinyasa.theme';
  static const mode = 'vinyasa.mode';
  static const motion = 'vinyasa.motion';
  static const updateOnStart = 'vinyasa.update.on_start';

  /// A version the user went back from, not to be offered again.
  static const updateSkipped = 'vinyasa.update.skipped';

  /// Versions this device has run, newest last, for problem reports.
  static const versions = 'vinyasa.versions';
}

/// The backup format (Settings › Back up).
const backupFormat = 'vinyasa-backup';

String _now() => DateTime.now().toUtc().toIso8601String();

/// The write path and the reads the screens share.
class SpaceBook {
  SpaceBook(this.store);
  final Store store;

  AppDatabase get db => store.db as AppDatabase;

  Future<T> pref<T>(String key, T fallback) async {
    final row = await (db.select(db.prefs)..where((p) => p.id.equals(key))).getSingleOrNull();
    if (row == null || row.deleted) return fallback;
    final v = jsonDecode(row.value);
    return v is T ? v : fallback;
  }

  Future<void> setPref(String key, Object value) => store.save(
    db.prefs,
    PrefsCompanion.insert(id: key, value: jsonEncode(value), deleted: const Value(false)),
    key,
  );

  Future<bool> updateOnStart() async => await db.localSetting(LocalKeys.updateOnStart) != 'off';

  Future<void> setUpdateOnStart(bool on) => db.setLocalSetting(LocalKeys.updateOnStart, on ? 'on' : 'off');

  Future<String> updateSkipped() async => await db.localSetting(LocalKeys.updateSkipped) ?? '';

  Future<void> skipUpdate(String version) => db.setLocalSetting(LocalKeys.updateSkipped, version);

  /// The versions this device has run, newest last.
  Future<List<String>> versions() async => strs(decodeList(await db.localSetting(LocalKeys.versions) ?? ''));

  /// Notes [version] as run on this device; returns the list, newest last.
  Future<List<String>> noteVersion(String version) async {
    final list = await versions();
    if (list.isEmpty || list.last != version) {
      list.add(version);
      while (list.length > 10) {
        list.removeAt(0);
      }
      await db.setLocalSetting(LocalKeys.versions, jsonEncode(list));
    }
    return list;
  }

  // ---- spaces ----

  Future<List<SpaceRow>> spaces() =>
      (db.select(db.vinSpaces)
            ..where((s) => s.deleted.equals(false))
            ..orderBy([(s) => OrderingTerm.desc(s.updated)]))
          .get();

  Future<String> saveSpace({
    String? id,
    required String name,
    required SpaceKind kind,
    String notes = '',
  }) async {
    final key = id ?? newId();
    await store.save(
      db.vinSpaces,
      VinSpacesCompanion.insert(
        id: key,
        name: name.trim(),
        kind: Value(kind.name),
        notes: Value(notes),
        updated: _now(),
        deleted: const Value(false),
      ),
      key,
    );
    return key;
  }

  /// Removes a space with its rooms and their plans.
  Future<void> removeSpace(String id) => db.transaction(() async {
    for (final r in await rooms(id)) {
      await removeRoom(r.id);
    }
    await store.remove(db.vinSpaces, id);
  });

  // ---- rooms ----

  Future<List<RoomRow>> rooms(String space) =>
      (db.select(db.vinRooms)
            ..where((r) => r.space.equals(space) & r.deleted.equals(false))
            ..orderBy([(r) => OrderingTerm.asc(r.name)]))
          .get();

  Future<List<RoomRow>> allRooms() =>
      (db.select(db.vinRooms)
            ..where((r) => r.deleted.equals(false))
            ..orderBy([(r) => OrderingTerm.desc(r.updated)]))
          .get();

  Future<RoomRow?> roomRow(String id) =>
      (db.select(db.vinRooms)..where((r) => r.id.equals(id) & r.deleted.equals(false))).getSingleOrNull();

  Future<Room?> room(String id) async {
    final row = await roomRow(id);
    return row == null ? null : Room.decode(row.json);
  }

  /// Saves [room] (its id is the row's) in [space], with its latest [score].
  Future<void> saveRoom(Room room, {required String space, int? score}) async {
    final had = await roomRow(room.id);
    await store.save(
      db.vinRooms,
      VinRoomsCompanion.insert(
        id: room.id,
        space: space,
        name: room.name,
        type: room.type.name,
        json: room.encode(),
        score: Value(score ?? had?.score ?? -1),
        updated: _now(),
        deleted: const Value(false),
      ),
      room.id,
    );
  }

  Future<void> removeRoom(String id) => db.transaction(() async {
    for (final p in await plans(id)) {
      await store.remove(db.vinPlans, p.id);
    }
    await (db.delete(db.vinMedia)..where((m) => m.room.equals(id))).go();
    for (final p in await pins(id)) {
      await store.remove(db.vinPins, p.id);
    }
    await store.remove(db.vinRooms, id);
  });

  // ---- plans ----

  Future<List<PlanRow>> plans(String room) =>
      (db.select(db.vinPlans)
            ..where((p) => p.room.equals(room) & p.deleted.equals(false))
            ..orderBy([(p) => OrderingTerm.desc(p.created)]))
          .get();

  Future<String> savePlan({
    required String room,
    required Room arranged,
    required int before,
    required int after,
  }) async {
    final id = newId();
    await store.save(
      db.vinPlans,
      VinPlansCompanion.insert(
        id: id,
        room: room,
        json: arranged.encode(),
        scoreBefore: before,
        scoreAfter: after,
        created: _now(),
      ),
      id,
    );
    return id;
  }

  /// Records which steps of [plan] are done. An update, not a save: a save
  /// would insert a row when the plan is missing.
  Future<void> setStepsDone(String plan, Set<String> done) => db.transaction(() async {
    final n = await (db.update(
      db.vinPlans,
    )..where((p) => p.id.equals(plan))).write(VinPlansCompanion(done: Value(done.join(','))));
    if (n > 0) await store.touch(db.vinPlans, plan);
  });

  Future<void> removePlan(String id) => store.remove(db.vinPlans, id);

  // ---- photos and videos (this device only) ----

  Future<List<MediaRow>> media(String room) =>
      (db.select(db.vinMedia)
            ..where((m) => m.room.equals(room))
            ..orderBy([(m) => OrderingTerm.desc(m.added)]))
          .get();

  Future<void> addMedia(String room, String path, String kind) => db
      .into(db.vinMedia)
      .insert(VinMediaCompanion.insert(id: newId(), room: room, path: path, kind: kind, added: _now()));

  Future<void> removeMedia(String id) => (db.delete(db.vinMedia)..where((m) => m.id.equals(id))).go();

  // ---- moodboard ----

  /// A room's pinned ideas photos, newest first.
  Future<List<PinRow>> pins(String room) =>
      (db.select(db.vinPins)
            ..where((p) => p.room.equals(room) & p.deleted.equals(false))
            ..orderBy([(p) => OrderingTerm.desc(p.created)]))
          .get();

  /// Pins [photo] to [room]; pinning it again changes nothing. The id is
  /// made from the room and the photo, so two devices pinning the same
  /// photo make one pin.
  Future<void> pin(String room, IdeaPhoto photo, {String? created}) {
    final id = pinId(room, photo);
    return store.save(
      db.vinPins,
      VinPinsCompanion.insert(
        id: id,
        room: room,
        json: jsonEncode(photo.toJson()),
        created: created ?? _now(),
        deleted: const Value(false),
      ),
      id,
    );
  }

  Future<void> unpin(String room, IdeaPhoto photo) => store.remove(db.vinPins, pinId(room, photo));

  static String pinId(String room, IdeaPhoto p) => '$room.${p.source.name}.${p.id}';

  // ---- themes ----

  Future<List<ThemeRow>> themes() =>
      (db.select(db.vinThemes)
            ..where((t) => t.deleted.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<void> saveTheme(String id, String name, String json) => store.save(
    db.vinThemes,
    VinThemesCompanion.insert(id: id, name: name, json: json, updated: _now(), deleted: const Value(false)),
    id,
  );

  Future<void> removeTheme(String id) => store.remove(db.vinThemes, id);

  // ---- backup ----

  /// Every space with its rooms, plans and pins, as one JSON document.
  Future<String> exportAll() async => const JsonEncoder.withIndent(' ').convert({
    'format': backupFormat,
    'version': 1,
    'exported': _now(),
    'spaces': [
      for (final s in await spaces())
        {
          'id': s.id,
          'name': s.name,
          'kind': s.kind,
          'notes': s.notes,
          'rooms': [
            for (final r in await rooms(s.id))
              {
                'room': decodeObject(r.json),
                'score': r.score,
                'pins': [
                  for (final p in await pins(r.id)) {...decodeObject(p.json), 'pinned': p.created},
                ],
                'plans': [
                  for (final p in await plans(r.id))
                    {
                      'id': p.id,
                      'room': decodeObject(p.json),
                      'done': p.done,
                      'before': p.scoreBefore,
                      'after': p.scoreAfter,
                      'created': p.created,
                    },
                ],
              },
          ],
        },
    ],
  });

  /// Reads a backup, adding or replacing by id. Returns the rooms read.
  Future<int> importAll(String text) async {
    final j = decodeObject(text);
    if (j['format'] != backupFormat) throw const FormatException('This is not a Vinyasa backup.');
    var count = 0;
    await db.transaction(() async {
      for (final s in objs(j['spaces'])) {
        final space = await saveSpace(
          id: str(s['id']).isEmpty ? null : str(s['id']),
          name: str(s['name']).isEmpty ? 'Space' : str(s['name']),
          kind: SpaceKind.of(str(s['kind'])),
          notes: str(s['notes']),
        );
        for (final r in objs(s['rooms'])) {
          final room = Room.fromJson(obj(r['room']));
          if (room.id.isEmpty) continue;
          await saveRoom(room, space: space, score: intOf(r['score']));
          count++;
          for (final p in objs(r['pins'])) {
            final photo = IdeaPhoto.fromJson(p);
            if (photo.id.isEmpty || photo.image.isEmpty) continue;
            await pin(room.id, photo, created: str(p['pinned']).isEmpty ? null : str(p['pinned']));
          }
          for (final p in objs(r['plans'])) {
            final id = str(p['id']).isEmpty ? newId() : str(p['id']);
            await store.save(
              db.vinPlans,
              VinPlansCompanion.insert(
                id: id,
                room: room.id,
                json: jsonEncode(obj(p['room'])),
                done: Value(str(p['done'])),
                scoreBefore: intOf(p['before']) ?? 0,
                scoreAfter: intOf(p['after']) ?? 0,
                created: str(p['created']).isEmpty ? _now() : str(p['created']),
                deleted: const Value(false),
              ),
              id,
            );
          }
        }
      }
    });
    return count;
  }
}
