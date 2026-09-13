// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PlayersTable extends Players with TableInfo<$PlayersTable, Player> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jerseyNumberMeta = const VerificationMeta(
    'jerseyNumber',
  );
  @override
  late final GeneratedColumn<int> jerseyNumber = GeneratedColumn<int>(
    'jersey_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _battingStyleMeta = const VerificationMeta(
    'battingStyle',
  );
  @override
  late final GeneratedColumn<int> battingStyle = GeneratedColumn<int>(
    'batting_style',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bowlingStyleMeta = const VerificationMeta(
    'bowlingStyle',
  );
  @override
  late final GeneratedColumn<int> bowlingStyle = GeneratedColumn<int>(
    'bowling_style',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    displayName,
    photoPath,
    jerseyNumber,
    battingStyle,
    bowlingStyle,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(
    Insertable<Player> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('jersey_number')) {
      context.handle(
        _jerseyNumberMeta,
        jerseyNumber.isAcceptableOrUnknown(
          data['jersey_number']!,
          _jerseyNumberMeta,
        ),
      );
    }
    if (data.containsKey('batting_style')) {
      context.handle(
        _battingStyleMeta,
        battingStyle.isAcceptableOrUnknown(
          data['batting_style']!,
          _battingStyleMeta,
        ),
      );
    }
    if (data.containsKey('bowling_style')) {
      context.handle(
        _bowlingStyleMeta,
        bowlingStyle.isAcceptableOrUnknown(
          data['bowling_style']!,
          _bowlingStyleMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Player map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Player(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      jerseyNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jersey_number'],
      ),
      battingStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}batting_style'],
      )!,
      bowlingStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bowling_style'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }
}

class Player extends DataClass implements Insertable<Player> {
  final int id;
  final String name;
  final String displayName;
  final String? photoPath;
  final int? jerseyNumber;
  final int battingStyle;
  final int bowlingStyle;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Player({
    required this.id,
    required this.name,
    required this.displayName,
    this.photoPath,
    this.jerseyNumber,
    required this.battingStyle,
    required this.bowlingStyle,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || jerseyNumber != null) {
      map['jersey_number'] = Variable<int>(jerseyNumber);
    }
    map['batting_style'] = Variable<int>(battingStyle);
    map['bowling_style'] = Variable<int>(bowlingStyle);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      id: Value(id),
      name: Value(name),
      displayName: Value(displayName),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      jerseyNumber: jerseyNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(jerseyNumber),
      battingStyle: Value(battingStyle),
      bowlingStyle: Value(bowlingStyle),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Player.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Player(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      jerseyNumber: serializer.fromJson<int?>(json['jerseyNumber']),
      battingStyle: serializer.fromJson<int>(json['battingStyle']),
      bowlingStyle: serializer.fromJson<int>(json['bowlingStyle']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'photoPath': serializer.toJson<String?>(photoPath),
      'jerseyNumber': serializer.toJson<int?>(jerseyNumber),
      'battingStyle': serializer.toJson<int>(battingStyle),
      'bowlingStyle': serializer.toJson<int>(bowlingStyle),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Player copyWith({
    int? id,
    String? name,
    String? displayName,
    Value<String?> photoPath = const Value.absent(),
    Value<int?> jerseyNumber = const Value.absent(),
    int? battingStyle,
    int? bowlingStyle,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Player(
    id: id ?? this.id,
    name: name ?? this.name,
    displayName: displayName ?? this.displayName,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    jerseyNumber: jerseyNumber.present ? jerseyNumber.value : this.jerseyNumber,
    battingStyle: battingStyle ?? this.battingStyle,
    bowlingStyle: bowlingStyle ?? this.bowlingStyle,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Player copyWithCompanion(PlayersCompanion data) {
    return Player(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      jerseyNumber: data.jerseyNumber.present
          ? data.jerseyNumber.value
          : this.jerseyNumber,
      battingStyle: data.battingStyle.present
          ? data.battingStyle.value
          : this.battingStyle,
      bowlingStyle: data.bowlingStyle.present
          ? data.bowlingStyle.value
          : this.bowlingStyle,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Player(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('photoPath: $photoPath, ')
          ..write('jerseyNumber: $jerseyNumber, ')
          ..write('battingStyle: $battingStyle, ')
          ..write('bowlingStyle: $bowlingStyle, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    displayName,
    photoPath,
    jerseyNumber,
    battingStyle,
    bowlingStyle,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Player &&
          other.id == this.id &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.photoPath == this.photoPath &&
          other.jerseyNumber == this.jerseyNumber &&
          other.battingStyle == this.battingStyle &&
          other.bowlingStyle == this.bowlingStyle &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlayersCompanion extends UpdateCompanion<Player> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> displayName;
  final Value<String?> photoPath;
  final Value<int?> jerseyNumber;
  final Value<int> battingStyle;
  final Value<int> bowlingStyle;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.jerseyNumber = const Value.absent(),
    this.battingStyle = const Value.absent(),
    this.bowlingStyle = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PlayersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String displayName,
    this.photoPath = const Value.absent(),
    this.jerseyNumber = const Value.absent(),
    this.battingStyle = const Value.absent(),
    this.bowlingStyle = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       displayName = Value(displayName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Player> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? photoPath,
    Expression<int>? jerseyNumber,
    Expression<int>? battingStyle,
    Expression<int>? bowlingStyle,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (photoPath != null) 'photo_path': photoPath,
      if (jerseyNumber != null) 'jersey_number': jerseyNumber,
      if (battingStyle != null) 'batting_style': battingStyle,
      if (bowlingStyle != null) 'bowling_style': bowlingStyle,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PlayersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? displayName,
    Value<String?>? photoPath,
    Value<int?>? jerseyNumber,
    Value<int>? battingStyle,
    Value<int>? bowlingStyle,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PlayersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      photoPath: photoPath ?? this.photoPath,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      battingStyle: battingStyle ?? this.battingStyle,
      bowlingStyle: bowlingStyle ?? this.bowlingStyle,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (jerseyNumber.present) {
      map['jersey_number'] = Variable<int>(jerseyNumber.value);
    }
    if (battingStyle.present) {
      map['batting_style'] = Variable<int>(battingStyle.value);
    }
    if (bowlingStyle.present) {
      map['bowling_style'] = Variable<int>(bowlingStyle.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('photoPath: $photoPath, ')
          ..write('jerseyNumber: $jerseyNumber, ')
          ..write('battingStyle: $battingStyle, ')
          ..write('bowlingStyle: $bowlingStyle, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TeamsTable extends Teams with TableInfo<$TeamsTable, Team> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _shortNameMeta = const VerificationMeta(
    'shortName',
  );
  @override
  late final GeneratedColumn<String> shortName = GeneratedColumn<String>(
    'short_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logoPathMeta = const VerificationMeta(
    'logoPath',
  );
  @override
  late final GeneratedColumn<String> logoPath = GeneratedColumn<String>(
    'logo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    shortName,
    logoPath,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teams';
  @override
  VerificationContext validateIntegrity(
    Insertable<Team> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('short_name')) {
      context.handle(
        _shortNameMeta,
        shortName.isAcceptableOrUnknown(data['short_name']!, _shortNameMeta),
      );
    } else if (isInserting) {
      context.missing(_shortNameMeta);
    }
    if (data.containsKey('logo_path')) {
      context.handle(
        _logoPathMeta,
        logoPath.isAcceptableOrUnknown(data['logo_path']!, _logoPathMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Team map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Team(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      shortName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_name'],
      )!,
      logoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_path'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TeamsTable createAlias(String alias) {
    return $TeamsTable(attachedDatabase, alias);
  }
}

class Team extends DataClass implements Insertable<Team> {
  final int id;
  final String name;
  final String shortName;
  final String? logoPath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Team({
    required this.id,
    required this.name,
    required this.shortName,
    this.logoPath,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['short_name'] = Variable<String>(shortName);
    if (!nullToAbsent || logoPath != null) {
      map['logo_path'] = Variable<String>(logoPath);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TeamsCompanion toCompanion(bool nullToAbsent) {
    return TeamsCompanion(
      id: Value(id),
      name: Value(name),
      shortName: Value(shortName),
      logoPath: logoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(logoPath),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Team.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Team(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      shortName: serializer.fromJson<String>(json['shortName']),
      logoPath: serializer.fromJson<String?>(json['logoPath']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'shortName': serializer.toJson<String>(shortName),
      'logoPath': serializer.toJson<String?>(logoPath),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Team copyWith({
    int? id,
    String? name,
    String? shortName,
    Value<String?> logoPath = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Team(
    id: id ?? this.id,
    name: name ?? this.name,
    shortName: shortName ?? this.shortName,
    logoPath: logoPath.present ? logoPath.value : this.logoPath,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Team copyWithCompanion(TeamsCompanion data) {
    return Team(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      shortName: data.shortName.present ? data.shortName.value : this.shortName,
      logoPath: data.logoPath.present ? data.logoPath.value : this.logoPath,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Team(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('shortName: $shortName, ')
          ..write('logoPath: $logoPath, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    shortName,
    logoPath,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Team &&
          other.id == this.id &&
          other.name == this.name &&
          other.shortName == this.shortName &&
          other.logoPath == this.logoPath &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TeamsCompanion extends UpdateCompanion<Team> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> shortName;
  final Value<String?> logoPath;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TeamsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.shortName = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TeamsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String shortName,
    this.logoPath = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       shortName = Value(shortName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Team> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? shortName,
    Expression<String>? logoPath,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (shortName != null) 'short_name': shortName,
      if (logoPath != null) 'logo_path': logoPath,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TeamsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? shortName,
    Value<String?>? logoPath,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return TeamsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      logoPath: logoPath ?? this.logoPath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (shortName.present) {
      map['short_name'] = Variable<String>(shortName.value);
    }
    if (logoPath.present) {
      map['logo_path'] = Variable<String>(logoPath.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('shortName: $shortName, ')
          ..write('logoPath: $logoPath, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TeamPlayersTable extends TeamPlayers
    with TableInfo<$TeamPlayersTable, TeamPlayer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamPlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<int> teamId = GeneratedColumn<int>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jerseyNumberMeta = const VerificationMeta(
    'jerseyNumber',
  );
  @override
  late final GeneratedColumn<int> jerseyNumber = GeneratedColumn<int>(
    'jersey_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    teamId,
    playerId,
    jerseyNumber,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'team_players';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeamPlayer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('jersey_number')) {
      context.handle(
        _jerseyNumberMeta,
        jerseyNumber.isAcceptableOrUnknown(
          data['jersey_number']!,
          _jerseyNumberMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {teamId, playerId},
  ];
  @override
  TeamPlayer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeamPlayer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      jerseyNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jersey_number'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TeamPlayersTable createAlias(String alias) {
    return $TeamPlayersTable(attachedDatabase, alias);
  }
}

class TeamPlayer extends DataClass implements Insertable<TeamPlayer> {
  final int id;
  final int teamId;
  final int playerId;
  final int? jerseyNumber;
  final bool isActive;
  final DateTime createdAt;
  const TeamPlayer({
    required this.id,
    required this.teamId,
    required this.playerId,
    this.jerseyNumber,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['team_id'] = Variable<int>(teamId);
    map['player_id'] = Variable<int>(playerId);
    if (!nullToAbsent || jerseyNumber != null) {
      map['jersey_number'] = Variable<int>(jerseyNumber);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TeamPlayersCompanion toCompanion(bool nullToAbsent) {
    return TeamPlayersCompanion(
      id: Value(id),
      teamId: Value(teamId),
      playerId: Value(playerId),
      jerseyNumber: jerseyNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(jerseyNumber),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory TeamPlayer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeamPlayer(
      id: serializer.fromJson<int>(json['id']),
      teamId: serializer.fromJson<int>(json['teamId']),
      playerId: serializer.fromJson<int>(json['playerId']),
      jerseyNumber: serializer.fromJson<int?>(json['jerseyNumber']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'teamId': serializer.toJson<int>(teamId),
      'playerId': serializer.toJson<int>(playerId),
      'jerseyNumber': serializer.toJson<int?>(jerseyNumber),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TeamPlayer copyWith({
    int? id,
    int? teamId,
    int? playerId,
    Value<int?> jerseyNumber = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
  }) => TeamPlayer(
    id: id ?? this.id,
    teamId: teamId ?? this.teamId,
    playerId: playerId ?? this.playerId,
    jerseyNumber: jerseyNumber.present ? jerseyNumber.value : this.jerseyNumber,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  TeamPlayer copyWithCompanion(TeamPlayersCompanion data) {
    return TeamPlayer(
      id: data.id.present ? data.id.value : this.id,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      jerseyNumber: data.jerseyNumber.present
          ? data.jerseyNumber.value
          : this.jerseyNumber,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeamPlayer(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('playerId: $playerId, ')
          ..write('jerseyNumber: $jerseyNumber, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, teamId, playerId, jerseyNumber, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeamPlayer &&
          other.id == this.id &&
          other.teamId == this.teamId &&
          other.playerId == this.playerId &&
          other.jerseyNumber == this.jerseyNumber &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class TeamPlayersCompanion extends UpdateCompanion<TeamPlayer> {
  final Value<int> id;
  final Value<int> teamId;
  final Value<int> playerId;
  final Value<int?> jerseyNumber;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  const TeamPlayersCompanion({
    this.id = const Value.absent(),
    this.teamId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.jerseyNumber = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TeamPlayersCompanion.insert({
    this.id = const Value.absent(),
    required int teamId,
    required int playerId,
    this.jerseyNumber = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
  }) : teamId = Value(teamId),
       playerId = Value(playerId),
       createdAt = Value(createdAt);
  static Insertable<TeamPlayer> custom({
    Expression<int>? id,
    Expression<int>? teamId,
    Expression<int>? playerId,
    Expression<int>? jerseyNumber,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teamId != null) 'team_id': teamId,
      if (playerId != null) 'player_id': playerId,
      if (jerseyNumber != null) 'jersey_number': jerseyNumber,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TeamPlayersCompanion copyWith({
    Value<int>? id,
    Value<int>? teamId,
    Value<int>? playerId,
    Value<int?>? jerseyNumber,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
  }) {
    return TeamPlayersCompanion(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      playerId: playerId ?? this.playerId,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<int>(teamId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (jerseyNumber.present) {
      map['jersey_number'] = Variable<int>(jerseyNumber.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamPlayersCompanion(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('playerId: $playerId, ')
          ..write('jerseyNumber: $jerseyNumber, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TournamentsTable extends Tournaments
    with TableInfo<$TournamentsTable, Tournament> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TournamentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _tournamentTypeMeta = const VerificationMeta(
    'tournamentType',
  );
  @override
  late final GeneratedColumn<int> tournamentType = GeneratedColumn<int>(
    'tournament_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logoPathMeta = const VerificationMeta(
    'logoPath',
  );
  @override
  late final GeneratedColumn<String> logoPath = GeneratedColumn<String>(
    'logo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    tournamentType,
    logoPath,
    startDate,
    endDate,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tournaments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tournament> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('tournament_type')) {
      context.handle(
        _tournamentTypeMeta,
        tournamentType.isAcceptableOrUnknown(
          data['tournament_type']!,
          _tournamentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tournamentTypeMeta);
    }
    if (data.containsKey('logo_path')) {
      context.handle(
        _logoPathMeta,
        logoPath.isAcceptableOrUnknown(data['logo_path']!, _logoPathMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tournament map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tournament(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      tournamentType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tournament_type'],
      )!,
      logoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_path'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TournamentsTable createAlias(String alias) {
    return $TournamentsTable(attachedDatabase, alias);
  }
}

class Tournament extends DataClass implements Insertable<Tournament> {
  final int id;
  final String name;
  final int tournamentType;
  final String? logoPath;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Tournament({
    required this.id,
    required this.name,
    required this.tournamentType,
    this.logoPath,
    this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['tournament_type'] = Variable<int>(tournamentType);
    if (!nullToAbsent || logoPath != null) {
      map['logo_path'] = Variable<String>(logoPath);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TournamentsCompanion toCompanion(bool nullToAbsent) {
    return TournamentsCompanion(
      id: Value(id),
      name: Value(name),
      tournamentType: Value(tournamentType),
      logoPath: logoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(logoPath),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Tournament.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tournament(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      tournamentType: serializer.fromJson<int>(json['tournamentType']),
      logoPath: serializer.fromJson<String?>(json['logoPath']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'tournamentType': serializer.toJson<int>(tournamentType),
      'logoPath': serializer.toJson<String?>(logoPath),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Tournament copyWith({
    int? id,
    String? name,
    int? tournamentType,
    Value<String?> logoPath = const Value.absent(),
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> endDate = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Tournament(
    id: id ?? this.id,
    name: name ?? this.name,
    tournamentType: tournamentType ?? this.tournamentType,
    logoPath: logoPath.present ? logoPath.value : this.logoPath,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Tournament copyWithCompanion(TournamentsCompanion data) {
    return Tournament(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      tournamentType: data.tournamentType.present
          ? data.tournamentType.value
          : this.tournamentType,
      logoPath: data.logoPath.present ? data.logoPath.value : this.logoPath,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tournament(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('tournamentType: $tournamentType, ')
          ..write('logoPath: $logoPath, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    tournamentType,
    logoPath,
    startDate,
    endDate,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tournament &&
          other.id == this.id &&
          other.name == this.name &&
          other.tournamentType == this.tournamentType &&
          other.logoPath == this.logoPath &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TournamentsCompanion extends UpdateCompanion<Tournament> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> tournamentType;
  final Value<String?> logoPath;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TournamentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.tournamentType = const Value.absent(),
    this.logoPath = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TournamentsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int tournamentType,
    this.logoPath = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       tournamentType = Value(tournamentType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Tournament> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? tournamentType,
    Expression<String>? logoPath,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (tournamentType != null) 'tournament_type': tournamentType,
      if (logoPath != null) 'logo_path': logoPath,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TournamentsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? tournamentType,
    Value<String?>? logoPath,
    Value<DateTime?>? startDate,
    Value<DateTime?>? endDate,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return TournamentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      tournamentType: tournamentType ?? this.tournamentType,
      logoPath: logoPath ?? this.logoPath,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (tournamentType.present) {
      map['tournament_type'] = Variable<int>(tournamentType.value);
    }
    if (logoPath.present) {
      map['logo_path'] = Variable<String>(logoPath.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TournamentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('tournamentType: $tournamentType, ')
          ..write('logoPath: $logoPath, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MatchesTable extends Matches with TableInfo<$MatchesTable, Matche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tournamentIdMeta = const VerificationMeta(
    'tournamentId',
  );
  @override
  late final GeneratedColumn<int> tournamentId = GeneratedColumn<int>(
    'tournament_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _venueMeta = const VerificationMeta('venue');
  @override
  late final GeneratedColumn<String> venue = GeneratedColumn<String>(
    'venue',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inningsCountMeta = const VerificationMeta(
    'inningsCount',
  );
  @override
  late final GeneratedColumn<int> inningsCount = GeneratedColumn<int>(
    'innings_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oversPerInningsMeta = const VerificationMeta(
    'oversPerInnings',
  );
  @override
  late final GeneratedColumn<int> oversPerInnings = GeneratedColumn<int>(
    'overs_per_innings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ballsPerOverMeta = const VerificationMeta(
    'ballsPerOver',
  );
  @override
  late final GeneratedColumn<int> ballsPerOver = GeneratedColumn<int>(
    'balls_per_over',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playersPerTeamMeta = const VerificationMeta(
    'playersPerTeam',
  );
  @override
  late final GeneratedColumn<int> playersPerTeam = GeneratedColumn<int>(
    'players_per_team',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _twoBowlerModeMeta = const VerificationMeta(
    'twoBowlerMode',
  );
  @override
  late final GeneratedColumn<bool> twoBowlerMode = GeneratedColumn<bool>(
    'two_bowler_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("two_bowler_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tossWinnerTeamIdMeta = const VerificationMeta(
    'tossWinnerTeamId',
  );
  @override
  late final GeneratedColumn<int> tossWinnerTeamId = GeneratedColumn<int>(
    'toss_winner_team_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tossDecisionMeta = const VerificationMeta(
    'tossDecision',
  );
  @override
  late final GeneratedColumn<int> tossDecision = GeneratedColumn<int>(
    'toss_decision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tournamentId,
    name,
    date,
    venue,
    inningsCount,
    oversPerInnings,
    ballsPerOver,
    playersPerTeam,
    twoBowlerMode,
    tossWinnerTeamId,
    tossDecision,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'matches';
  @override
  VerificationContext validateIntegrity(
    Insertable<Matche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tournament_id')) {
      context.handle(
        _tournamentIdMeta,
        tournamentId.isAcceptableOrUnknown(
          data['tournament_id']!,
          _tournamentIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('venue')) {
      context.handle(
        _venueMeta,
        venue.isAcceptableOrUnknown(data['venue']!, _venueMeta),
      );
    }
    if (data.containsKey('innings_count')) {
      context.handle(
        _inningsCountMeta,
        inningsCount.isAcceptableOrUnknown(
          data['innings_count']!,
          _inningsCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inningsCountMeta);
    }
    if (data.containsKey('overs_per_innings')) {
      context.handle(
        _oversPerInningsMeta,
        oversPerInnings.isAcceptableOrUnknown(
          data['overs_per_innings']!,
          _oversPerInningsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_oversPerInningsMeta);
    }
    if (data.containsKey('balls_per_over')) {
      context.handle(
        _ballsPerOverMeta,
        ballsPerOver.isAcceptableOrUnknown(
          data['balls_per_over']!,
          _ballsPerOverMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ballsPerOverMeta);
    }
    if (data.containsKey('players_per_team')) {
      context.handle(
        _playersPerTeamMeta,
        playersPerTeam.isAcceptableOrUnknown(
          data['players_per_team']!,
          _playersPerTeamMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playersPerTeamMeta);
    }
    if (data.containsKey('two_bowler_mode')) {
      context.handle(
        _twoBowlerModeMeta,
        twoBowlerMode.isAcceptableOrUnknown(
          data['two_bowler_mode']!,
          _twoBowlerModeMeta,
        ),
      );
    }
    if (data.containsKey('toss_winner_team_id')) {
      context.handle(
        _tossWinnerTeamIdMeta,
        tossWinnerTeamId.isAcceptableOrUnknown(
          data['toss_winner_team_id']!,
          _tossWinnerTeamIdMeta,
        ),
      );
    }
    if (data.containsKey('toss_decision')) {
      context.handle(
        _tossDecisionMeta,
        tossDecision.isAcceptableOrUnknown(
          data['toss_decision']!,
          _tossDecisionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Matche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Matche(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tournamentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tournament_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      venue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venue'],
      ),
      inningsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}innings_count'],
      )!,
      oversPerInnings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overs_per_innings'],
      )!,
      ballsPerOver: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balls_per_over'],
      )!,
      playersPerTeam: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}players_per_team'],
      )!,
      twoBowlerMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}two_bowler_mode'],
      )!,
      tossWinnerTeamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}toss_winner_team_id'],
      ),
      tossDecision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}toss_decision'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MatchesTable createAlias(String alias) {
    return $MatchesTable(attachedDatabase, alias);
  }
}

class Matche extends DataClass implements Insertable<Matche> {
  final int id;
  final int? tournamentId;
  final String name;
  final DateTime date;
  final String? venue;
  final int inningsCount;
  final int oversPerInnings;
  final int ballsPerOver;
  final int playersPerTeam;
  final bool twoBowlerMode;
  final int? tossWinnerTeamId;
  final int? tossDecision;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Matche({
    required this.id,
    this.tournamentId,
    required this.name,
    required this.date,
    this.venue,
    required this.inningsCount,
    required this.oversPerInnings,
    required this.ballsPerOver,
    required this.playersPerTeam,
    required this.twoBowlerMode,
    this.tossWinnerTeamId,
    this.tossDecision,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || tournamentId != null) {
      map['tournament_id'] = Variable<int>(tournamentId);
    }
    map['name'] = Variable<String>(name);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || venue != null) {
      map['venue'] = Variable<String>(venue);
    }
    map['innings_count'] = Variable<int>(inningsCount);
    map['overs_per_innings'] = Variable<int>(oversPerInnings);
    map['balls_per_over'] = Variable<int>(ballsPerOver);
    map['players_per_team'] = Variable<int>(playersPerTeam);
    map['two_bowler_mode'] = Variable<bool>(twoBowlerMode);
    if (!nullToAbsent || tossWinnerTeamId != null) {
      map['toss_winner_team_id'] = Variable<int>(tossWinnerTeamId);
    }
    if (!nullToAbsent || tossDecision != null) {
      map['toss_decision'] = Variable<int>(tossDecision);
    }
    map['status'] = Variable<int>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MatchesCompanion toCompanion(bool nullToAbsent) {
    return MatchesCompanion(
      id: Value(id),
      tournamentId: tournamentId == null && nullToAbsent
          ? const Value.absent()
          : Value(tournamentId),
      name: Value(name),
      date: Value(date),
      venue: venue == null && nullToAbsent
          ? const Value.absent()
          : Value(venue),
      inningsCount: Value(inningsCount),
      oversPerInnings: Value(oversPerInnings),
      ballsPerOver: Value(ballsPerOver),
      playersPerTeam: Value(playersPerTeam),
      twoBowlerMode: Value(twoBowlerMode),
      tossWinnerTeamId: tossWinnerTeamId == null && nullToAbsent
          ? const Value.absent()
          : Value(tossWinnerTeamId),
      tossDecision: tossDecision == null && nullToAbsent
          ? const Value.absent()
          : Value(tossDecision),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Matche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Matche(
      id: serializer.fromJson<int>(json['id']),
      tournamentId: serializer.fromJson<int?>(json['tournamentId']),
      name: serializer.fromJson<String>(json['name']),
      date: serializer.fromJson<DateTime>(json['date']),
      venue: serializer.fromJson<String?>(json['venue']),
      inningsCount: serializer.fromJson<int>(json['inningsCount']),
      oversPerInnings: serializer.fromJson<int>(json['oversPerInnings']),
      ballsPerOver: serializer.fromJson<int>(json['ballsPerOver']),
      playersPerTeam: serializer.fromJson<int>(json['playersPerTeam']),
      twoBowlerMode: serializer.fromJson<bool>(json['twoBowlerMode']),
      tossWinnerTeamId: serializer.fromJson<int?>(json['tossWinnerTeamId']),
      tossDecision: serializer.fromJson<int?>(json['tossDecision']),
      status: serializer.fromJson<int>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tournamentId': serializer.toJson<int?>(tournamentId),
      'name': serializer.toJson<String>(name),
      'date': serializer.toJson<DateTime>(date),
      'venue': serializer.toJson<String?>(venue),
      'inningsCount': serializer.toJson<int>(inningsCount),
      'oversPerInnings': serializer.toJson<int>(oversPerInnings),
      'ballsPerOver': serializer.toJson<int>(ballsPerOver),
      'playersPerTeam': serializer.toJson<int>(playersPerTeam),
      'twoBowlerMode': serializer.toJson<bool>(twoBowlerMode),
      'tossWinnerTeamId': serializer.toJson<int?>(tossWinnerTeamId),
      'tossDecision': serializer.toJson<int?>(tossDecision),
      'status': serializer.toJson<int>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Matche copyWith({
    int? id,
    Value<int?> tournamentId = const Value.absent(),
    String? name,
    DateTime? date,
    Value<String?> venue = const Value.absent(),
    int? inningsCount,
    int? oversPerInnings,
    int? ballsPerOver,
    int? playersPerTeam,
    bool? twoBowlerMode,
    Value<int?> tossWinnerTeamId = const Value.absent(),
    Value<int?> tossDecision = const Value.absent(),
    int? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Matche(
    id: id ?? this.id,
    tournamentId: tournamentId.present ? tournamentId.value : this.tournamentId,
    name: name ?? this.name,
    date: date ?? this.date,
    venue: venue.present ? venue.value : this.venue,
    inningsCount: inningsCount ?? this.inningsCount,
    oversPerInnings: oversPerInnings ?? this.oversPerInnings,
    ballsPerOver: ballsPerOver ?? this.ballsPerOver,
    playersPerTeam: playersPerTeam ?? this.playersPerTeam,
    twoBowlerMode: twoBowlerMode ?? this.twoBowlerMode,
    tossWinnerTeamId: tossWinnerTeamId.present
        ? tossWinnerTeamId.value
        : this.tossWinnerTeamId,
    tossDecision: tossDecision.present ? tossDecision.value : this.tossDecision,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Matche copyWithCompanion(MatchesCompanion data) {
    return Matche(
      id: data.id.present ? data.id.value : this.id,
      tournamentId: data.tournamentId.present
          ? data.tournamentId.value
          : this.tournamentId,
      name: data.name.present ? data.name.value : this.name,
      date: data.date.present ? data.date.value : this.date,
      venue: data.venue.present ? data.venue.value : this.venue,
      inningsCount: data.inningsCount.present
          ? data.inningsCount.value
          : this.inningsCount,
      oversPerInnings: data.oversPerInnings.present
          ? data.oversPerInnings.value
          : this.oversPerInnings,
      ballsPerOver: data.ballsPerOver.present
          ? data.ballsPerOver.value
          : this.ballsPerOver,
      playersPerTeam: data.playersPerTeam.present
          ? data.playersPerTeam.value
          : this.playersPerTeam,
      twoBowlerMode: data.twoBowlerMode.present
          ? data.twoBowlerMode.value
          : this.twoBowlerMode,
      tossWinnerTeamId: data.tossWinnerTeamId.present
          ? data.tossWinnerTeamId.value
          : this.tossWinnerTeamId,
      tossDecision: data.tossDecision.present
          ? data.tossDecision.value
          : this.tossDecision,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Matche(')
          ..write('id: $id, ')
          ..write('tournamentId: $tournamentId, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('venue: $venue, ')
          ..write('inningsCount: $inningsCount, ')
          ..write('oversPerInnings: $oversPerInnings, ')
          ..write('ballsPerOver: $ballsPerOver, ')
          ..write('playersPerTeam: $playersPerTeam, ')
          ..write('twoBowlerMode: $twoBowlerMode, ')
          ..write('tossWinnerTeamId: $tossWinnerTeamId, ')
          ..write('tossDecision: $tossDecision, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tournamentId,
    name,
    date,
    venue,
    inningsCount,
    oversPerInnings,
    ballsPerOver,
    playersPerTeam,
    twoBowlerMode,
    tossWinnerTeamId,
    tossDecision,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Matche &&
          other.id == this.id &&
          other.tournamentId == this.tournamentId &&
          other.name == this.name &&
          other.date == this.date &&
          other.venue == this.venue &&
          other.inningsCount == this.inningsCount &&
          other.oversPerInnings == this.oversPerInnings &&
          other.ballsPerOver == this.ballsPerOver &&
          other.playersPerTeam == this.playersPerTeam &&
          other.twoBowlerMode == this.twoBowlerMode &&
          other.tossWinnerTeamId == this.tossWinnerTeamId &&
          other.tossDecision == this.tossDecision &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MatchesCompanion extends UpdateCompanion<Matche> {
  final Value<int> id;
  final Value<int?> tournamentId;
  final Value<String> name;
  final Value<DateTime> date;
  final Value<String?> venue;
  final Value<int> inningsCount;
  final Value<int> oversPerInnings;
  final Value<int> ballsPerOver;
  final Value<int> playersPerTeam;
  final Value<bool> twoBowlerMode;
  final Value<int?> tossWinnerTeamId;
  final Value<int?> tossDecision;
  final Value<int> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MatchesCompanion({
    this.id = const Value.absent(),
    this.tournamentId = const Value.absent(),
    this.name = const Value.absent(),
    this.date = const Value.absent(),
    this.venue = const Value.absent(),
    this.inningsCount = const Value.absent(),
    this.oversPerInnings = const Value.absent(),
    this.ballsPerOver = const Value.absent(),
    this.playersPerTeam = const Value.absent(),
    this.twoBowlerMode = const Value.absent(),
    this.tossWinnerTeamId = const Value.absent(),
    this.tossDecision = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MatchesCompanion.insert({
    this.id = const Value.absent(),
    this.tournamentId = const Value.absent(),
    required String name,
    required DateTime date,
    this.venue = const Value.absent(),
    required int inningsCount,
    required int oversPerInnings,
    required int ballsPerOver,
    required int playersPerTeam,
    this.twoBowlerMode = const Value.absent(),
    this.tossWinnerTeamId = const Value.absent(),
    this.tossDecision = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       date = Value(date),
       inningsCount = Value(inningsCount),
       oversPerInnings = Value(oversPerInnings),
       ballsPerOver = Value(ballsPerOver),
       playersPerTeam = Value(playersPerTeam),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Matche> custom({
    Expression<int>? id,
    Expression<int>? tournamentId,
    Expression<String>? name,
    Expression<DateTime>? date,
    Expression<String>? venue,
    Expression<int>? inningsCount,
    Expression<int>? oversPerInnings,
    Expression<int>? ballsPerOver,
    Expression<int>? playersPerTeam,
    Expression<bool>? twoBowlerMode,
    Expression<int>? tossWinnerTeamId,
    Expression<int>? tossDecision,
    Expression<int>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tournamentId != null) 'tournament_id': tournamentId,
      if (name != null) 'name': name,
      if (date != null) 'date': date,
      if (venue != null) 'venue': venue,
      if (inningsCount != null) 'innings_count': inningsCount,
      if (oversPerInnings != null) 'overs_per_innings': oversPerInnings,
      if (ballsPerOver != null) 'balls_per_over': ballsPerOver,
      if (playersPerTeam != null) 'players_per_team': playersPerTeam,
      if (twoBowlerMode != null) 'two_bowler_mode': twoBowlerMode,
      if (tossWinnerTeamId != null) 'toss_winner_team_id': tossWinnerTeamId,
      if (tossDecision != null) 'toss_decision': tossDecision,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MatchesCompanion copyWith({
    Value<int>? id,
    Value<int?>? tournamentId,
    Value<String>? name,
    Value<DateTime>? date,
    Value<String?>? venue,
    Value<int>? inningsCount,
    Value<int>? oversPerInnings,
    Value<int>? ballsPerOver,
    Value<int>? playersPerTeam,
    Value<bool>? twoBowlerMode,
    Value<int?>? tossWinnerTeamId,
    Value<int?>? tossDecision,
    Value<int>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return MatchesCompanion(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      date: date ?? this.date,
      venue: venue ?? this.venue,
      inningsCount: inningsCount ?? this.inningsCount,
      oversPerInnings: oversPerInnings ?? this.oversPerInnings,
      ballsPerOver: ballsPerOver ?? this.ballsPerOver,
      playersPerTeam: playersPerTeam ?? this.playersPerTeam,
      twoBowlerMode: twoBowlerMode ?? this.twoBowlerMode,
      tossWinnerTeamId: tossWinnerTeamId ?? this.tossWinnerTeamId,
      tossDecision: tossDecision ?? this.tossDecision,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tournamentId.present) {
      map['tournament_id'] = Variable<int>(tournamentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (venue.present) {
      map['venue'] = Variable<String>(venue.value);
    }
    if (inningsCount.present) {
      map['innings_count'] = Variable<int>(inningsCount.value);
    }
    if (oversPerInnings.present) {
      map['overs_per_innings'] = Variable<int>(oversPerInnings.value);
    }
    if (ballsPerOver.present) {
      map['balls_per_over'] = Variable<int>(ballsPerOver.value);
    }
    if (playersPerTeam.present) {
      map['players_per_team'] = Variable<int>(playersPerTeam.value);
    }
    if (twoBowlerMode.present) {
      map['two_bowler_mode'] = Variable<bool>(twoBowlerMode.value);
    }
    if (tossWinnerTeamId.present) {
      map['toss_winner_team_id'] = Variable<int>(tossWinnerTeamId.value);
    }
    if (tossDecision.present) {
      map['toss_decision'] = Variable<int>(tossDecision.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchesCompanion(')
          ..write('id: $id, ')
          ..write('tournamentId: $tournamentId, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('venue: $venue, ')
          ..write('inningsCount: $inningsCount, ')
          ..write('oversPerInnings: $oversPerInnings, ')
          ..write('ballsPerOver: $ballsPerOver, ')
          ..write('playersPerTeam: $playersPerTeam, ')
          ..write('twoBowlerMode: $twoBowlerMode, ')
          ..write('tossWinnerTeamId: $tossWinnerTeamId, ')
          ..write('tossDecision: $tossDecision, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MatchTeamsTable extends MatchTeams
    with TableInfo<$MatchTeamsTable, MatchTeam> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchTeamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<int> matchId = GeneratedColumn<int>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<int> teamId = GeneratedColumn<int>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<int> slot = GeneratedColumn<int>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, matchId, teamId, slot];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'match_teams';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatchTeam> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {matchId, slot},
    {matchId, teamId},
  ];
  @override
  MatchTeam map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatchTeam(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}match_id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_id'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slot'],
      )!,
    );
  }

  @override
  $MatchTeamsTable createAlias(String alias) {
    return $MatchTeamsTable(attachedDatabase, alias);
  }
}

class MatchTeam extends DataClass implements Insertable<MatchTeam> {
  final int id;
  final int matchId;
  final int teamId;
  final int slot;
  const MatchTeam({
    required this.id,
    required this.matchId,
    required this.teamId,
    required this.slot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['match_id'] = Variable<int>(matchId);
    map['team_id'] = Variable<int>(teamId);
    map['slot'] = Variable<int>(slot);
    return map;
  }

  MatchTeamsCompanion toCompanion(bool nullToAbsent) {
    return MatchTeamsCompanion(
      id: Value(id),
      matchId: Value(matchId),
      teamId: Value(teamId),
      slot: Value(slot),
    );
  }

  factory MatchTeam.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatchTeam(
      id: serializer.fromJson<int>(json['id']),
      matchId: serializer.fromJson<int>(json['matchId']),
      teamId: serializer.fromJson<int>(json['teamId']),
      slot: serializer.fromJson<int>(json['slot']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'matchId': serializer.toJson<int>(matchId),
      'teamId': serializer.toJson<int>(teamId),
      'slot': serializer.toJson<int>(slot),
    };
  }

  MatchTeam copyWith({int? id, int? matchId, int? teamId, int? slot}) =>
      MatchTeam(
        id: id ?? this.id,
        matchId: matchId ?? this.matchId,
        teamId: teamId ?? this.teamId,
        slot: slot ?? this.slot,
      );
  MatchTeam copyWithCompanion(MatchTeamsCompanion data) {
    return MatchTeam(
      id: data.id.present ? data.id.value : this.id,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      slot: data.slot.present ? data.slot.value : this.slot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatchTeam(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('teamId: $teamId, ')
          ..write('slot: $slot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, matchId, teamId, slot);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatchTeam &&
          other.id == this.id &&
          other.matchId == this.matchId &&
          other.teamId == this.teamId &&
          other.slot == this.slot);
}

class MatchTeamsCompanion extends UpdateCompanion<MatchTeam> {
  final Value<int> id;
  final Value<int> matchId;
  final Value<int> teamId;
  final Value<int> slot;
  const MatchTeamsCompanion({
    this.id = const Value.absent(),
    this.matchId = const Value.absent(),
    this.teamId = const Value.absent(),
    this.slot = const Value.absent(),
  });
  MatchTeamsCompanion.insert({
    this.id = const Value.absent(),
    required int matchId,
    required int teamId,
    required int slot,
  }) : matchId = Value(matchId),
       teamId = Value(teamId),
       slot = Value(slot);
  static Insertable<MatchTeam> custom({
    Expression<int>? id,
    Expression<int>? matchId,
    Expression<int>? teamId,
    Expression<int>? slot,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchId != null) 'match_id': matchId,
      if (teamId != null) 'team_id': teamId,
      if (slot != null) 'slot': slot,
    });
  }

  MatchTeamsCompanion copyWith({
    Value<int>? id,
    Value<int>? matchId,
    Value<int>? teamId,
    Value<int>? slot,
  }) {
    return MatchTeamsCompanion(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      teamId: teamId ?? this.teamId,
      slot: slot ?? this.slot,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<int>(matchId.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<int>(teamId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<int>(slot.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchTeamsCompanion(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('teamId: $teamId, ')
          ..write('slot: $slot')
          ..write(')'))
        .toString();
  }
}

class $MatchPlayersTable extends MatchPlayers
    with TableInfo<$MatchPlayersTable, MatchPlayer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchPlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<int> matchId = GeneratedColumn<int>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<int> teamId = GeneratedColumn<int>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<int> playerId = GeneratedColumn<int>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPlayingMeta = const VerificationMeta(
    'isPlaying',
  );
  @override
  late final GeneratedColumn<bool> isPlaying = GeneratedColumn<bool>(
    'is_playing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_playing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _battingOrderMeta = const VerificationMeta(
    'battingOrder',
  );
  @override
  late final GeneratedColumn<int> battingOrder = GeneratedColumn<int>(
    'batting_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    matchId,
    teamId,
    playerId,
    isPlaying,
    battingOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'match_players';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatchPlayer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('is_playing')) {
      context.handle(
        _isPlayingMeta,
        isPlaying.isAcceptableOrUnknown(data['is_playing']!, _isPlayingMeta),
      );
    }
    if (data.containsKey('batting_order')) {
      context.handle(
        _battingOrderMeta,
        battingOrder.isAcceptableOrUnknown(
          data['batting_order']!,
          _battingOrderMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {matchId, playerId},
  ];
  @override
  MatchPlayer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatchPlayer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}match_id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}team_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}player_id'],
      )!,
      isPlaying: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_playing'],
      )!,
      battingOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}batting_order'],
      ),
    );
  }

  @override
  $MatchPlayersTable createAlias(String alias) {
    return $MatchPlayersTable(attachedDatabase, alias);
  }
}

class MatchPlayer extends DataClass implements Insertable<MatchPlayer> {
  final int id;
  final int matchId;
  final int teamId;
  final int playerId;
  final bool isPlaying;
  final int? battingOrder;
  const MatchPlayer({
    required this.id,
    required this.matchId,
    required this.teamId,
    required this.playerId,
    required this.isPlaying,
    this.battingOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['match_id'] = Variable<int>(matchId);
    map['team_id'] = Variable<int>(teamId);
    map['player_id'] = Variable<int>(playerId);
    map['is_playing'] = Variable<bool>(isPlaying);
    if (!nullToAbsent || battingOrder != null) {
      map['batting_order'] = Variable<int>(battingOrder);
    }
    return map;
  }

  MatchPlayersCompanion toCompanion(bool nullToAbsent) {
    return MatchPlayersCompanion(
      id: Value(id),
      matchId: Value(matchId),
      teamId: Value(teamId),
      playerId: Value(playerId),
      isPlaying: Value(isPlaying),
      battingOrder: battingOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(battingOrder),
    );
  }

  factory MatchPlayer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatchPlayer(
      id: serializer.fromJson<int>(json['id']),
      matchId: serializer.fromJson<int>(json['matchId']),
      teamId: serializer.fromJson<int>(json['teamId']),
      playerId: serializer.fromJson<int>(json['playerId']),
      isPlaying: serializer.fromJson<bool>(json['isPlaying']),
      battingOrder: serializer.fromJson<int?>(json['battingOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'matchId': serializer.toJson<int>(matchId),
      'teamId': serializer.toJson<int>(teamId),
      'playerId': serializer.toJson<int>(playerId),
      'isPlaying': serializer.toJson<bool>(isPlaying),
      'battingOrder': serializer.toJson<int?>(battingOrder),
    };
  }

  MatchPlayer copyWith({
    int? id,
    int? matchId,
    int? teamId,
    int? playerId,
    bool? isPlaying,
    Value<int?> battingOrder = const Value.absent(),
  }) => MatchPlayer(
    id: id ?? this.id,
    matchId: matchId ?? this.matchId,
    teamId: teamId ?? this.teamId,
    playerId: playerId ?? this.playerId,
    isPlaying: isPlaying ?? this.isPlaying,
    battingOrder: battingOrder.present ? battingOrder.value : this.battingOrder,
  );
  MatchPlayer copyWithCompanion(MatchPlayersCompanion data) {
    return MatchPlayer(
      id: data.id.present ? data.id.value : this.id,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      isPlaying: data.isPlaying.present ? data.isPlaying.value : this.isPlaying,
      battingOrder: data.battingOrder.present
          ? data.battingOrder.value
          : this.battingOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatchPlayer(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('teamId: $teamId, ')
          ..write('playerId: $playerId, ')
          ..write('isPlaying: $isPlaying, ')
          ..write('battingOrder: $battingOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, matchId, teamId, playerId, isPlaying, battingOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatchPlayer &&
          other.id == this.id &&
          other.matchId == this.matchId &&
          other.teamId == this.teamId &&
          other.playerId == this.playerId &&
          other.isPlaying == this.isPlaying &&
          other.battingOrder == this.battingOrder);
}

class MatchPlayersCompanion extends UpdateCompanion<MatchPlayer> {
  final Value<int> id;
  final Value<int> matchId;
  final Value<int> teamId;
  final Value<int> playerId;
  final Value<bool> isPlaying;
  final Value<int?> battingOrder;
  const MatchPlayersCompanion({
    this.id = const Value.absent(),
    this.matchId = const Value.absent(),
    this.teamId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.isPlaying = const Value.absent(),
    this.battingOrder = const Value.absent(),
  });
  MatchPlayersCompanion.insert({
    this.id = const Value.absent(),
    required int matchId,
    required int teamId,
    required int playerId,
    this.isPlaying = const Value.absent(),
    this.battingOrder = const Value.absent(),
  }) : matchId = Value(matchId),
       teamId = Value(teamId),
       playerId = Value(playerId);
  static Insertable<MatchPlayer> custom({
    Expression<int>? id,
    Expression<int>? matchId,
    Expression<int>? teamId,
    Expression<int>? playerId,
    Expression<bool>? isPlaying,
    Expression<int>? battingOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchId != null) 'match_id': matchId,
      if (teamId != null) 'team_id': teamId,
      if (playerId != null) 'player_id': playerId,
      if (isPlaying != null) 'is_playing': isPlaying,
      if (battingOrder != null) 'batting_order': battingOrder,
    });
  }

  MatchPlayersCompanion copyWith({
    Value<int>? id,
    Value<int>? matchId,
    Value<int>? teamId,
    Value<int>? playerId,
    Value<bool>? isPlaying,
    Value<int?>? battingOrder,
  }) {
    return MatchPlayersCompanion(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      teamId: teamId ?? this.teamId,
      playerId: playerId ?? this.playerId,
      isPlaying: isPlaying ?? this.isPlaying,
      battingOrder: battingOrder ?? this.battingOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<int>(matchId.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<int>(teamId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<int>(playerId.value);
    }
    if (isPlaying.present) {
      map['is_playing'] = Variable<bool>(isPlaying.value);
    }
    if (battingOrder.present) {
      map['batting_order'] = Variable<int>(battingOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchPlayersCompanion(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('teamId: $teamId, ')
          ..write('playerId: $playerId, ')
          ..write('isPlaying: $isPlaying, ')
          ..write('battingOrder: $battingOrder')
          ..write(')'))
        .toString();
  }
}

class $InningsTable extends Innings with TableInfo<$InningsTable, Inning> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InningsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<int> matchId = GeneratedColumn<int>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inningsNumberMeta = const VerificationMeta(
    'inningsNumber',
  );
  @override
  late final GeneratedColumn<int> inningsNumber = GeneratedColumn<int>(
    'innings_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _battingTeamIdMeta = const VerificationMeta(
    'battingTeamId',
  );
  @override
  late final GeneratedColumn<int> battingTeamId = GeneratedColumn<int>(
    'batting_team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bowlingTeamIdMeta = const VerificationMeta(
    'bowlingTeamId',
  );
  @override
  late final GeneratedColumn<int> bowlingTeamId = GeneratedColumn<int>(
    'bowling_team_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingStrikerIdMeta = const VerificationMeta(
    'openingStrikerId',
  );
  @override
  late final GeneratedColumn<int> openingStrikerId = GeneratedColumn<int>(
    'opening_striker_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingNonStrikerIdMeta =
      const VerificationMeta('openingNonStrikerId');
  @override
  late final GeneratedColumn<int> openingNonStrikerId = GeneratedColumn<int>(
    'opening_non_striker_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openingBowlerIdMeta = const VerificationMeta(
    'openingBowlerId',
  );
  @override
  late final GeneratedColumn<int> openingBowlerId = GeneratedColumn<int>(
    'opening_bowler_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oversPerInningsMeta = const VerificationMeta(
    'oversPerInnings',
  );
  @override
  late final GeneratedColumn<int> oversPerInnings = GeneratedColumn<int>(
    'overs_per_innings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ballsPerOverMeta = const VerificationMeta(
    'ballsPerOver',
  );
  @override
  late final GeneratedColumn<int> ballsPerOver = GeneratedColumn<int>(
    'balls_per_over',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _twoBowlerModeMeta = const VerificationMeta(
    'twoBowlerMode',
  );
  @override
  late final GeneratedColumn<bool> twoBowlerMode = GeneratedColumn<bool>(
    'two_bowler_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("two_bowler_mode" IN (0, 1))',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    matchId,
    inningsNumber,
    battingTeamId,
    bowlingTeamId,
    openingStrikerId,
    openingNonStrikerId,
    openingBowlerId,
    oversPerInnings,
    ballsPerOver,
    twoBowlerMode,
    status,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'innings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Inning> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('innings_number')) {
      context.handle(
        _inningsNumberMeta,
        inningsNumber.isAcceptableOrUnknown(
          data['innings_number']!,
          _inningsNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inningsNumberMeta);
    }
    if (data.containsKey('batting_team_id')) {
      context.handle(
        _battingTeamIdMeta,
        battingTeamId.isAcceptableOrUnknown(
          data['batting_team_id']!,
          _battingTeamIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_battingTeamIdMeta);
    }
    if (data.containsKey('bowling_team_id')) {
      context.handle(
        _bowlingTeamIdMeta,
        bowlingTeamId.isAcceptableOrUnknown(
          data['bowling_team_id']!,
          _bowlingTeamIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bowlingTeamIdMeta);
    }
    if (data.containsKey('opening_striker_id')) {
      context.handle(
        _openingStrikerIdMeta,
        openingStrikerId.isAcceptableOrUnknown(
          data['opening_striker_id']!,
          _openingStrikerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingStrikerIdMeta);
    }
    if (data.containsKey('opening_non_striker_id')) {
      context.handle(
        _openingNonStrikerIdMeta,
        openingNonStrikerId.isAcceptableOrUnknown(
          data['opening_non_striker_id']!,
          _openingNonStrikerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingNonStrikerIdMeta);
    }
    if (data.containsKey('opening_bowler_id')) {
      context.handle(
        _openingBowlerIdMeta,
        openingBowlerId.isAcceptableOrUnknown(
          data['opening_bowler_id']!,
          _openingBowlerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openingBowlerIdMeta);
    }
    if (data.containsKey('overs_per_innings')) {
      context.handle(
        _oversPerInningsMeta,
        oversPerInnings.isAcceptableOrUnknown(
          data['overs_per_innings']!,
          _oversPerInningsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_oversPerInningsMeta);
    }
    if (data.containsKey('balls_per_over')) {
      context.handle(
        _ballsPerOverMeta,
        ballsPerOver.isAcceptableOrUnknown(
          data['balls_per_over']!,
          _ballsPerOverMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ballsPerOverMeta);
    }
    if (data.containsKey('two_bowler_mode')) {
      context.handle(
        _twoBowlerModeMeta,
        twoBowlerMode.isAcceptableOrUnknown(
          data['two_bowler_mode']!,
          _twoBowlerModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_twoBowlerModeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {matchId, inningsNumber},
  ];
  @override
  Inning map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Inning(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}match_id'],
      )!,
      inningsNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}innings_number'],
      )!,
      battingTeamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}batting_team_id'],
      )!,
      bowlingTeamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bowling_team_id'],
      )!,
      openingStrikerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_striker_id'],
      )!,
      openingNonStrikerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_non_striker_id'],
      )!,
      openingBowlerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_bowler_id'],
      )!,
      oversPerInnings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overs_per_innings'],
      )!,
      ballsPerOver: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balls_per_over'],
      )!,
      twoBowlerMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}two_bowler_mode'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $InningsTable createAlias(String alias) {
    return $InningsTable(attachedDatabase, alias);
  }
}

class Inning extends DataClass implements Insertable<Inning> {
  final int id;
  final int matchId;
  final int inningsNumber;
  final int battingTeamId;
  final int bowlingTeamId;
  final int openingStrikerId;
  final int openingNonStrikerId;
  final int openingBowlerId;
  final int oversPerInnings;
  final int ballsPerOver;
  final bool twoBowlerMode;
  final int status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  const Inning({
    required this.id,
    required this.matchId,
    required this.inningsNumber,
    required this.battingTeamId,
    required this.bowlingTeamId,
    required this.openingStrikerId,
    required this.openingNonStrikerId,
    required this.openingBowlerId,
    required this.oversPerInnings,
    required this.ballsPerOver,
    required this.twoBowlerMode,
    required this.status,
    this.startedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['match_id'] = Variable<int>(matchId);
    map['innings_number'] = Variable<int>(inningsNumber);
    map['batting_team_id'] = Variable<int>(battingTeamId);
    map['bowling_team_id'] = Variable<int>(bowlingTeamId);
    map['opening_striker_id'] = Variable<int>(openingStrikerId);
    map['opening_non_striker_id'] = Variable<int>(openingNonStrikerId);
    map['opening_bowler_id'] = Variable<int>(openingBowlerId);
    map['overs_per_innings'] = Variable<int>(oversPerInnings);
    map['balls_per_over'] = Variable<int>(ballsPerOver);
    map['two_bowler_mode'] = Variable<bool>(twoBowlerMode);
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  InningsCompanion toCompanion(bool nullToAbsent) {
    return InningsCompanion(
      id: Value(id),
      matchId: Value(matchId),
      inningsNumber: Value(inningsNumber),
      battingTeamId: Value(battingTeamId),
      bowlingTeamId: Value(bowlingTeamId),
      openingStrikerId: Value(openingStrikerId),
      openingNonStrikerId: Value(openingNonStrikerId),
      openingBowlerId: Value(openingBowlerId),
      oversPerInnings: Value(oversPerInnings),
      ballsPerOver: Value(ballsPerOver),
      twoBowlerMode: Value(twoBowlerMode),
      status: Value(status),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory Inning.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Inning(
      id: serializer.fromJson<int>(json['id']),
      matchId: serializer.fromJson<int>(json['matchId']),
      inningsNumber: serializer.fromJson<int>(json['inningsNumber']),
      battingTeamId: serializer.fromJson<int>(json['battingTeamId']),
      bowlingTeamId: serializer.fromJson<int>(json['bowlingTeamId']),
      openingStrikerId: serializer.fromJson<int>(json['openingStrikerId']),
      openingNonStrikerId: serializer.fromJson<int>(
        json['openingNonStrikerId'],
      ),
      openingBowlerId: serializer.fromJson<int>(json['openingBowlerId']),
      oversPerInnings: serializer.fromJson<int>(json['oversPerInnings']),
      ballsPerOver: serializer.fromJson<int>(json['ballsPerOver']),
      twoBowlerMode: serializer.fromJson<bool>(json['twoBowlerMode']),
      status: serializer.fromJson<int>(json['status']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'matchId': serializer.toJson<int>(matchId),
      'inningsNumber': serializer.toJson<int>(inningsNumber),
      'battingTeamId': serializer.toJson<int>(battingTeamId),
      'bowlingTeamId': serializer.toJson<int>(bowlingTeamId),
      'openingStrikerId': serializer.toJson<int>(openingStrikerId),
      'openingNonStrikerId': serializer.toJson<int>(openingNonStrikerId),
      'openingBowlerId': serializer.toJson<int>(openingBowlerId),
      'oversPerInnings': serializer.toJson<int>(oversPerInnings),
      'ballsPerOver': serializer.toJson<int>(ballsPerOver),
      'twoBowlerMode': serializer.toJson<bool>(twoBowlerMode),
      'status': serializer.toJson<int>(status),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  Inning copyWith({
    int? id,
    int? matchId,
    int? inningsNumber,
    int? battingTeamId,
    int? bowlingTeamId,
    int? openingStrikerId,
    int? openingNonStrikerId,
    int? openingBowlerId,
    int? oversPerInnings,
    int? ballsPerOver,
    bool? twoBowlerMode,
    int? status,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
  }) => Inning(
    id: id ?? this.id,
    matchId: matchId ?? this.matchId,
    inningsNumber: inningsNumber ?? this.inningsNumber,
    battingTeamId: battingTeamId ?? this.battingTeamId,
    bowlingTeamId: bowlingTeamId ?? this.bowlingTeamId,
    openingStrikerId: openingStrikerId ?? this.openingStrikerId,
    openingNonStrikerId: openingNonStrikerId ?? this.openingNonStrikerId,
    openingBowlerId: openingBowlerId ?? this.openingBowlerId,
    oversPerInnings: oversPerInnings ?? this.oversPerInnings,
    ballsPerOver: ballsPerOver ?? this.ballsPerOver,
    twoBowlerMode: twoBowlerMode ?? this.twoBowlerMode,
    status: status ?? this.status,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  Inning copyWithCompanion(InningsCompanion data) {
    return Inning(
      id: data.id.present ? data.id.value : this.id,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      inningsNumber: data.inningsNumber.present
          ? data.inningsNumber.value
          : this.inningsNumber,
      battingTeamId: data.battingTeamId.present
          ? data.battingTeamId.value
          : this.battingTeamId,
      bowlingTeamId: data.bowlingTeamId.present
          ? data.bowlingTeamId.value
          : this.bowlingTeamId,
      openingStrikerId: data.openingStrikerId.present
          ? data.openingStrikerId.value
          : this.openingStrikerId,
      openingNonStrikerId: data.openingNonStrikerId.present
          ? data.openingNonStrikerId.value
          : this.openingNonStrikerId,
      openingBowlerId: data.openingBowlerId.present
          ? data.openingBowlerId.value
          : this.openingBowlerId,
      oversPerInnings: data.oversPerInnings.present
          ? data.oversPerInnings.value
          : this.oversPerInnings,
      ballsPerOver: data.ballsPerOver.present
          ? data.ballsPerOver.value
          : this.ballsPerOver,
      twoBowlerMode: data.twoBowlerMode.present
          ? data.twoBowlerMode.value
          : this.twoBowlerMode,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Inning(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('inningsNumber: $inningsNumber, ')
          ..write('battingTeamId: $battingTeamId, ')
          ..write('bowlingTeamId: $bowlingTeamId, ')
          ..write('openingStrikerId: $openingStrikerId, ')
          ..write('openingNonStrikerId: $openingNonStrikerId, ')
          ..write('openingBowlerId: $openingBowlerId, ')
          ..write('oversPerInnings: $oversPerInnings, ')
          ..write('ballsPerOver: $ballsPerOver, ')
          ..write('twoBowlerMode: $twoBowlerMode, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    matchId,
    inningsNumber,
    battingTeamId,
    bowlingTeamId,
    openingStrikerId,
    openingNonStrikerId,
    openingBowlerId,
    oversPerInnings,
    ballsPerOver,
    twoBowlerMode,
    status,
    startedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Inning &&
          other.id == this.id &&
          other.matchId == this.matchId &&
          other.inningsNumber == this.inningsNumber &&
          other.battingTeamId == this.battingTeamId &&
          other.bowlingTeamId == this.bowlingTeamId &&
          other.openingStrikerId == this.openingStrikerId &&
          other.openingNonStrikerId == this.openingNonStrikerId &&
          other.openingBowlerId == this.openingBowlerId &&
          other.oversPerInnings == this.oversPerInnings &&
          other.ballsPerOver == this.ballsPerOver &&
          other.twoBowlerMode == this.twoBowlerMode &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class InningsCompanion extends UpdateCompanion<Inning> {
  final Value<int> id;
  final Value<int> matchId;
  final Value<int> inningsNumber;
  final Value<int> battingTeamId;
  final Value<int> bowlingTeamId;
  final Value<int> openingStrikerId;
  final Value<int> openingNonStrikerId;
  final Value<int> openingBowlerId;
  final Value<int> oversPerInnings;
  final Value<int> ballsPerOver;
  final Value<bool> twoBowlerMode;
  final Value<int> status;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  const InningsCompanion({
    this.id = const Value.absent(),
    this.matchId = const Value.absent(),
    this.inningsNumber = const Value.absent(),
    this.battingTeamId = const Value.absent(),
    this.bowlingTeamId = const Value.absent(),
    this.openingStrikerId = const Value.absent(),
    this.openingNonStrikerId = const Value.absent(),
    this.openingBowlerId = const Value.absent(),
    this.oversPerInnings = const Value.absent(),
    this.ballsPerOver = const Value.absent(),
    this.twoBowlerMode = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  InningsCompanion.insert({
    this.id = const Value.absent(),
    required int matchId,
    required int inningsNumber,
    required int battingTeamId,
    required int bowlingTeamId,
    required int openingStrikerId,
    required int openingNonStrikerId,
    required int openingBowlerId,
    required int oversPerInnings,
    required int ballsPerOver,
    required bool twoBowlerMode,
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  }) : matchId = Value(matchId),
       inningsNumber = Value(inningsNumber),
       battingTeamId = Value(battingTeamId),
       bowlingTeamId = Value(bowlingTeamId),
       openingStrikerId = Value(openingStrikerId),
       openingNonStrikerId = Value(openingNonStrikerId),
       openingBowlerId = Value(openingBowlerId),
       oversPerInnings = Value(oversPerInnings),
       ballsPerOver = Value(ballsPerOver),
       twoBowlerMode = Value(twoBowlerMode);
  static Insertable<Inning> custom({
    Expression<int>? id,
    Expression<int>? matchId,
    Expression<int>? inningsNumber,
    Expression<int>? battingTeamId,
    Expression<int>? bowlingTeamId,
    Expression<int>? openingStrikerId,
    Expression<int>? openingNonStrikerId,
    Expression<int>? openingBowlerId,
    Expression<int>? oversPerInnings,
    Expression<int>? ballsPerOver,
    Expression<bool>? twoBowlerMode,
    Expression<int>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchId != null) 'match_id': matchId,
      if (inningsNumber != null) 'innings_number': inningsNumber,
      if (battingTeamId != null) 'batting_team_id': battingTeamId,
      if (bowlingTeamId != null) 'bowling_team_id': bowlingTeamId,
      if (openingStrikerId != null) 'opening_striker_id': openingStrikerId,
      if (openingNonStrikerId != null)
        'opening_non_striker_id': openingNonStrikerId,
      if (openingBowlerId != null) 'opening_bowler_id': openingBowlerId,
      if (oversPerInnings != null) 'overs_per_innings': oversPerInnings,
      if (ballsPerOver != null) 'balls_per_over': ballsPerOver,
      if (twoBowlerMode != null) 'two_bowler_mode': twoBowlerMode,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  InningsCompanion copyWith({
    Value<int>? id,
    Value<int>? matchId,
    Value<int>? inningsNumber,
    Value<int>? battingTeamId,
    Value<int>? bowlingTeamId,
    Value<int>? openingStrikerId,
    Value<int>? openingNonStrikerId,
    Value<int>? openingBowlerId,
    Value<int>? oversPerInnings,
    Value<int>? ballsPerOver,
    Value<bool>? twoBowlerMode,
    Value<int>? status,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? completedAt,
  }) {
    return InningsCompanion(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      inningsNumber: inningsNumber ?? this.inningsNumber,
      battingTeamId: battingTeamId ?? this.battingTeamId,
      bowlingTeamId: bowlingTeamId ?? this.bowlingTeamId,
      openingStrikerId: openingStrikerId ?? this.openingStrikerId,
      openingNonStrikerId: openingNonStrikerId ?? this.openingNonStrikerId,
      openingBowlerId: openingBowlerId ?? this.openingBowlerId,
      oversPerInnings: oversPerInnings ?? this.oversPerInnings,
      ballsPerOver: ballsPerOver ?? this.ballsPerOver,
      twoBowlerMode: twoBowlerMode ?? this.twoBowlerMode,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<int>(matchId.value);
    }
    if (inningsNumber.present) {
      map['innings_number'] = Variable<int>(inningsNumber.value);
    }
    if (battingTeamId.present) {
      map['batting_team_id'] = Variable<int>(battingTeamId.value);
    }
    if (bowlingTeamId.present) {
      map['bowling_team_id'] = Variable<int>(bowlingTeamId.value);
    }
    if (openingStrikerId.present) {
      map['opening_striker_id'] = Variable<int>(openingStrikerId.value);
    }
    if (openingNonStrikerId.present) {
      map['opening_non_striker_id'] = Variable<int>(openingNonStrikerId.value);
    }
    if (openingBowlerId.present) {
      map['opening_bowler_id'] = Variable<int>(openingBowlerId.value);
    }
    if (oversPerInnings.present) {
      map['overs_per_innings'] = Variable<int>(oversPerInnings.value);
    }
    if (ballsPerOver.present) {
      map['balls_per_over'] = Variable<int>(ballsPerOver.value);
    }
    if (twoBowlerMode.present) {
      map['two_bowler_mode'] = Variable<bool>(twoBowlerMode.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InningsCompanion(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('inningsNumber: $inningsNumber, ')
          ..write('battingTeamId: $battingTeamId, ')
          ..write('bowlingTeamId: $bowlingTeamId, ')
          ..write('openingStrikerId: $openingStrikerId, ')
          ..write('openingNonStrikerId: $openingNonStrikerId, ')
          ..write('openingBowlerId: $openingBowlerId, ')
          ..write('oversPerInnings: $oversPerInnings, ')
          ..write('ballsPerOver: $ballsPerOver, ')
          ..write('twoBowlerMode: $twoBowlerMode, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PlayersTable players = $PlayersTable(this);
  late final $TeamsTable teams = $TeamsTable(this);
  late final $TeamPlayersTable teamPlayers = $TeamPlayersTable(this);
  late final $TournamentsTable tournaments = $TournamentsTable(this);
  late final $MatchesTable matches = $MatchesTable(this);
  late final $MatchTeamsTable matchTeams = $MatchTeamsTable(this);
  late final $MatchPlayersTable matchPlayers = $MatchPlayersTable(this);
  late final $InningsTable innings = $InningsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    players,
    teams,
    teamPlayers,
    tournaments,
    matches,
    matchTeams,
    matchPlayers,
    innings,
  ];
}

typedef $$PlayersTableCreateCompanionBuilder = PlayersCompanion Function({
  Value<int> id,
  required String name,
  required String displayName,
  Value<String?> photoPath,
  Value<int?> jerseyNumber,
  Value<int> battingStyle,
  Value<int> bowlingStyle,
  Value<bool> isActive,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$PlayersTableUpdateCompanionBuilder = PlayersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> displayName,
  Value<String?> photoPath,
  Value<int?> jerseyNumber,
  Value<int> battingStyle,
  Value<int> bowlingStyle,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$PlayersTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get battingStyle => $composableBuilder(
    column: $table.battingStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bowlingStyle => $composableBuilder(
    column: $table.bowlingStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get battingStyle => $composableBuilder(
    column: $table.battingStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bowlingStyle => $composableBuilder(
    column: $table.bowlingStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<int> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get battingStyle => $composableBuilder(
    column: $table.battingStyle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bowlingStyle => $composableBuilder(
    column: $table.bowlingStyle,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayersTable,
          Player,
          $$PlayersTableFilterComposer,
          $$PlayersTableOrderingComposer,
          $$PlayersTableAnnotationComposer,
          $$PlayersTableCreateCompanionBuilder,
          $$PlayersTableUpdateCompanionBuilder,
          (Player, BaseReferences<_$AppDatabase, $PlayersTable, Player>),
          Player,
          PrefetchHooks Function()
        > {
  $$PlayersTableTableManager(_$AppDatabase db, $PlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<int?> jerseyNumber = const Value.absent(),
                Value<int> battingStyle = const Value.absent(),
                Value<int> bowlingStyle = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlayersCompanion(
                id: id,
                name: name,
                displayName: displayName,
                photoPath: photoPath,
                jerseyNumber: jerseyNumber,
                battingStyle: battingStyle,
                bowlingStyle: bowlingStyle,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String displayName,
                Value<String?> photoPath = const Value.absent(),
                Value<int?> jerseyNumber = const Value.absent(),
                Value<int> battingStyle = const Value.absent(),
                Value<int> bowlingStyle = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => PlayersCompanion.insert(
                id: id,
                name: name,
                displayName: displayName,
                photoPath: photoPath,
                jerseyNumber: jerseyNumber,
                battingStyle: battingStyle,
                bowlingStyle: bowlingStyle,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlayersTable, Player>(table),
                  BaseReferences<_$AppDatabase, $PlayersTable, Player>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayersTable,
      Player,
      $$PlayersTableFilterComposer,
      $$PlayersTableOrderingComposer,
      $$PlayersTableAnnotationComposer,
      $$PlayersTableCreateCompanionBuilder,
      $$PlayersTableUpdateCompanionBuilder,
      (Player, BaseReferences<_$AppDatabase, $PlayersTable, Player>),
      Player,
      PrefetchHooks Function()
    >;
typedef $$TeamsTableCreateCompanionBuilder = TeamsCompanion Function({
  Value<int> id,
  required String name,
  required String shortName,
  Value<String?> logoPath,
  Value<bool> isActive,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$TeamsTableUpdateCompanionBuilder = TeamsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> shortName,
  Value<String?> logoPath,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$TeamsTableFilterComposer extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shortName => $composableBuilder(
    column: $table.shortName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TeamsTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shortName => $composableBuilder(
    column: $table.shortName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TeamsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get shortName =>
      $composableBuilder(column: $table.shortName, builder: (column) => column);

  GeneratedColumn<String> get logoPath =>
      $composableBuilder(column: $table.logoPath, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TeamsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamsTable,
          Team,
          $$TeamsTableFilterComposer,
          $$TeamsTableOrderingComposer,
          $$TeamsTableAnnotationComposer,
          $$TeamsTableCreateCompanionBuilder,
          $$TeamsTableUpdateCompanionBuilder,
          (Team, BaseReferences<_$AppDatabase, $TeamsTable, Team>),
          Team,
          PrefetchHooks Function()
        > {
  $$TeamsTableTableManager(_$AppDatabase db, $TeamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> shortName = const Value.absent(),
                Value<String?> logoPath = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TeamsCompanion(
                id: id,
                name: name,
                shortName: shortName,
                logoPath: logoPath,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String shortName,
                Value<String?> logoPath = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => TeamsCompanion.insert(
                id: id,
                name: name,
                shortName: shortName,
                logoPath: logoPath,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TeamsTable, Team>(table),
                  BaseReferences<_$AppDatabase, $TeamsTable, Team>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TeamsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamsTable,
      Team,
      $$TeamsTableFilterComposer,
      $$TeamsTableOrderingComposer,
      $$TeamsTableAnnotationComposer,
      $$TeamsTableCreateCompanionBuilder,
      $$TeamsTableUpdateCompanionBuilder,
      (Team, BaseReferences<_$AppDatabase, $TeamsTable, Team>),
      Team,
      PrefetchHooks Function()
    >;
typedef $$TeamPlayersTableCreateCompanionBuilder =
    TeamPlayersCompanion Function({
      Value<int> id,
      required int teamId,
      required int playerId,
      Value<int?> jerseyNumber,
      Value<bool> isActive,
      required DateTime createdAt,
    });
typedef $$TeamPlayersTableUpdateCompanionBuilder =
    TeamPlayersCompanion Function({
      Value<int> id,
      Value<int> teamId,
      Value<int> playerId,
      Value<int?> jerseyNumber,
      Value<bool> isActive,
      Value<DateTime> createdAt,
    });

class $$TeamPlayersTableFilterComposer
    extends Composer<_$AppDatabase, $TeamPlayersTable> {
  $$TeamPlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TeamPlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamPlayersTable> {
  $$TeamPlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TeamPlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamPlayersTable> {
  $$TeamPlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<int> get jerseyNumber => $composableBuilder(
    column: $table.jerseyNumber,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TeamPlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamPlayersTable,
          TeamPlayer,
          $$TeamPlayersTableFilterComposer,
          $$TeamPlayersTableOrderingComposer,
          $$TeamPlayersTableAnnotationComposer,
          $$TeamPlayersTableCreateCompanionBuilder,
          $$TeamPlayersTableUpdateCompanionBuilder,
          (
            TeamPlayer,
            BaseReferences<_$AppDatabase, $TeamPlayersTable, TeamPlayer>,
          ),
          TeamPlayer,
          PrefetchHooks Function()
        > {
  $$TeamPlayersTableTableManager(_$AppDatabase db, $TeamPlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamPlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamPlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamPlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> teamId = const Value.absent(),
                Value<int> playerId = const Value.absent(),
                Value<int?> jerseyNumber = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TeamPlayersCompanion(
                id: id,
                teamId: teamId,
                playerId: playerId,
                jerseyNumber: jerseyNumber,
                isActive: isActive,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int teamId,
                required int playerId,
                Value<int?> jerseyNumber = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
              }) => TeamPlayersCompanion.insert(
                id: id,
                teamId: teamId,
                playerId: playerId,
                jerseyNumber: jerseyNumber,
                isActive: isActive,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TeamPlayersTable, TeamPlayer>(table),
                  BaseReferences<_$AppDatabase, $TeamPlayersTable, TeamPlayer>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TeamPlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamPlayersTable,
      TeamPlayer,
      $$TeamPlayersTableFilterComposer,
      $$TeamPlayersTableOrderingComposer,
      $$TeamPlayersTableAnnotationComposer,
      $$TeamPlayersTableCreateCompanionBuilder,
      $$TeamPlayersTableUpdateCompanionBuilder,
      (
        TeamPlayer,
        BaseReferences<_$AppDatabase, $TeamPlayersTable, TeamPlayer>,
      ),
      TeamPlayer,
      PrefetchHooks Function()
    >;
typedef $$TournamentsTableCreateCompanionBuilder =
    TournamentsCompanion Function({
      Value<int> id,
      required String name,
      required int tournamentType,
      Value<String?> logoPath,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<bool> isActive,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$TournamentsTableUpdateCompanionBuilder =
    TournamentsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> tournamentType,
      Value<String?> logoPath,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$TournamentsTableFilterComposer
    extends Composer<_$AppDatabase, $TournamentsTable> {
  $$TournamentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tournamentType => $composableBuilder(
    column: $table.tournamentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TournamentsTableOrderingComposer
    extends Composer<_$AppDatabase, $TournamentsTable> {
  $$TournamentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tournamentType => $composableBuilder(
    column: $table.tournamentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoPath => $composableBuilder(
    column: $table.logoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TournamentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TournamentsTable> {
  $$TournamentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get tournamentType => $composableBuilder(
    column: $table.tournamentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get logoPath =>
      $composableBuilder(column: $table.logoPath, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TournamentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TournamentsTable,
          Tournament,
          $$TournamentsTableFilterComposer,
          $$TournamentsTableOrderingComposer,
          $$TournamentsTableAnnotationComposer,
          $$TournamentsTableCreateCompanionBuilder,
          $$TournamentsTableUpdateCompanionBuilder,
          (
            Tournament,
            BaseReferences<_$AppDatabase, $TournamentsTable, Tournament>,
          ),
          Tournament,
          PrefetchHooks Function()
        > {
  $$TournamentsTableTableManager(_$AppDatabase db, $TournamentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TournamentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TournamentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TournamentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> tournamentType = const Value.absent(),
                Value<String?> logoPath = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => TournamentsCompanion(
                id: id,
                name: name,
                tournamentType: tournamentType,
                logoPath: logoPath,
                startDate: startDate,
                endDate: endDate,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int tournamentType,
                Value<String?> logoPath = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => TournamentsCompanion.insert(
                id: id,
                name: name,
                tournamentType: tournamentType,
                logoPath: logoPath,
                startDate: startDate,
                endDate: endDate,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TournamentsTable, Tournament>(table),
                  BaseReferences<_$AppDatabase, $TournamentsTable, Tournament>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TournamentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TournamentsTable,
      Tournament,
      $$TournamentsTableFilterComposer,
      $$TournamentsTableOrderingComposer,
      $$TournamentsTableAnnotationComposer,
      $$TournamentsTableCreateCompanionBuilder,
      $$TournamentsTableUpdateCompanionBuilder,
      (
        Tournament,
        BaseReferences<_$AppDatabase, $TournamentsTable, Tournament>,
      ),
      Tournament,
      PrefetchHooks Function()
    >;
typedef $$MatchesTableCreateCompanionBuilder = MatchesCompanion Function({
  Value<int> id,
  Value<int?> tournamentId,
  required String name,
  required DateTime date,
  Value<String?> venue,
  required int inningsCount,
  required int oversPerInnings,
  required int ballsPerOver,
  required int playersPerTeam,
  Value<bool> twoBowlerMode,
  Value<int?> tossWinnerTeamId,
  Value<int?> tossDecision,
  Value<int> status,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$MatchesTableUpdateCompanionBuilder = MatchesCompanion Function({
  Value<int> id,
  Value<int?> tournamentId,
  Value<String> name,
  Value<DateTime> date,
  Value<String?> venue,
  Value<int> inningsCount,
  Value<int> oversPerInnings,
  Value<int> ballsPerOver,
  Value<int> playersPerTeam,
  Value<bool> twoBowlerMode,
  Value<int?> tossWinnerTeamId,
  Value<int?> tossDecision,
  Value<int> status,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$MatchesTableFilterComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get venue => $composableBuilder(
    column: $table.venue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inningsCount => $composableBuilder(
    column: $table.inningsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get oversPerInnings => $composableBuilder(
    column: $table.oversPerInnings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ballsPerOver => $composableBuilder(
    column: $table.ballsPerOver,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playersPerTeam => $composableBuilder(
    column: $table.playersPerTeam,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get twoBowlerMode => $composableBuilder(
    column: $table.twoBowlerMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tossWinnerTeamId => $composableBuilder(
    column: $table.tossWinnerTeamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tossDecision => $composableBuilder(
    column: $table.tossDecision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get venue => $composableBuilder(
    column: $table.venue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inningsCount => $composableBuilder(
    column: $table.inningsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get oversPerInnings => $composableBuilder(
    column: $table.oversPerInnings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ballsPerOver => $composableBuilder(
    column: $table.ballsPerOver,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playersPerTeam => $composableBuilder(
    column: $table.playersPerTeam,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get twoBowlerMode => $composableBuilder(
    column: $table.twoBowlerMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tossWinnerTeamId => $composableBuilder(
    column: $table.tossWinnerTeamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tossDecision => $composableBuilder(
    column: $table.tossDecision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tournamentId => $composableBuilder(
    column: $table.tournamentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get venue =>
      $composableBuilder(column: $table.venue, builder: (column) => column);

  GeneratedColumn<int> get inningsCount => $composableBuilder(
    column: $table.inningsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get oversPerInnings => $composableBuilder(
    column: $table.oversPerInnings,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ballsPerOver => $composableBuilder(
    column: $table.ballsPerOver,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playersPerTeam => $composableBuilder(
    column: $table.playersPerTeam,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get twoBowlerMode => $composableBuilder(
    column: $table.twoBowlerMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tossWinnerTeamId => $composableBuilder(
    column: $table.tossWinnerTeamId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tossDecision => $composableBuilder(
    column: $table.tossDecision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatchesTable,
          Matche,
          $$MatchesTableFilterComposer,
          $$MatchesTableOrderingComposer,
          $$MatchesTableAnnotationComposer,
          $$MatchesTableCreateCompanionBuilder,
          $$MatchesTableUpdateCompanionBuilder,
          (Matche, BaseReferences<_$AppDatabase, $MatchesTable, Matche>),
          Matche,
          PrefetchHooks Function()
        > {
  $$MatchesTableTableManager(_$AppDatabase db, $MatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> tournamentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> venue = const Value.absent(),
                Value<int> inningsCount = const Value.absent(),
                Value<int> oversPerInnings = const Value.absent(),
                Value<int> ballsPerOver = const Value.absent(),
                Value<int> playersPerTeam = const Value.absent(),
                Value<bool> twoBowlerMode = const Value.absent(),
                Value<int?> tossWinnerTeamId = const Value.absent(),
                Value<int?> tossDecision = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MatchesCompanion(
                id: id,
                tournamentId: tournamentId,
                name: name,
                date: date,
                venue: venue,
                inningsCount: inningsCount,
                oversPerInnings: oversPerInnings,
                ballsPerOver: ballsPerOver,
                playersPerTeam: playersPerTeam,
                twoBowlerMode: twoBowlerMode,
                tossWinnerTeamId: tossWinnerTeamId,
                tossDecision: tossDecision,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> tournamentId = const Value.absent(),
                required String name,
                required DateTime date,
                Value<String?> venue = const Value.absent(),
                required int inningsCount,
                required int oversPerInnings,
                required int ballsPerOver,
                required int playersPerTeam,
                Value<bool> twoBowlerMode = const Value.absent(),
                Value<int?> tossWinnerTeamId = const Value.absent(),
                Value<int?> tossDecision = const Value.absent(),
                Value<int> status = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => MatchesCompanion.insert(
                id: id,
                tournamentId: tournamentId,
                name: name,
                date: date,
                venue: venue,
                inningsCount: inningsCount,
                oversPerInnings: oversPerInnings,
                ballsPerOver: ballsPerOver,
                playersPerTeam: playersPerTeam,
                twoBowlerMode: twoBowlerMode,
                tossWinnerTeamId: tossWinnerTeamId,
                tossDecision: tossDecision,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MatchesTable, Matche>(table),
                  BaseReferences<_$AppDatabase, $MatchesTable, Matche>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatchesTable,
      Matche,
      $$MatchesTableFilterComposer,
      $$MatchesTableOrderingComposer,
      $$MatchesTableAnnotationComposer,
      $$MatchesTableCreateCompanionBuilder,
      $$MatchesTableUpdateCompanionBuilder,
      (Matche, BaseReferences<_$AppDatabase, $MatchesTable, Matche>),
      Matche,
      PrefetchHooks Function()
    >;
typedef $$MatchTeamsTableCreateCompanionBuilder = MatchTeamsCompanion Function({
  Value<int> id,
  required int matchId,
  required int teamId,
  required int slot,
});
typedef $$MatchTeamsTableUpdateCompanionBuilder = MatchTeamsCompanion Function({
  Value<int> id,
  Value<int> matchId,
  Value<int> teamId,
  Value<int> slot,
});

class $$MatchTeamsTableFilterComposer
    extends Composer<_$AppDatabase, $MatchTeamsTable> {
  $$MatchTeamsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MatchTeamsTableOrderingComposer
    extends Composer<_$AppDatabase, $MatchTeamsTable> {
  $$MatchTeamsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MatchTeamsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatchTeamsTable> {
  $$MatchTeamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<int> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<int> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);
}

class $$MatchTeamsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatchTeamsTable,
          MatchTeam,
          $$MatchTeamsTableFilterComposer,
          $$MatchTeamsTableOrderingComposer,
          $$MatchTeamsTableAnnotationComposer,
          $$MatchTeamsTableCreateCompanionBuilder,
          $$MatchTeamsTableUpdateCompanionBuilder,
          (
            MatchTeam,
            BaseReferences<_$AppDatabase, $MatchTeamsTable, MatchTeam>,
          ),
          MatchTeam,
          PrefetchHooks Function()
        > {
  $$MatchTeamsTableTableManager(_$AppDatabase db, $MatchTeamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatchTeamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatchTeamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatchTeamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> matchId = const Value.absent(),
                Value<int> teamId = const Value.absent(),
                Value<int> slot = const Value.absent(),
              }) => MatchTeamsCompanion(
                id: id,
                matchId: matchId,
                teamId: teamId,
                slot: slot,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int matchId,
                required int teamId,
                required int slot,
              }) => MatchTeamsCompanion.insert(
                id: id,
                matchId: matchId,
                teamId: teamId,
                slot: slot,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MatchTeamsTable, MatchTeam>(table),
                  BaseReferences<_$AppDatabase, $MatchTeamsTable, MatchTeam>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MatchTeamsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatchTeamsTable,
      MatchTeam,
      $$MatchTeamsTableFilterComposer,
      $$MatchTeamsTableOrderingComposer,
      $$MatchTeamsTableAnnotationComposer,
      $$MatchTeamsTableCreateCompanionBuilder,
      $$MatchTeamsTableUpdateCompanionBuilder,
      (MatchTeam, BaseReferences<_$AppDatabase, $MatchTeamsTable, MatchTeam>),
      MatchTeam,
      PrefetchHooks Function()
    >;
typedef $$MatchPlayersTableCreateCompanionBuilder =
    MatchPlayersCompanion Function({
      Value<int> id,
      required int matchId,
      required int teamId,
      required int playerId,
      Value<bool> isPlaying,
      Value<int?> battingOrder,
    });
typedef $$MatchPlayersTableUpdateCompanionBuilder =
    MatchPlayersCompanion Function({
      Value<int> id,
      Value<int> matchId,
      Value<int> teamId,
      Value<int> playerId,
      Value<bool> isPlaying,
      Value<int?> battingOrder,
    });

class $$MatchPlayersTableFilterComposer
    extends Composer<_$AppDatabase, $MatchPlayersTable> {
  $$MatchPlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPlaying => $composableBuilder(
    column: $table.isPlaying,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get battingOrder => $composableBuilder(
    column: $table.battingOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MatchPlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $MatchPlayersTable> {
  $$MatchPlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPlaying => $composableBuilder(
    column: $table.isPlaying,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get battingOrder => $composableBuilder(
    column: $table.battingOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MatchPlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatchPlayersTable> {
  $$MatchPlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<int> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<int> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<bool> get isPlaying =>
      $composableBuilder(column: $table.isPlaying, builder: (column) => column);

  GeneratedColumn<int> get battingOrder => $composableBuilder(
    column: $table.battingOrder,
    builder: (column) => column,
  );
}

class $$MatchPlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatchPlayersTable,
          MatchPlayer,
          $$MatchPlayersTableFilterComposer,
          $$MatchPlayersTableOrderingComposer,
          $$MatchPlayersTableAnnotationComposer,
          $$MatchPlayersTableCreateCompanionBuilder,
          $$MatchPlayersTableUpdateCompanionBuilder,
          (
            MatchPlayer,
            BaseReferences<_$AppDatabase, $MatchPlayersTable, MatchPlayer>,
          ),
          MatchPlayer,
          PrefetchHooks Function()
        > {
  $$MatchPlayersTableTableManager(_$AppDatabase db, $MatchPlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatchPlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatchPlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatchPlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> matchId = const Value.absent(),
                Value<int> teamId = const Value.absent(),
                Value<int> playerId = const Value.absent(),
                Value<bool> isPlaying = const Value.absent(),
                Value<int?> battingOrder = const Value.absent(),
              }) => MatchPlayersCompanion(
                id: id,
                matchId: matchId,
                teamId: teamId,
                playerId: playerId,
                isPlaying: isPlaying,
                battingOrder: battingOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int matchId,
                required int teamId,
                required int playerId,
                Value<bool> isPlaying = const Value.absent(),
                Value<int?> battingOrder = const Value.absent(),
              }) => MatchPlayersCompanion.insert(
                id: id,
                matchId: matchId,
                teamId: teamId,
                playerId: playerId,
                isPlaying: isPlaying,
                battingOrder: battingOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MatchPlayersTable, MatchPlayer>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MatchPlayersTable,
                    MatchPlayer
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MatchPlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatchPlayersTable,
      MatchPlayer,
      $$MatchPlayersTableFilterComposer,
      $$MatchPlayersTableOrderingComposer,
      $$MatchPlayersTableAnnotationComposer,
      $$MatchPlayersTableCreateCompanionBuilder,
      $$MatchPlayersTableUpdateCompanionBuilder,
      (
        MatchPlayer,
        BaseReferences<_$AppDatabase, $MatchPlayersTable, MatchPlayer>,
      ),
      MatchPlayer,
      PrefetchHooks Function()
    >;
typedef $$InningsTableCreateCompanionBuilder = InningsCompanion Function({
  Value<int> id,
  required int matchId,
  required int inningsNumber,
  required int battingTeamId,
  required int bowlingTeamId,
  required int openingStrikerId,
  required int openingNonStrikerId,
  required int openingBowlerId,
  required int oversPerInnings,
  required int ballsPerOver,
  required bool twoBowlerMode,
  Value<int> status,
  Value<DateTime?> startedAt,
  Value<DateTime?> completedAt,
});
typedef $$InningsTableUpdateCompanionBuilder = InningsCompanion Function({
  Value<int> id,
  Value<int> matchId,
  Value<int> inningsNumber,
  Value<int> battingTeamId,
  Value<int> bowlingTeamId,
  Value<int> openingStrikerId,
  Value<int> openingNonStrikerId,
  Value<int> openingBowlerId,
  Value<int> oversPerInnings,
  Value<int> ballsPerOver,
  Value<bool> twoBowlerMode,
  Value<int> status,
  Value<DateTime?> startedAt,
  Value<DateTime?> completedAt,
});

class $$InningsTableFilterComposer
    extends Composer<_$AppDatabase, $InningsTable> {
  $$InningsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inningsNumber => $composableBuilder(
    column: $table.inningsNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get battingTeamId => $composableBuilder(
    column: $table.battingTeamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bowlingTeamId => $composableBuilder(
    column: $table.bowlingTeamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingStrikerId => $composableBuilder(
    column: $table.openingStrikerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingNonStrikerId => $composableBuilder(
    column: $table.openingNonStrikerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingBowlerId => $composableBuilder(
    column: $table.openingBowlerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get oversPerInnings => $composableBuilder(
    column: $table.oversPerInnings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ballsPerOver => $composableBuilder(
    column: $table.ballsPerOver,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get twoBowlerMode => $composableBuilder(
    column: $table.twoBowlerMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InningsTableOrderingComposer
    extends Composer<_$AppDatabase, $InningsTable> {
  $$InningsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get matchId => $composableBuilder(
    column: $table.matchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inningsNumber => $composableBuilder(
    column: $table.inningsNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get battingTeamId => $composableBuilder(
    column: $table.battingTeamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bowlingTeamId => $composableBuilder(
    column: $table.bowlingTeamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingStrikerId => $composableBuilder(
    column: $table.openingStrikerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingNonStrikerId => $composableBuilder(
    column: $table.openingNonStrikerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingBowlerId => $composableBuilder(
    column: $table.openingBowlerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get oversPerInnings => $composableBuilder(
    column: $table.oversPerInnings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ballsPerOver => $composableBuilder(
    column: $table.ballsPerOver,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get twoBowlerMode => $composableBuilder(
    column: $table.twoBowlerMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InningsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InningsTable> {
  $$InningsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<int> get inningsNumber => $composableBuilder(
    column: $table.inningsNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get battingTeamId => $composableBuilder(
    column: $table.battingTeamId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bowlingTeamId => $composableBuilder(
    column: $table.bowlingTeamId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get openingStrikerId => $composableBuilder(
    column: $table.openingStrikerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get openingNonStrikerId => $composableBuilder(
    column: $table.openingNonStrikerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get openingBowlerId => $composableBuilder(
    column: $table.openingBowlerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get oversPerInnings => $composableBuilder(
    column: $table.oversPerInnings,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ballsPerOver => $composableBuilder(
    column: $table.ballsPerOver,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get twoBowlerMode => $composableBuilder(
    column: $table.twoBowlerMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$InningsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InningsTable,
          Inning,
          $$InningsTableFilterComposer,
          $$InningsTableOrderingComposer,
          $$InningsTableAnnotationComposer,
          $$InningsTableCreateCompanionBuilder,
          $$InningsTableUpdateCompanionBuilder,
          (Inning, BaseReferences<_$AppDatabase, $InningsTable, Inning>),
          Inning,
          PrefetchHooks Function()
        > {
  $$InningsTableTableManager(_$AppDatabase db, $InningsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InningsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InningsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InningsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> matchId = const Value.absent(),
                Value<int> inningsNumber = const Value.absent(),
                Value<int> battingTeamId = const Value.absent(),
                Value<int> bowlingTeamId = const Value.absent(),
                Value<int> openingStrikerId = const Value.absent(),
                Value<int> openingNonStrikerId = const Value.absent(),
                Value<int> openingBowlerId = const Value.absent(),
                Value<int> oversPerInnings = const Value.absent(),
                Value<int> ballsPerOver = const Value.absent(),
                Value<bool> twoBowlerMode = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => InningsCompanion(
                id: id,
                matchId: matchId,
                inningsNumber: inningsNumber,
                battingTeamId: battingTeamId,
                bowlingTeamId: bowlingTeamId,
                openingStrikerId: openingStrikerId,
                openingNonStrikerId: openingNonStrikerId,
                openingBowlerId: openingBowlerId,
                oversPerInnings: oversPerInnings,
                ballsPerOver: ballsPerOver,
                twoBowlerMode: twoBowlerMode,
                status: status,
                startedAt: startedAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int matchId,
                required int inningsNumber,
                required int battingTeamId,
                required int bowlingTeamId,
                required int openingStrikerId,
                required int openingNonStrikerId,
                required int openingBowlerId,
                required int oversPerInnings,
                required int ballsPerOver,
                required bool twoBowlerMode,
                Value<int> status = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => InningsCompanion.insert(
                id: id,
                matchId: matchId,
                inningsNumber: inningsNumber,
                battingTeamId: battingTeamId,
                bowlingTeamId: bowlingTeamId,
                openingStrikerId: openingStrikerId,
                openingNonStrikerId: openingNonStrikerId,
                openingBowlerId: openingBowlerId,
                oversPerInnings: oversPerInnings,
                ballsPerOver: ballsPerOver,
                twoBowlerMode: twoBowlerMode,
                status: status,
                startedAt: startedAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InningsTable, Inning>(table),
                  BaseReferences<_$AppDatabase, $InningsTable, Inning>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InningsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InningsTable,
      Inning,
      $$InningsTableFilterComposer,
      $$InningsTableOrderingComposer,
      $$InningsTableAnnotationComposer,
      $$InningsTableCreateCompanionBuilder,
      $$InningsTableUpdateCompanionBuilder,
      (Inning, BaseReferences<_$AppDatabase, $InningsTable, Inning>),
      Inning,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db, _db.teams);
  $$TeamPlayersTableTableManager get teamPlayers =>
      $$TeamPlayersTableTableManager(_db, _db.teamPlayers);
  $$TournamentsTableTableManager get tournaments =>
      $$TournamentsTableTableManager(_db, _db.tournaments);
  $$MatchesTableTableManager get matches =>
      $$MatchesTableTableManager(_db, _db.matches);
  $$MatchTeamsTableTableManager get matchTeams =>
      $$MatchTeamsTableTableManager(_db, _db.matchTeams);
  $$MatchPlayersTableTableManager get matchPlayers =>
      $$MatchPlayersTableTableManager(_db, _db.matchPlayers);
  $$InningsTableTableManager get innings =>
      $$InningsTableTableManager(_db, _db.innings);
}
