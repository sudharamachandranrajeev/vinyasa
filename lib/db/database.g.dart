// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $VinSpacesTable extends VinSpaces with TableInfo<$VinSpacesTable, SpaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VinSpacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('home'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta('updated');
  @override
  late final GeneratedColumn<String> updated = GeneratedColumn<String>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, hlc, deleted, name, kind, notes, updated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vin_spaces';
  @override
  VerificationContext validateIntegrity(Insertable<SpaceRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(_hlcMeta, hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta, deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(_notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('updated')) {
      context.handle(_updatedMeta, updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta));
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SpaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpaceRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      hlc: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hlc'])!,
      deleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      notes: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      updated: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}updated'])!,
    );
  }

  @override
  $VinSpacesTable createAlias(String alias) {
    return $VinSpacesTable(attachedDatabase, alias);
  }
}

class SpaceRow extends DataClass implements Insertable<SpaceRow> {
  final String id;
  final String hlc;
  final bool deleted;
  final String name;

  /// home | office | shop | clinic | studio | storeroom | other
  final String kind;
  final String notes;

  /// ISO 8601 UTC.
  final String updated;
  const SpaceRow({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.name,
    required this.kind,
    required this.notes,
    required this.updated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['notes'] = Variable<String>(notes);
    map['updated'] = Variable<String>(updated);
    return map;
  }

  VinSpacesCompanion toCompanion(bool nullToAbsent) {
    return VinSpacesCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      name: Value(name),
      kind: Value(kind),
      notes: Value(notes),
      updated: Value(updated),
    );
  }

  factory SpaceRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpaceRow(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      notes: serializer.fromJson<String>(json['notes']),
      updated: serializer.fromJson<String>(json['updated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'notes': serializer.toJson<String>(notes),
      'updated': serializer.toJson<String>(updated),
    };
  }

  SpaceRow copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? name,
    String? kind,
    String? notes,
    String? updated,
  }) => SpaceRow(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    notes: notes ?? this.notes,
    updated: updated ?? this.updated,
  );
  SpaceRow copyWithCompanion(VinSpacesCompanion data) {
    return SpaceRow(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      notes: data.notes.present ? data.notes.value : this.notes,
      updated: data.updated.present ? data.updated.value : this.updated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpaceRow(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('notes: $notes, ')
          ..write('updated: $updated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, deleted, name, kind, notes, updated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpaceRow &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.notes == this.notes &&
          other.updated == this.updated);
}

class VinSpacesCompanion extends UpdateCompanion<SpaceRow> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> notes;
  final Value<String> updated;
  final Value<int> rowid;
  const VinSpacesCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.notes = const Value.absent(),
    this.updated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VinSpacesCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String name,
    this.kind = const Value.absent(),
    this.notes = const Value.absent(),
    required String updated,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       updated = Value(updated);
  static Insertable<SpaceRow> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? notes,
    Expression<String>? updated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (notes != null) 'notes': notes,
      if (updated != null) 'updated': updated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VinSpacesCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? notes,
    Value<String>? updated,
    Value<int>? rowid,
  }) {
    return VinSpacesCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      notes: notes ?? this.notes,
      updated: updated ?? this.updated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (updated.present) {
      map['updated'] = Variable<String>(updated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VinSpacesCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('notes: $notes, ')
          ..write('updated: $updated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VinRoomsTable extends VinRooms with TableInfo<$VinRoomsTable, RoomRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VinRoomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _spaceMeta = const VerificationMeta('space');
  @override
  late final GeneratedColumn<String> space = GeneratedColumn<String>(
    'space',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta('updated');
  @override
  late final GeneratedColumn<String> updated = GeneratedColumn<String>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, hlc, deleted, space, name, type, json, score, updated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vin_rooms';
  @override
  VerificationContext validateIntegrity(Insertable<RoomRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(_hlcMeta, hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta, deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('space')) {
      context.handle(_spaceMeta, space.isAcceptableOrUnknown(data['space']!, _spaceMeta));
    } else if (isInserting) {
      context.missing(_spaceMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('json')) {
      context.handle(_jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('score')) {
      context.handle(_scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    }
    if (data.containsKey('updated')) {
      context.handle(_updatedMeta, updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta));
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoomRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoomRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      hlc: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hlc'])!,
      deleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      space: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}space'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      json: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}json'])!,
      score: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}score'])!,
      updated: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}updated'])!,
    );
  }

  @override
  $VinRoomsTable createAlias(String alias) {
    return $VinRoomsTable(attachedDatabase, alias);
  }
}

class RoomRow extends DataClass implements Insertable<RoomRow> {
  final String id;
  final String hlc;
  final bool deleted;
  final String space;
  final String name;

  /// The room's purpose (RoomType.name), repeated here for lists.
  final String type;
  final String json;

  /// Its last overall score, 0 to 100, for lists; -1 before the first analysis.
  final int score;
  final String updated;
  const RoomRow({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.space,
    required this.name,
    required this.type,
    required this.json,
    required this.score,
    required this.updated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['space'] = Variable<String>(space);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['json'] = Variable<String>(json);
    map['score'] = Variable<int>(score);
    map['updated'] = Variable<String>(updated);
    return map;
  }

  VinRoomsCompanion toCompanion(bool nullToAbsent) {
    return VinRoomsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      space: Value(space),
      name: Value(name),
      type: Value(type),
      json: Value(json),
      score: Value(score),
      updated: Value(updated),
    );
  }

  factory RoomRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoomRow(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      space: serializer.fromJson<String>(json['space']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      json: serializer.fromJson<String>(json['json']),
      score: serializer.fromJson<int>(json['score']),
      updated: serializer.fromJson<String>(json['updated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'space': serializer.toJson<String>(space),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'json': serializer.toJson<String>(json),
      'score': serializer.toJson<int>(score),
      'updated': serializer.toJson<String>(updated),
    };
  }

  RoomRow copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? space,
    String? name,
    String? type,
    String? json,
    int? score,
    String? updated,
  }) => RoomRow(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    space: space ?? this.space,
    name: name ?? this.name,
    type: type ?? this.type,
    json: json ?? this.json,
    score: score ?? this.score,
    updated: updated ?? this.updated,
  );
  RoomRow copyWithCompanion(VinRoomsCompanion data) {
    return RoomRow(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      space: data.space.present ? data.space.value : this.space,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      json: data.json.present ? data.json.value : this.json,
      score: data.score.present ? data.score.value : this.score,
      updated: data.updated.present ? data.updated.value : this.updated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoomRow(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('space: $space, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('json: $json, ')
          ..write('score: $score, ')
          ..write('updated: $updated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, deleted, space, name, type, json, score, updated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoomRow &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.space == this.space &&
          other.name == this.name &&
          other.type == this.type &&
          other.json == this.json &&
          other.score == this.score &&
          other.updated == this.updated);
}

class VinRoomsCompanion extends UpdateCompanion<RoomRow> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> space;
  final Value<String> name;
  final Value<String> type;
  final Value<String> json;
  final Value<int> score;
  final Value<String> updated;
  final Value<int> rowid;
  const VinRoomsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.space = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.json = const Value.absent(),
    this.score = const Value.absent(),
    this.updated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VinRoomsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String space,
    required String name,
    required String type,
    required String json,
    this.score = const Value.absent(),
    required String updated,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       space = Value(space),
       name = Value(name),
       type = Value(type),
       json = Value(json),
       updated = Value(updated);
  static Insertable<RoomRow> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? space,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? json,
    Expression<int>? score,
    Expression<String>? updated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (space != null) 'space': space,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (json != null) 'json': json,
      if (score != null) 'score': score,
      if (updated != null) 'updated': updated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VinRoomsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? space,
    Value<String>? name,
    Value<String>? type,
    Value<String>? json,
    Value<int>? score,
    Value<String>? updated,
    Value<int>? rowid,
  }) {
    return VinRoomsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      space: space ?? this.space,
      name: name ?? this.name,
      type: type ?? this.type,
      json: json ?? this.json,
      score: score ?? this.score,
      updated: updated ?? this.updated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (space.present) {
      map['space'] = Variable<String>(space.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (updated.present) {
      map['updated'] = Variable<String>(updated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VinRoomsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('space: $space, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('json: $json, ')
          ..write('score: $score, ')
          ..write('updated: $updated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VinPlansTable extends VinPlans with TableInfo<$VinPlansTable, PlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VinPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
    'room',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<String> done = GeneratedColumn<String>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _scoreBeforeMeta = const VerificationMeta('scoreBefore');
  @override
  late final GeneratedColumn<int> scoreBefore = GeneratedColumn<int>(
    'score_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreAfterMeta = const VerificationMeta('scoreAfter');
  @override
  late final GeneratedColumn<int> scoreAfter = GeneratedColumn<int>(
    'score_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdMeta = const VerificationMeta('created');
  @override
  late final GeneratedColumn<String> created = GeneratedColumn<String>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deleted,
    room,
    json,
    done,
    scoreBefore,
    scoreAfter,
    created,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vin_plans';
  @override
  VerificationContext validateIntegrity(Insertable<PlanRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(_hlcMeta, hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta, deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('room')) {
      context.handle(_roomMeta, room.isAcceptableOrUnknown(data['room']!, _roomMeta));
    } else if (isInserting) {
      context.missing(_roomMeta);
    }
    if (data.containsKey('json')) {
      context.handle(_jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('done')) {
      context.handle(_doneMeta, done.isAcceptableOrUnknown(data['done']!, _doneMeta));
    }
    if (data.containsKey('score_before')) {
      context.handle(
        _scoreBeforeMeta,
        scoreBefore.isAcceptableOrUnknown(data['score_before']!, _scoreBeforeMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreBeforeMeta);
    }
    if (data.containsKey('score_after')) {
      context.handle(
        _scoreAfterMeta,
        scoreAfter.isAcceptableOrUnknown(data['score_after']!, _scoreAfterMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreAfterMeta);
    }
    if (data.containsKey('created')) {
      context.handle(_createdMeta, created.isAcceptableOrUnknown(data['created']!, _createdMeta));
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      hlc: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hlc'])!,
      deleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      room: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}room'])!,
      json: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}json'])!,
      done: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}done'])!,
      scoreBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_before'],
      )!,
      scoreAfter: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}score_after'])!,
      created: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}created'])!,
    );
  }

  @override
  $VinPlansTable createAlias(String alias) {
    return $VinPlansTable(attachedDatabase, alias);
  }
}

class PlanRow extends DataClass implements Insertable<PlanRow> {
  final String id;
  final String hlc;
  final bool deleted;
  final String room;

  /// The arranged Room JSON.
  final String json;

  /// Ids of the steps already done, comma separated.
  final String done;
  final int scoreBefore;
  final int scoreAfter;
  final String created;
  const PlanRow({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.room,
    required this.json,
    required this.done,
    required this.scoreBefore,
    required this.scoreAfter,
    required this.created,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['room'] = Variable<String>(room);
    map['json'] = Variable<String>(json);
    map['done'] = Variable<String>(done);
    map['score_before'] = Variable<int>(scoreBefore);
    map['score_after'] = Variable<int>(scoreAfter);
    map['created'] = Variable<String>(created);
    return map;
  }

  VinPlansCompanion toCompanion(bool nullToAbsent) {
    return VinPlansCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      room: Value(room),
      json: Value(json),
      done: Value(done),
      scoreBefore: Value(scoreBefore),
      scoreAfter: Value(scoreAfter),
      created: Value(created),
    );
  }

  factory PlanRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanRow(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      room: serializer.fromJson<String>(json['room']),
      json: serializer.fromJson<String>(json['json']),
      done: serializer.fromJson<String>(json['done']),
      scoreBefore: serializer.fromJson<int>(json['scoreBefore']),
      scoreAfter: serializer.fromJson<int>(json['scoreAfter']),
      created: serializer.fromJson<String>(json['created']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'room': serializer.toJson<String>(room),
      'json': serializer.toJson<String>(json),
      'done': serializer.toJson<String>(done),
      'scoreBefore': serializer.toJson<int>(scoreBefore),
      'scoreAfter': serializer.toJson<int>(scoreAfter),
      'created': serializer.toJson<String>(created),
    };
  }

  PlanRow copyWith({
    String? id,
    String? hlc,
    bool? deleted,
    String? room,
    String? json,
    String? done,
    int? scoreBefore,
    int? scoreAfter,
    String? created,
  }) => PlanRow(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    room: room ?? this.room,
    json: json ?? this.json,
    done: done ?? this.done,
    scoreBefore: scoreBefore ?? this.scoreBefore,
    scoreAfter: scoreAfter ?? this.scoreAfter,
    created: created ?? this.created,
  );
  PlanRow copyWithCompanion(VinPlansCompanion data) {
    return PlanRow(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      room: data.room.present ? data.room.value : this.room,
      json: data.json.present ? data.json.value : this.json,
      done: data.done.present ? data.done.value : this.done,
      scoreBefore: data.scoreBefore.present ? data.scoreBefore.value : this.scoreBefore,
      scoreAfter: data.scoreAfter.present ? data.scoreAfter.value : this.scoreAfter,
      created: data.created.present ? data.created.value : this.created,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanRow(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('room: $room, ')
          ..write('json: $json, ')
          ..write('done: $done, ')
          ..write('scoreBefore: $scoreBefore, ')
          ..write('scoreAfter: $scoreAfter, ')
          ..write('created: $created')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, deleted, room, json, done, scoreBefore, scoreAfter, created);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanRow &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.room == this.room &&
          other.json == this.json &&
          other.done == this.done &&
          other.scoreBefore == this.scoreBefore &&
          other.scoreAfter == this.scoreAfter &&
          other.created == this.created);
}

class VinPlansCompanion extends UpdateCompanion<PlanRow> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> room;
  final Value<String> json;
  final Value<String> done;
  final Value<int> scoreBefore;
  final Value<int> scoreAfter;
  final Value<String> created;
  final Value<int> rowid;
  const VinPlansCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.room = const Value.absent(),
    this.json = const Value.absent(),
    this.done = const Value.absent(),
    this.scoreBefore = const Value.absent(),
    this.scoreAfter = const Value.absent(),
    this.created = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VinPlansCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String room,
    required String json,
    this.done = const Value.absent(),
    required int scoreBefore,
    required int scoreAfter,
    required String created,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       room = Value(room),
       json = Value(json),
       scoreBefore = Value(scoreBefore),
       scoreAfter = Value(scoreAfter),
       created = Value(created);
  static Insertable<PlanRow> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? room,
    Expression<String>? json,
    Expression<String>? done,
    Expression<int>? scoreBefore,
    Expression<int>? scoreAfter,
    Expression<String>? created,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (room != null) 'room': room,
      if (json != null) 'json': json,
      if (done != null) 'done': done,
      if (scoreBefore != null) 'score_before': scoreBefore,
      if (scoreAfter != null) 'score_after': scoreAfter,
      if (created != null) 'created': created,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VinPlansCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? room,
    Value<String>? json,
    Value<String>? done,
    Value<int>? scoreBefore,
    Value<int>? scoreAfter,
    Value<String>? created,
    Value<int>? rowid,
  }) {
    return VinPlansCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      room: room ?? this.room,
      json: json ?? this.json,
      done: done ?? this.done,
      scoreBefore: scoreBefore ?? this.scoreBefore,
      scoreAfter: scoreAfter ?? this.scoreAfter,
      created: created ?? this.created,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (done.present) {
      map['done'] = Variable<String>(done.value);
    }
    if (scoreBefore.present) {
      map['score_before'] = Variable<int>(scoreBefore.value);
    }
    if (scoreAfter.present) {
      map['score_after'] = Variable<int>(scoreAfter.value);
    }
    if (created.present) {
      map['created'] = Variable<String>(created.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VinPlansCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('room: $room, ')
          ..write('json: $json, ')
          ..write('done: $done, ')
          ..write('scoreBefore: $scoreBefore, ')
          ..write('scoreAfter: $scoreAfter, ')
          ..write('created: $created, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VinMediaTable extends VinMedia with TableInfo<$VinMediaTable, MediaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VinMediaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
    'room',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedMeta = const VerificationMeta('added');
  @override
  late final GeneratedColumn<String> added = GeneratedColumn<String>(
    'added',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, room, path, kind, added];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vin_media';
  @override
  VerificationContext validateIntegrity(Insertable<MediaRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('room')) {
      context.handle(_roomMeta, room.isAcceptableOrUnknown(data['room']!, _roomMeta));
    } else if (isInserting) {
      context.missing(_roomMeta);
    }
    if (data.containsKey('path')) {
      context.handle(_pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('added')) {
      context.handle(_addedMeta, added.isAcceptableOrUnknown(data['added']!, _addedMeta));
    } else if (isInserting) {
      context.missing(_addedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      room: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}room'])!,
      path: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      added: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}added'])!,
    );
  }

  @override
  $VinMediaTable createAlias(String alias) {
    return $VinMediaTable(attachedDatabase, alias);
  }
}

class MediaRow extends DataClass implements Insertable<MediaRow> {
  final String id;
  final String room;
  final String path;

  /// photo | video
  final String kind;
  final String added;
  const MediaRow({
    required this.id,
    required this.room,
    required this.path,
    required this.kind,
    required this.added,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['room'] = Variable<String>(room);
    map['path'] = Variable<String>(path);
    map['kind'] = Variable<String>(kind);
    map['added'] = Variable<String>(added);
    return map;
  }

  VinMediaCompanion toCompanion(bool nullToAbsent) {
    return VinMediaCompanion(
      id: Value(id),
      room: Value(room),
      path: Value(path),
      kind: Value(kind),
      added: Value(added),
    );
  }

  factory MediaRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaRow(
      id: serializer.fromJson<String>(json['id']),
      room: serializer.fromJson<String>(json['room']),
      path: serializer.fromJson<String>(json['path']),
      kind: serializer.fromJson<String>(json['kind']),
      added: serializer.fromJson<String>(json['added']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'room': serializer.toJson<String>(room),
      'path': serializer.toJson<String>(path),
      'kind': serializer.toJson<String>(kind),
      'added': serializer.toJson<String>(added),
    };
  }

  MediaRow copyWith({String? id, String? room, String? path, String? kind, String? added}) => MediaRow(
    id: id ?? this.id,
    room: room ?? this.room,
    path: path ?? this.path,
    kind: kind ?? this.kind,
    added: added ?? this.added,
  );
  MediaRow copyWithCompanion(VinMediaCompanion data) {
    return MediaRow(
      id: data.id.present ? data.id.value : this.id,
      room: data.room.present ? data.room.value : this.room,
      path: data.path.present ? data.path.value : this.path,
      kind: data.kind.present ? data.kind.value : this.kind,
      added: data.added.present ? data.added.value : this.added,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaRow(')
          ..write('id: $id, ')
          ..write('room: $room, ')
          ..write('path: $path, ')
          ..write('kind: $kind, ')
          ..write('added: $added')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, room, path, kind, added);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaRow &&
          other.id == this.id &&
          other.room == this.room &&
          other.path == this.path &&
          other.kind == this.kind &&
          other.added == this.added);
}

class VinMediaCompanion extends UpdateCompanion<MediaRow> {
  final Value<String> id;
  final Value<String> room;
  final Value<String> path;
  final Value<String> kind;
  final Value<String> added;
  final Value<int> rowid;
  const VinMediaCompanion({
    this.id = const Value.absent(),
    this.room = const Value.absent(),
    this.path = const Value.absent(),
    this.kind = const Value.absent(),
    this.added = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VinMediaCompanion.insert({
    required String id,
    required String room,
    required String path,
    required String kind,
    required String added,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       room = Value(room),
       path = Value(path),
       kind = Value(kind),
       added = Value(added);
  static Insertable<MediaRow> custom({
    Expression<String>? id,
    Expression<String>? room,
    Expression<String>? path,
    Expression<String>? kind,
    Expression<String>? added,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (room != null) 'room': room,
      if (path != null) 'path': path,
      if (kind != null) 'kind': kind,
      if (added != null) 'added': added,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VinMediaCompanion copyWith({
    Value<String>? id,
    Value<String>? room,
    Value<String>? path,
    Value<String>? kind,
    Value<String>? added,
    Value<int>? rowid,
  }) {
    return VinMediaCompanion(
      id: id ?? this.id,
      room: room ?? this.room,
      path: path ?? this.path,
      kind: kind ?? this.kind,
      added: added ?? this.added,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (added.present) {
      map['added'] = Variable<String>(added.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VinMediaCompanion(')
          ..write('id: $id, ')
          ..write('room: $room, ')
          ..write('path: $path, ')
          ..write('kind: $kind, ')
          ..write('added: $added, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VinThemesTable extends VinThemes with TableInfo<$VinThemesTable, ThemeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VinThemesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta('updated');
  @override
  late final GeneratedColumn<String> updated = GeneratedColumn<String>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, hlc, deleted, name, json, updated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vin_themes';
  @override
  VerificationContext validateIntegrity(Insertable<ThemeRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(_hlcMeta, hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta, deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('json')) {
      context.handle(_jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('updated')) {
      context.handle(_updatedMeta, updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta));
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ThemeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ThemeRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      hlc: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hlc'])!,
      deleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      json: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}json'])!,
      updated: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}updated'])!,
    );
  }

  @override
  $VinThemesTable createAlias(String alias) {
    return $VinThemesTable(attachedDatabase, alias);
  }
}

class ThemeRow extends DataClass implements Insertable<ThemeRow> {
  final String id;
  final String hlc;
  final bool deleted;
  final String name;
  final String json;
  final String updated;
  const ThemeRow({
    required this.id,
    required this.hlc,
    required this.deleted,
    required this.name,
    required this.json,
    required this.updated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['name'] = Variable<String>(name);
    map['json'] = Variable<String>(json);
    map['updated'] = Variable<String>(updated);
    return map;
  }

  VinThemesCompanion toCompanion(bool nullToAbsent) {
    return VinThemesCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deleted: Value(deleted),
      name: Value(name),
      json: Value(json),
      updated: Value(updated),
    );
  }

  factory ThemeRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ThemeRow(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      name: serializer.fromJson<String>(json['name']),
      json: serializer.fromJson<String>(json['json']),
      updated: serializer.fromJson<String>(json['updated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'name': serializer.toJson<String>(name),
      'json': serializer.toJson<String>(json),
      'updated': serializer.toJson<String>(updated),
    };
  }

  ThemeRow copyWith({String? id, String? hlc, bool? deleted, String? name, String? json, String? updated}) =>
      ThemeRow(
        id: id ?? this.id,
        hlc: hlc ?? this.hlc,
        deleted: deleted ?? this.deleted,
        name: name ?? this.name,
        json: json ?? this.json,
        updated: updated ?? this.updated,
      );
  ThemeRow copyWithCompanion(VinThemesCompanion data) {
    return ThemeRow(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      name: data.name.present ? data.name.value : this.name,
      json: data.json.present ? data.json.value : this.json,
      updated: data.updated.present ? data.updated.value : this.updated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ThemeRow(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('json: $json, ')
          ..write('updated: $updated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, deleted, name, json, updated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ThemeRow &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.name == this.name &&
          other.json == this.json &&
          other.updated == this.updated);
}

class VinThemesCompanion extends UpdateCompanion<ThemeRow> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> name;
  final Value<String> json;
  final Value<String> updated;
  final Value<int> rowid;
  const VinThemesCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.name = const Value.absent(),
    this.json = const Value.absent(),
    this.updated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VinThemesCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String name,
    required String json,
    required String updated,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       json = Value(json),
       updated = Value(updated);
  static Insertable<ThemeRow> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? name,
    Expression<String>? json,
    Expression<String>? updated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (name != null) 'name': name,
      if (json != null) 'json': json,
      if (updated != null) 'updated': updated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VinThemesCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? name,
    Value<String>? json,
    Value<String>? updated,
    Value<int>? rowid,
  }) {
    return VinThemesCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      name: name ?? this.name,
      json: json ?? this.json,
      updated: updated ?? this.updated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (updated.present) {
      map['updated'] = Variable<String>(updated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VinThemesCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('name: $name, ')
          ..write('json: $json, ')
          ..write('updated: $updated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrefsTable extends Prefs with TableInfo<$PrefsTable, Pref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, hlc, deleted, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prefs';
  @override
  VerificationContext validateIntegrity(Insertable<Pref> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(_hlcMeta, hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta, deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pref(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      hlc: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hlc'])!,
      deleted: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $PrefsTable createAlias(String alias) {
    return $PrefsTable(attachedDatabase, alias);
  }
}

class Pref extends DataClass implements Insertable<Pref> {
  final String id;
  final String hlc;
  final bool deleted;
  final String value;
  const Pref({required this.id, required this.hlc, required this.deleted, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    map['deleted'] = Variable<bool>(deleted);
    map['value'] = Variable<String>(value);
    return map;
  }

  PrefsCompanion toCompanion(bool nullToAbsent) {
    return PrefsCompanion(id: Value(id), hlc: Value(hlc), deleted: Value(deleted), value: Value(value));
  }

  factory Pref.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pref(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deleted': serializer.toJson<bool>(deleted),
      'value': serializer.toJson<String>(value),
    };
  }

  Pref copyWith({String? id, String? hlc, bool? deleted, String? value}) => Pref(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deleted: deleted ?? this.deleted,
    value: value ?? this.value,
  );
  Pref copyWithCompanion(PrefsCompanion data) {
    return Pref(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pref(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, deleted, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pref &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deleted == this.deleted &&
          other.value == this.value);
}

class PrefsCompanion extends UpdateCompanion<Pref> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<bool> deleted;
  final Value<String> value;
  final Value<int> rowid;
  const PrefsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrefsCompanion.insert({
    required String id,
    this.hlc = const Value.absent(),
    this.deleted = const Value.absent(),
    required String value,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       value = Value(value);
  static Insertable<Pref> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<bool>? deleted,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deleted != null) 'deleted': deleted,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrefsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<bool>? deleted,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PrefsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deleted: deleted ?? this.deleted,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrefsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deleted: $deleted, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [entity, rowId, seq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(Insertable<OutboxItem> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(_entityMeta, entity.isAcceptableOrUnknown(data['entity']!, _entityMeta));
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(_rowIdMeta, rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta));
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(_seqMeta, seq.isAcceptableOrUnknown(data['seq']!, _seqMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity, rowId};
  @override
  OutboxItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxItem(
      entity: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}entity'])!,
      rowId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}row_id'])!,
      seq: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}seq']),
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxItem extends DataClass implements Insertable<OutboxItem> {
  final String entity;
  final String rowId;
  final int? seq;
  const OutboxItem({required this.entity, required this.rowId, this.seq});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['row_id'] = Variable<String>(rowId);
    if (!nullToAbsent || seq != null) {
      map['seq'] = Variable<int>(seq);
    }
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      entity: Value(entity),
      rowId: Value(rowId),
      seq: seq == null && nullToAbsent ? const Value.absent() : Value(seq),
    );
  }

  factory OutboxItem.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxItem(
      entity: serializer.fromJson<String>(json['entity']),
      rowId: serializer.fromJson<String>(json['rowId']),
      seq: serializer.fromJson<int?>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'rowId': serializer.toJson<String>(rowId),
      'seq': serializer.toJson<int?>(seq),
    };
  }

  OutboxItem copyWith({String? entity, String? rowId, Value<int?> seq = const Value.absent()}) => OutboxItem(
    entity: entity ?? this.entity,
    rowId: rowId ?? this.rowId,
    seq: seq.present ? seq.value : this.seq,
  );
  OutboxItem copyWithCompanion(OutboxCompanion data) {
    return OutboxItem(
      entity: data.entity.present ? data.entity.value : this.entity,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxItem(')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entity, rowId, seq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxItem &&
          other.entity == this.entity &&
          other.rowId == this.rowId &&
          other.seq == this.seq);
}

class OutboxCompanion extends UpdateCompanion<OutboxItem> {
  final Value<String> entity;
  final Value<String> rowId;
  final Value<int?> seq;
  final Value<int> rowid;
  const OutboxCompanion({
    this.entity = const Value.absent(),
    this.rowId = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String entity,
    required String rowId,
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       rowId = Value(rowId);
  static Insertable<OutboxItem> custom({
    Expression<String>? entity,
    Expression<String>? rowId,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (rowId != null) 'row_id': rowId,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? entity,
    Value<String>? rowId,
    Value<int?>? seq,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      entity: entity ?? this.entity,
      rowId: rowId ?? this.rowId,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('entity: $entity, ')
          ..write('rowId: $rowId, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCursorsTable extends SyncCursors with TableInfo<$SyncCursorsTable, SyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [deviceId, seq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(Insertable<SyncCursor> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta, deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(_seqMeta, seq.isAcceptableOrUnknown(data['seq']!, _seqMeta));
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  SyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursor(
      deviceId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      seq: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}seq'])!,
    );
  }

  @override
  $SyncCursorsTable createAlias(String alias) {
    return $SyncCursorsTable(attachedDatabase, alias);
  }
}

class SyncCursor extends DataClass implements Insertable<SyncCursor> {
  final String deviceId;
  final int seq;
  const SyncCursor({required this.deviceId, required this.seq});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['seq'] = Variable<int>(seq);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(deviceId: Value(deviceId), seq: Value(seq));
  }

  factory SyncCursor.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursor(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      seq: serializer.fromJson<int>(json['seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'seq': serializer.toJson<int>(seq),
    };
  }

  SyncCursor copyWith({String? deviceId, int? seq}) =>
      SyncCursor(deviceId: deviceId ?? this.deviceId, seq: seq ?? this.seq);
  SyncCursor copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursor(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      seq: data.seq.present ? data.seq.value : this.seq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursor(')
          ..write('deviceId: $deviceId, ')
          ..write('seq: $seq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, seq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursor && other.deviceId == this.deviceId && other.seq == this.seq);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursor> {
  final Value<String> deviceId;
  final Value<int> seq;
  final Value<int> rowid;
  const SyncCursorsCompanion({
    this.deviceId = const Value.absent(),
    this.seq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursorsCompanion.insert({required String deviceId, required int seq, this.rowid = const Value.absent()})
    : deviceId = Value(deviceId),
      seq = Value(seq);
  static Insertable<SyncCursor> custom({
    Expression<String>? deviceId,
    Expression<int>? seq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (seq != null) 'seq': seq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursorsCompanion copyWith({Value<String>? deviceId, Value<int>? seq, Value<int>? rowid}) {
    return SyncCursorsCompanion(
      deviceId: deviceId ?? this.deviceId,
      seq: seq ?? this.seq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('seq: $seq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSettingsTable extends LocalSettings with TableInfo<$LocalSettingsTable, LocalSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(Insertable<LocalSetting> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetting(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSetting extends DataClass implements Insertable<LocalSetting> {
  final String key;
  final String value;
  const LocalSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory LocalSetting.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  LocalSetting copyWith({String? key, String? value}) =>
      LocalSetting(key: key ?? this.key, value: value ?? this.value);
  LocalSetting copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LocalSetting && other.key == this.key && other.value == this.value);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSettingsCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return LocalSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VinSpacesTable vinSpaces = $VinSpacesTable(this);
  late final $VinRoomsTable vinRooms = $VinRoomsTable(this);
  late final $VinPlansTable vinPlans = $VinPlansTable(this);
  late final $VinMediaTable vinMedia = $VinMediaTable(this);
  late final $VinThemesTable vinThemes = $VinThemesTable(this);
  late final $PrefsTable prefs = $PrefsTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $SyncCursorsTable syncCursors = $SyncCursorsTable(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vinSpaces,
    vinRooms,
    vinPlans,
    vinMedia,
    vinThemes,
    prefs,
    outbox,
    syncCursors,
    localSettings,
  ];
}

typedef $$VinSpacesTableCreateCompanionBuilder = VinSpacesCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String name,
  Value<String> kind,
  Value<String> notes,
  required String updated,
  Value<int> rowid,
});
typedef $$VinSpacesTableUpdateCompanionBuilder = VinSpacesCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> name,
  Value<String> kind,
  Value<String> notes,
  Value<String> updated,
  Value<int> rowid,
});

class $$VinSpacesTableFilterComposer extends Composer<_$AppDatabase, $VinSpacesTable> {
  $$VinSpacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => ColumnFilters(column));
}

class $$VinSpacesTableOrderingComposer extends Composer<_$AppDatabase, $VinSpacesTable> {
  $$VinSpacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => ColumnOrderings(column));
}

class $$VinSpacesTableAnnotationComposer extends Composer<_$AppDatabase, $VinSpacesTable> {
  $$VinSpacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc => $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get notes => $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);
}

class $$VinSpacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VinSpacesTable,
          SpaceRow,
          $$VinSpacesTableFilterComposer,
          $$VinSpacesTableOrderingComposer,
          $$VinSpacesTableAnnotationComposer,
          $$VinSpacesTableCreateCompanionBuilder,
          $$VinSpacesTableUpdateCompanionBuilder,
          (SpaceRow, BaseReferences<_$AppDatabase, $VinSpacesTable, SpaceRow>),
          SpaceRow,
          PrefetchHooks Function()
        > {
  $$VinSpacesTableTableManager(_$AppDatabase db, $VinSpacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$VinSpacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$VinSpacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$VinSpacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> updated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VinSpacesCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                kind: kind,
                notes: notes,
                updated: updated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String name,
                Value<String> kind = const Value.absent(),
                Value<String> notes = const Value.absent(),
                required String updated,
                Value<int> rowid = const Value.absent(),
              }) => VinSpacesCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                kind: kind,
                notes: notes,
                updated: updated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VinSpacesTable, SpaceRow>(table),
                  BaseReferences<_$AppDatabase, $VinSpacesTable, SpaceRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VinSpacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VinSpacesTable,
      SpaceRow,
      $$VinSpacesTableFilterComposer,
      $$VinSpacesTableOrderingComposer,
      $$VinSpacesTableAnnotationComposer,
      $$VinSpacesTableCreateCompanionBuilder,
      $$VinSpacesTableUpdateCompanionBuilder,
      (SpaceRow, BaseReferences<_$AppDatabase, $VinSpacesTable, SpaceRow>),
      SpaceRow,
      PrefetchHooks Function()
    >;
typedef $$VinRoomsTableCreateCompanionBuilder = VinRoomsCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String space,
  required String name,
  required String type,
  required String json,
  Value<int> score,
  required String updated,
  Value<int> rowid,
});
typedef $$VinRoomsTableUpdateCompanionBuilder = VinRoomsCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> space,
  Value<String> name,
  Value<String> type,
  Value<String> json,
  Value<int> score,
  Value<String> updated,
  Value<int> rowid,
});

class $$VinRoomsTableFilterComposer extends Composer<_$AppDatabase, $VinRoomsTable> {
  $$VinRoomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get space =>
      $composableBuilder(column: $table.space, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => ColumnFilters(column));
}

class $$VinRoomsTableOrderingComposer extends Composer<_$AppDatabase, $VinRoomsTable> {
  $$VinRoomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get space =>
      $composableBuilder(column: $table.space, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => ColumnOrderings(column));
}

class $$VinRoomsTableAnnotationComposer extends Composer<_$AppDatabase, $VinRoomsTable> {
  $$VinRoomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc => $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get space => $composableBuilder(column: $table.space, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type => $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get json => $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get score => $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);
}

class $$VinRoomsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VinRoomsTable,
          RoomRow,
          $$VinRoomsTableFilterComposer,
          $$VinRoomsTableOrderingComposer,
          $$VinRoomsTableAnnotationComposer,
          $$VinRoomsTableCreateCompanionBuilder,
          $$VinRoomsTableUpdateCompanionBuilder,
          (RoomRow, BaseReferences<_$AppDatabase, $VinRoomsTable, RoomRow>),
          RoomRow,
          PrefetchHooks Function()
        > {
  $$VinRoomsTableTableManager(_$AppDatabase db, $VinRoomsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$VinRoomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$VinRoomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$VinRoomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> space = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<String> updated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VinRoomsCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                space: space,
                name: name,
                type: type,
                json: json,
                score: score,
                updated: updated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String space,
                required String name,
                required String type,
                required String json,
                Value<int> score = const Value.absent(),
                required String updated,
                Value<int> rowid = const Value.absent(),
              }) => VinRoomsCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                space: space,
                name: name,
                type: type,
                json: json,
                score: score,
                updated: updated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VinRoomsTable, RoomRow>(table),
                  BaseReferences<_$AppDatabase, $VinRoomsTable, RoomRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VinRoomsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VinRoomsTable,
      RoomRow,
      $$VinRoomsTableFilterComposer,
      $$VinRoomsTableOrderingComposer,
      $$VinRoomsTableAnnotationComposer,
      $$VinRoomsTableCreateCompanionBuilder,
      $$VinRoomsTableUpdateCompanionBuilder,
      (RoomRow, BaseReferences<_$AppDatabase, $VinRoomsTable, RoomRow>),
      RoomRow,
      PrefetchHooks Function()
    >;
typedef $$VinPlansTableCreateCompanionBuilder = VinPlansCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String room,
  required String json,
  Value<String> done,
  required int scoreBefore,
  required int scoreAfter,
  required String created,
  Value<int> rowid,
});
typedef $$VinPlansTableUpdateCompanionBuilder = VinPlansCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> room,
  Value<String> json,
  Value<String> done,
  Value<int> scoreBefore,
  Value<int> scoreAfter,
  Value<String> created,
  Value<int> rowid,
});

class $$VinPlansTableFilterComposer extends Composer<_$AppDatabase, $VinPlansTable> {
  $$VinPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get done =>
      $composableBuilder(column: $table.done, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scoreBefore =>
      $composableBuilder(column: $table.scoreBefore, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get scoreAfter =>
      $composableBuilder(column: $table.scoreAfter, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get created =>
      $composableBuilder(column: $table.created, builder: (column) => ColumnFilters(column));
}

class $$VinPlansTableOrderingComposer extends Composer<_$AppDatabase, $VinPlansTable> {
  $$VinPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get done =>
      $composableBuilder(column: $table.done, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scoreBefore =>
      $composableBuilder(column: $table.scoreBefore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get scoreAfter =>
      $composableBuilder(column: $table.scoreAfter, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get created =>
      $composableBuilder(column: $table.created, builder: (column) => ColumnOrderings(column));
}

class $$VinPlansTableAnnotationComposer extends Composer<_$AppDatabase, $VinPlansTable> {
  $$VinPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc => $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get room => $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumn<String> get json => $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get done => $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<int> get scoreBefore =>
      $composableBuilder(column: $table.scoreBefore, builder: (column) => column);

  GeneratedColumn<int> get scoreAfter =>
      $composableBuilder(column: $table.scoreAfter, builder: (column) => column);

  GeneratedColumn<String> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);
}

class $$VinPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VinPlansTable,
          PlanRow,
          $$VinPlansTableFilterComposer,
          $$VinPlansTableOrderingComposer,
          $$VinPlansTableAnnotationComposer,
          $$VinPlansTableCreateCompanionBuilder,
          $$VinPlansTableUpdateCompanionBuilder,
          (PlanRow, BaseReferences<_$AppDatabase, $VinPlansTable, PlanRow>),
          PlanRow,
          PrefetchHooks Function()
        > {
  $$VinPlansTableTableManager(_$AppDatabase db, $VinPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$VinPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$VinPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$VinPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> room = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String> done = const Value.absent(),
                Value<int> scoreBefore = const Value.absent(),
                Value<int> scoreAfter = const Value.absent(),
                Value<String> created = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VinPlansCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                room: room,
                json: json,
                done: done,
                scoreBefore: scoreBefore,
                scoreAfter: scoreAfter,
                created: created,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String room,
                required String json,
                Value<String> done = const Value.absent(),
                required int scoreBefore,
                required int scoreAfter,
                required String created,
                Value<int> rowid = const Value.absent(),
              }) => VinPlansCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                room: room,
                json: json,
                done: done,
                scoreBefore: scoreBefore,
                scoreAfter: scoreAfter,
                created: created,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VinPlansTable, PlanRow>(table),
                  BaseReferences<_$AppDatabase, $VinPlansTable, PlanRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VinPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VinPlansTable,
      PlanRow,
      $$VinPlansTableFilterComposer,
      $$VinPlansTableOrderingComposer,
      $$VinPlansTableAnnotationComposer,
      $$VinPlansTableCreateCompanionBuilder,
      $$VinPlansTableUpdateCompanionBuilder,
      (PlanRow, BaseReferences<_$AppDatabase, $VinPlansTable, PlanRow>),
      PlanRow,
      PrefetchHooks Function()
    >;
typedef $$VinMediaTableCreateCompanionBuilder = VinMediaCompanion Function({
  required String id,
  required String room,
  required String path,
  required String kind,
  required String added,
  Value<int> rowid,
});
typedef $$VinMediaTableUpdateCompanionBuilder = VinMediaCompanion Function({
  Value<String> id,
  Value<String> room,
  Value<String> path,
  Value<String> kind,
  Value<String> added,
  Value<int> rowid,
});

class $$VinMediaTableFilterComposer extends Composer<_$AppDatabase, $VinMediaTable> {
  $$VinMediaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get added =>
      $composableBuilder(column: $table.added, builder: (column) => ColumnFilters(column));
}

class $$VinMediaTableOrderingComposer extends Composer<_$AppDatabase, $VinMediaTable> {
  $$VinMediaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get added =>
      $composableBuilder(column: $table.added, builder: (column) => ColumnOrderings(column));
}

class $$VinMediaTableAnnotationComposer extends Composer<_$AppDatabase, $VinMediaTable> {
  $$VinMediaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get room => $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumn<String> get path => $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get added => $composableBuilder(column: $table.added, builder: (column) => column);
}

class $$VinMediaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VinMediaTable,
          MediaRow,
          $$VinMediaTableFilterComposer,
          $$VinMediaTableOrderingComposer,
          $$VinMediaTableAnnotationComposer,
          $$VinMediaTableCreateCompanionBuilder,
          $$VinMediaTableUpdateCompanionBuilder,
          (MediaRow, BaseReferences<_$AppDatabase, $VinMediaTable, MediaRow>),
          MediaRow,
          PrefetchHooks Function()
        > {
  $$VinMediaTableTableManager(_$AppDatabase db, $VinMediaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$VinMediaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$VinMediaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$VinMediaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> room = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> added = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => VinMediaCompanion(id: id, room: room, path: path, kind: kind, added: added, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String room,
                required String path,
                required String kind,
                required String added,
                Value<int> rowid = const Value.absent(),
              }) => VinMediaCompanion.insert(
                id: id,
                room: room,
                path: path,
                kind: kind,
                added: added,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VinMediaTable, MediaRow>(table),
                  BaseReferences<_$AppDatabase, $VinMediaTable, MediaRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VinMediaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VinMediaTable,
      MediaRow,
      $$VinMediaTableFilterComposer,
      $$VinMediaTableOrderingComposer,
      $$VinMediaTableAnnotationComposer,
      $$VinMediaTableCreateCompanionBuilder,
      $$VinMediaTableUpdateCompanionBuilder,
      (MediaRow, BaseReferences<_$AppDatabase, $VinMediaTable, MediaRow>),
      MediaRow,
      PrefetchHooks Function()
    >;
typedef $$VinThemesTableCreateCompanionBuilder = VinThemesCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String name,
  required String json,
  required String updated,
  Value<int> rowid,
});
typedef $$VinThemesTableUpdateCompanionBuilder = VinThemesCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> name,
  Value<String> json,
  Value<String> updated,
  Value<int> rowid,
});

class $$VinThemesTableFilterComposer extends Composer<_$AppDatabase, $VinThemesTable> {
  $$VinThemesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => ColumnFilters(column));
}

class $$VinThemesTableOrderingComposer extends Composer<_$AppDatabase, $VinThemesTable> {
  $$VinThemesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => ColumnOrderings(column));
}

class $$VinThemesTableAnnotationComposer extends Composer<_$AppDatabase, $VinThemesTable> {
  $$VinThemesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc => $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get json => $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);
}

class $$VinThemesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VinThemesTable,
          ThemeRow,
          $$VinThemesTableFilterComposer,
          $$VinThemesTableOrderingComposer,
          $$VinThemesTableAnnotationComposer,
          $$VinThemesTableCreateCompanionBuilder,
          $$VinThemesTableUpdateCompanionBuilder,
          (ThemeRow, BaseReferences<_$AppDatabase, $VinThemesTable, ThemeRow>),
          ThemeRow,
          PrefetchHooks Function()
        > {
  $$VinThemesTableTableManager(_$AppDatabase db, $VinThemesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$VinThemesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$VinThemesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$VinThemesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String> updated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VinThemesCompanion(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                json: json,
                updated: updated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlc = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String name,
                required String json,
                required String updated,
                Value<int> rowid = const Value.absent(),
              }) => VinThemesCompanion.insert(
                id: id,
                hlc: hlc,
                deleted: deleted,
                name: name,
                json: json,
                updated: updated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VinThemesTable, ThemeRow>(table),
                  BaseReferences<_$AppDatabase, $VinThemesTable, ThemeRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VinThemesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VinThemesTable,
      ThemeRow,
      $$VinThemesTableFilterComposer,
      $$VinThemesTableOrderingComposer,
      $$VinThemesTableAnnotationComposer,
      $$VinThemesTableCreateCompanionBuilder,
      $$VinThemesTableUpdateCompanionBuilder,
      (ThemeRow, BaseReferences<_$AppDatabase, $VinThemesTable, ThemeRow>),
      ThemeRow,
      PrefetchHooks Function()
    >;
typedef $$PrefsTableCreateCompanionBuilder = PrefsCompanion Function({
  required String id,
  Value<String> hlc,
  Value<bool> deleted,
  required String value,
  Value<int> rowid,
});
typedef $$PrefsTableUpdateCompanionBuilder = PrefsCompanion Function({
  Value<String> id,
  Value<String> hlc,
  Value<bool> deleted,
  Value<String> value,
  Value<int> rowid,
});

class $$PrefsTableFilterComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$PrefsTableOrderingComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$PrefsTableAnnotationComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc => $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrefsTable,
          Pref,
          $$PrefsTableFilterComposer,
          $$PrefsTableOrderingComposer,
          $$PrefsTableAnnotationComposer,
          $$PrefsTableCreateCompanionBuilder,
          $$PrefsTableUpdateCompanionBuilder,
          (Pref, BaseReferences<_$AppDatabase, $PrefsTable, Pref>),
          Pref,
          PrefetchHooks Function()
        > {
  $$PrefsTableTableManager(_$AppDatabase db, $PrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> hlc = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PrefsCompanion(id: id, hlc: hlc, deleted: deleted, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            Value<String> hlc = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => PrefsCompanion.insert(id: id, hlc: hlc, deleted: deleted, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrefsTable, Pref>(table),
                  BaseReferences<_$AppDatabase, $PrefsTable, Pref>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrefsTable,
      Pref,
      $$PrefsTableFilterComposer,
      $$PrefsTableOrderingComposer,
      $$PrefsTableAnnotationComposer,
      $$PrefsTableCreateCompanionBuilder,
      $$PrefsTableUpdateCompanionBuilder,
      (Pref, BaseReferences<_$AppDatabase, $PrefsTable, Pref>),
      Pref,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  required String entity,
  required String rowId,
  Value<int?> seq,
  Value<int> rowid,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<String> entity,
  Value<String> rowId,
  Value<int?> seq,
  Value<int> rowid,
});

class $$OutboxTableFilterComposer extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => ColumnFilters(column));
}

class $$OutboxTableOrderingComposer extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => ColumnOrderings(column));
}

class $$OutboxTableAnnotationComposer extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get rowId => $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<int> get seq => $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxItem,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxItem, BaseReferences<_$AppDatabase, $OutboxTable, OutboxItem>),
          OutboxItem,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> entity = const Value.absent(),
            Value<String> rowId = const Value.absent(),
            Value<int?> seq = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => OutboxCompanion(entity: entity, rowId: rowId, seq: seq, rowid: rowid),
          createCompanionCallback: ({
            required String entity,
            required String rowId,
            Value<int?> seq = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => OutboxCompanion.insert(entity: entity, rowId: rowId, seq: seq, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxItem>(table),
                  BaseReferences<_$AppDatabase, $OutboxTable, OutboxItem>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxItem,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxItem, BaseReferences<_$AppDatabase, $OutboxTable, OutboxItem>),
      OutboxItem,
      PrefetchHooks Function()
    >;
typedef $$SyncCursorsTableCreateCompanionBuilder = SyncCursorsCompanion Function({
  required String deviceId,
  required int seq,
  Value<int> rowid,
});
typedef $$SyncCursorsTableUpdateCompanionBuilder = SyncCursorsCompanion Function({
  Value<String> deviceId,
  Value<int> seq,
  Value<int> rowid,
});

class $$SyncCursorsTableFilterComposer extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => ColumnFilters(column));
}

class $$SyncCursorsTableOrderingComposer extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => ColumnOrderings(column));
}

class $$SyncCursorsTableAnnotationComposer extends Composer<_$AppDatabase, $SyncCursorsTable> {
  $$SyncCursorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get seq => $composableBuilder(column: $table.seq, builder: (column) => column);
}

class $$SyncCursorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursorsTable,
          SyncCursor,
          $$SyncCursorsTableFilterComposer,
          $$SyncCursorsTableOrderingComposer,
          $$SyncCursorsTableAnnotationComposer,
          $$SyncCursorsTableCreateCompanionBuilder,
          $$SyncCursorsTableUpdateCompanionBuilder,
          (SyncCursor, BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>),
          SyncCursor,
          PrefetchHooks Function()
        > {
  $$SyncCursorsTableTableManager(_$AppDatabase db, $SyncCursorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SyncCursorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SyncCursorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SyncCursorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> deviceId = const Value.absent(),
            Value<int> seq = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncCursorsCompanion(deviceId: deviceId, seq: seq, rowid: rowid),
          createCompanionCallback: ({
            required String deviceId,
            required int seq,
            Value<int> rowid = const Value.absent(),
          }) => SyncCursorsCompanion.insert(deviceId: deviceId, seq: seq, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncCursorsTable, SyncCursor>(table),
                  BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursorsTable,
      SyncCursor,
      $$SyncCursorsTableFilterComposer,
      $$SyncCursorsTableOrderingComposer,
      $$SyncCursorsTableAnnotationComposer,
      $$SyncCursorsTableCreateCompanionBuilder,
      $$SyncCursorsTableUpdateCompanionBuilder,
      (SyncCursor, BaseReferences<_$AppDatabase, $SyncCursorsTable, SyncCursor>),
      SyncCursor,
      PrefetchHooks Function()
    >;
typedef $$LocalSettingsTableCreateCompanionBuilder = LocalSettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$LocalSettingsTableUpdateCompanionBuilder = LocalSettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$LocalSettingsTableFilterComposer extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$LocalSettingsTableOrderingComposer extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$LocalSettingsTableAnnotationComposer extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTable,
          LocalSetting,
          $$LocalSettingsTableFilterComposer,
          $$LocalSettingsTableOrderingComposer,
          $$LocalSettingsTableAnnotationComposer,
          $$LocalSettingsTableCreateCompanionBuilder,
          $$LocalSettingsTableUpdateCompanionBuilder,
          (LocalSetting, BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>),
          LocalSetting,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LocalSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => LocalSettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSettingsTable, LocalSetting>(table),
                  BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTable,
      LocalSetting,
      $$LocalSettingsTableFilterComposer,
      $$LocalSettingsTableOrderingComposer,
      $$LocalSettingsTableAnnotationComposer,
      $$LocalSettingsTableCreateCompanionBuilder,
      $$LocalSettingsTableUpdateCompanionBuilder,
      (LocalSetting, BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>),
      LocalSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VinSpacesTableTableManager get vinSpaces => $$VinSpacesTableTableManager(_db, _db.vinSpaces);
  $$VinRoomsTableTableManager get vinRooms => $$VinRoomsTableTableManager(_db, _db.vinRooms);
  $$VinPlansTableTableManager get vinPlans => $$VinPlansTableTableManager(_db, _db.vinPlans);
  $$VinMediaTableTableManager get vinMedia => $$VinMediaTableTableManager(_db, _db.vinMedia);
  $$VinThemesTableTableManager get vinThemes => $$VinThemesTableTableManager(_db, _db.vinThemes);
  $$PrefsTableTableManager get prefs => $$PrefsTableTableManager(_db, _db.prefs);
  $$OutboxTableTableManager get outbox => $$OutboxTableTableManager(_db, _db.outbox);
  $$SyncCursorsTableTableManager get syncCursors => $$SyncCursorsTableTableManager(_db, _db.syncCursors);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
}
