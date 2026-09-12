// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $HouseholdMembersTable extends HouseholdMembers
    with TableInfo<$HouseholdMembersTable, HouseholdMemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdMembersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isLocalDeviceOwnerMeta =
      const VerificationMeta('isLocalDeviceOwner');
  @override
  late final GeneratedColumn<bool> isLocalDeviceOwner = GeneratedColumn<bool>(
    'is_local_device_owner',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_local_device_owner" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, displayName, isLocalDeviceOwner];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'household_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<HouseholdMemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('is_local_device_owner')) {
      context.handle(
        _isLocalDeviceOwnerMeta,
        isLocalDeviceOwner.isAcceptableOrUnknown(
          data['is_local_device_owner']!,
          _isLocalDeviceOwnerMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HouseholdMemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HouseholdMemberRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      isLocalDeviceOwner: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_local_device_owner'],
      )!,
    );
  }

  @override
  $HouseholdMembersTable createAlias(String alias) {
    return $HouseholdMembersTable(attachedDatabase, alias);
  }
}

class HouseholdMemberRow extends DataClass
    implements Insertable<HouseholdMemberRow> {
  final int id;
  final String displayName;
  final bool isLocalDeviceOwner;
  const HouseholdMemberRow({
    required this.id,
    required this.displayName,
    required this.isLocalDeviceOwner,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['display_name'] = Variable<String>(displayName);
    map['is_local_device_owner'] = Variable<bool>(isLocalDeviceOwner);
    return map;
  }

  HouseholdMembersCompanion toCompanion(bool nullToAbsent) {
    return HouseholdMembersCompanion(
      id: Value(id),
      displayName: Value(displayName),
      isLocalDeviceOwner: Value(isLocalDeviceOwner),
    );
  }

  factory HouseholdMemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HouseholdMemberRow(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      isLocalDeviceOwner: serializer.fromJson<bool>(json['isLocalDeviceOwner']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String>(displayName),
      'isLocalDeviceOwner': serializer.toJson<bool>(isLocalDeviceOwner),
    };
  }

  HouseholdMemberRow copyWith({
    int? id,
    String? displayName,
    bool? isLocalDeviceOwner,
  }) => HouseholdMemberRow(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    isLocalDeviceOwner: isLocalDeviceOwner ?? this.isLocalDeviceOwner,
  );
  HouseholdMemberRow copyWithCompanion(HouseholdMembersCompanion data) {
    return HouseholdMemberRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      isLocalDeviceOwner: data.isLocalDeviceOwner.present
          ? data.isLocalDeviceOwner.value
          : this.isLocalDeviceOwner,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdMemberRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('isLocalDeviceOwner: $isLocalDeviceOwner')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, displayName, isLocalDeviceOwner);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HouseholdMemberRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.isLocalDeviceOwner == this.isLocalDeviceOwner);
}

class HouseholdMembersCompanion extends UpdateCompanion<HouseholdMemberRow> {
  final Value<int> id;
  final Value<String> displayName;
  final Value<bool> isLocalDeviceOwner;
  const HouseholdMembersCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.isLocalDeviceOwner = const Value.absent(),
  });
  HouseholdMembersCompanion.insert({
    this.id = const Value.absent(),
    required String displayName,
    this.isLocalDeviceOwner = const Value.absent(),
  }) : displayName = Value(displayName);
  static Insertable<HouseholdMemberRow> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<bool>? isLocalDeviceOwner,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (isLocalDeviceOwner != null)
        'is_local_device_owner': isLocalDeviceOwner,
    });
  }

  HouseholdMembersCompanion copyWith({
    Value<int>? id,
    Value<String>? displayName,
    Value<bool>? isLocalDeviceOwner,
  }) {
    return HouseholdMembersCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      isLocalDeviceOwner: isLocalDeviceOwner ?? this.isLocalDeviceOwner,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (isLocalDeviceOwner.present) {
      map['is_local_device_owner'] = Variable<bool>(isLocalDeviceOwner.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdMembersCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('isLocalDeviceOwner: $isLocalDeviceOwner')
          ..write(')'))
        .toString();
  }
}

class $PetsTable extends Pets with TableInfo<$PetsTable, PetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PetsTable(this.attachedDatabase, [this._alias]);
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speciesMeta = const VerificationMeta(
    'species',
  );
  @override
  late final GeneratedColumn<String> species = GeneratedColumn<String>(
    'species',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoRefMeta = const VerificationMeta(
    'photoRef',
  );
  @override
  late final GeneratedColumn<String> photoRef = GeneratedColumn<String>(
    'photo_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, species, photoRef];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pets';
  @override
  VerificationContext validateIntegrity(
    Insertable<PetRow> instance, {
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
    if (data.containsKey('species')) {
      context.handle(
        _speciesMeta,
        species.isAcceptableOrUnknown(data['species']!, _speciesMeta),
      );
    } else if (isInserting) {
      context.missing(_speciesMeta);
    }
    if (data.containsKey('photo_ref')) {
      context.handle(
        _photoRefMeta,
        photoRef.isAcceptableOrUnknown(data['photo_ref']!, _photoRefMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      species: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}species'],
      )!,
      photoRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_ref'],
      ),
    );
  }

  @override
  $PetsTable createAlias(String alias) {
    return $PetsTable(attachedDatabase, alias);
  }
}

class PetRow extends DataClass implements Insertable<PetRow> {
  final int id;
  final String name;
  final String species;

  /// Optional file reference for a photo; bytes live outside the database.
  final String? photoRef;
  const PetRow({
    required this.id,
    required this.name,
    required this.species,
    this.photoRef,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['species'] = Variable<String>(species);
    if (!nullToAbsent || photoRef != null) {
      map['photo_ref'] = Variable<String>(photoRef);
    }
    return map;
  }

  PetsCompanion toCompanion(bool nullToAbsent) {
    return PetsCompanion(
      id: Value(id),
      name: Value(name),
      species: Value(species),
      photoRef: photoRef == null && nullToAbsent
          ? const Value.absent()
          : Value(photoRef),
    );
  }

  factory PetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PetRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      species: serializer.fromJson<String>(json['species']),
      photoRef: serializer.fromJson<String?>(json['photoRef']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'species': serializer.toJson<String>(species),
      'photoRef': serializer.toJson<String?>(photoRef),
    };
  }

  PetRow copyWith({
    int? id,
    String? name,
    String? species,
    Value<String?> photoRef = const Value.absent(),
  }) => PetRow(
    id: id ?? this.id,
    name: name ?? this.name,
    species: species ?? this.species,
    photoRef: photoRef.present ? photoRef.value : this.photoRef,
  );
  PetRow copyWithCompanion(PetsCompanion data) {
    return PetRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      species: data.species.present ? data.species.value : this.species,
      photoRef: data.photoRef.present ? data.photoRef.value : this.photoRef,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PetRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('species: $species, ')
          ..write('photoRef: $photoRef')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, species, photoRef);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PetRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.species == this.species &&
          other.photoRef == this.photoRef);
}

class PetsCompanion extends UpdateCompanion<PetRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> species;
  final Value<String?> photoRef;
  const PetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.species = const Value.absent(),
    this.photoRef = const Value.absent(),
  });
  PetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String species,
    this.photoRef = const Value.absent(),
  }) : name = Value(name),
       species = Value(species);
  static Insertable<PetRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? species,
    Expression<String>? photoRef,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (species != null) 'species': species,
      if (photoRef != null) 'photo_ref': photoRef,
    });
  }

  PetsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? species,
    Value<String?>? photoRef,
  }) {
    return PetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      photoRef: photoRef ?? this.photoRef,
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
    if (species.present) {
      map['species'] = Variable<String>(species.value);
    }
    if (photoRef.present) {
      map['photo_ref'] = Variable<String>(photoRef.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('species: $species, ')
          ..write('photoRef: $photoRef')
          ..write(')'))
        .toString();
  }
}

class $RoutinesTable extends Routines
    with TableInfo<$RoutinesTable, RoutineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutinesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _petIdMeta = const VerificationMeta('petId');
  @override
  late final GeneratedColumn<int> petId = GeneratedColumn<int>(
    'pet_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pets (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultAssigneeIdMeta = const VerificationMeta(
    'defaultAssigneeId',
  );
  @override
  late final GeneratedColumn<int> defaultAssigneeId = GeneratedColumn<int>(
    'default_assignee_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES household_members (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, petId, name, defaultAssigneeId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routines';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoutineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pet_id')) {
      context.handle(
        _petIdMeta,
        petId.isAcceptableOrUnknown(data['pet_id']!, _petIdMeta),
      );
    } else if (isInserting) {
      context.missing(_petIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('default_assignee_id')) {
      context.handle(
        _defaultAssigneeIdMeta,
        defaultAssigneeId.isAcceptableOrUnknown(
          data['default_assignee_id']!,
          _defaultAssigneeIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      petId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pet_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      defaultAssigneeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_assignee_id'],
      ),
    );
  }

  @override
  $RoutinesTable createAlias(String alias) {
    return $RoutinesTable(attachedDatabase, alias);
  }
}

class RoutineRow extends DataClass implements Insertable<RoutineRow> {
  final int id;
  final int petId;
  final String name;
  final int? defaultAssigneeId;
  const RoutineRow({
    required this.id,
    required this.petId,
    required this.name,
    this.defaultAssigneeId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pet_id'] = Variable<int>(petId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || defaultAssigneeId != null) {
      map['default_assignee_id'] = Variable<int>(defaultAssigneeId);
    }
    return map;
  }

  RoutinesCompanion toCompanion(bool nullToAbsent) {
    return RoutinesCompanion(
      id: Value(id),
      petId: Value(petId),
      name: Value(name),
      defaultAssigneeId: defaultAssigneeId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultAssigneeId),
    );
  }

  factory RoutineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineRow(
      id: serializer.fromJson<int>(json['id']),
      petId: serializer.fromJson<int>(json['petId']),
      name: serializer.fromJson<String>(json['name']),
      defaultAssigneeId: serializer.fromJson<int?>(json['defaultAssigneeId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'petId': serializer.toJson<int>(petId),
      'name': serializer.toJson<String>(name),
      'defaultAssigneeId': serializer.toJson<int?>(defaultAssigneeId),
    };
  }

  RoutineRow copyWith({
    int? id,
    int? petId,
    String? name,
    Value<int?> defaultAssigneeId = const Value.absent(),
  }) => RoutineRow(
    id: id ?? this.id,
    petId: petId ?? this.petId,
    name: name ?? this.name,
    defaultAssigneeId: defaultAssigneeId.present
        ? defaultAssigneeId.value
        : this.defaultAssigneeId,
  );
  RoutineRow copyWithCompanion(RoutinesCompanion data) {
    return RoutineRow(
      id: data.id.present ? data.id.value : this.id,
      petId: data.petId.present ? data.petId.value : this.petId,
      name: data.name.present ? data.name.value : this.name,
      defaultAssigneeId: data.defaultAssigneeId.present
          ? data.defaultAssigneeId.value
          : this.defaultAssigneeId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineRow(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('name: $name, ')
          ..write('defaultAssigneeId: $defaultAssigneeId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, petId, name, defaultAssigneeId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineRow &&
          other.id == this.id &&
          other.petId == this.petId &&
          other.name == this.name &&
          other.defaultAssigneeId == this.defaultAssigneeId);
}

class RoutinesCompanion extends UpdateCompanion<RoutineRow> {
  final Value<int> id;
  final Value<int> petId;
  final Value<String> name;
  final Value<int?> defaultAssigneeId;
  const RoutinesCompanion({
    this.id = const Value.absent(),
    this.petId = const Value.absent(),
    this.name = const Value.absent(),
    this.defaultAssigneeId = const Value.absent(),
  });
  RoutinesCompanion.insert({
    this.id = const Value.absent(),
    required int petId,
    required String name,
    this.defaultAssigneeId = const Value.absent(),
  }) : petId = Value(petId),
       name = Value(name);
  static Insertable<RoutineRow> custom({
    Expression<int>? id,
    Expression<int>? petId,
    Expression<String>? name,
    Expression<int>? defaultAssigneeId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (petId != null) 'pet_id': petId,
      if (name != null) 'name': name,
      if (defaultAssigneeId != null) 'default_assignee_id': defaultAssigneeId,
    });
  }

  RoutinesCompanion copyWith({
    Value<int>? id,
    Value<int>? petId,
    Value<String>? name,
    Value<int?>? defaultAssigneeId,
  }) {
    return RoutinesCompanion(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      name: name ?? this.name,
      defaultAssigneeId: defaultAssigneeId ?? this.defaultAssigneeId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (petId.present) {
      map['pet_id'] = Variable<int>(petId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (defaultAssigneeId.present) {
      map['default_assignee_id'] = Variable<int>(defaultAssigneeId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutinesCompanion(')
          ..write('id: $id, ')
          ..write('petId: $petId, ')
          ..write('name: $name, ')
          ..write('defaultAssigneeId: $defaultAssigneeId')
          ..write(')'))
        .toString();
  }
}

class $ScheduleWindowsTable extends ScheduleWindows
    with TableInfo<$ScheduleWindowsTable, ScheduleWindowRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduleWindowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<int> routineId = GeneratedColumn<int>(
    'routine_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES routines (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _startHourMeta = const VerificationMeta(
    'startHour',
  );
  @override
  late final GeneratedColumn<int> startHour = GeneratedColumn<int>(
    'start_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startMinuteMeta = const VerificationMeta(
    'startMinute',
  );
  @override
  late final GeneratedColumn<int> startMinute = GeneratedColumn<int>(
    'start_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _endHourMeta = const VerificationMeta(
    'endHour',
  );
  @override
  late final GeneratedColumn<int> endHour = GeneratedColumn<int>(
    'end_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _endMinuteMeta = const VerificationMeta(
    'endMinute',
  );
  @override
  late final GeneratedColumn<int> endMinute = GeneratedColumn<int>(
    'end_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _daysOfWeekMeta = const VerificationMeta(
    'daysOfWeek',
  );
  @override
  late final GeneratedColumn<String> daysOfWeek = GeneratedColumn<String>(
    'days_of_week',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('1,2,3,4,5,6,7'),
  );
  static const VerificationMeta _crossesMidnightMeta = const VerificationMeta(
    'crossesMidnight',
  );
  @override
  late final GeneratedColumn<bool> crossesMidnight = GeneratedColumn<bool>(
    'crosses_midnight',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("crosses_midnight" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    routineId,
    startHour,
    startMinute,
    endHour,
    endMinute,
    daysOfWeek,
    crossesMidnight,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_windows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleWindowRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('start_hour')) {
      context.handle(
        _startHourMeta,
        startHour.isAcceptableOrUnknown(data['start_hour']!, _startHourMeta),
      );
    }
    if (data.containsKey('start_minute')) {
      context.handle(
        _startMinuteMeta,
        startMinute.isAcceptableOrUnknown(
          data['start_minute']!,
          _startMinuteMeta,
        ),
      );
    }
    if (data.containsKey('end_hour')) {
      context.handle(
        _endHourMeta,
        endHour.isAcceptableOrUnknown(data['end_hour']!, _endHourMeta),
      );
    }
    if (data.containsKey('end_minute')) {
      context.handle(
        _endMinuteMeta,
        endMinute.isAcceptableOrUnknown(data['end_minute']!, _endMinuteMeta),
      );
    }
    if (data.containsKey('days_of_week')) {
      context.handle(
        _daysOfWeekMeta,
        daysOfWeek.isAcceptableOrUnknown(
          data['days_of_week']!,
          _daysOfWeekMeta,
        ),
      );
    }
    if (data.containsKey('crosses_midnight')) {
      context.handle(
        _crossesMidnightMeta,
        crossesMidnight.isAcceptableOrUnknown(
          data['crosses_midnight']!,
          _crossesMidnightMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleWindowRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleWindowRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}routine_id'],
      )!,
      startHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_hour'],
      )!,
      startMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minute'],
      )!,
      endHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_hour'],
      )!,
      endMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minute'],
      )!,
      daysOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}days_of_week'],
      )!,
      crossesMidnight: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}crosses_midnight'],
      )!,
    );
  }

  @override
  $ScheduleWindowsTable createAlias(String alias) {
    return $ScheduleWindowsTable(attachedDatabase, alias);
  }
}

class ScheduleWindowRow extends DataClass
    implements Insertable<ScheduleWindowRow> {
  final int id;
  final int routineId;

  /// Device-local wall-clock window bounds, e.g. 07:30 to 08:00.
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  /// ISO weekdays (Mon=1..Sun=7) as a comma-separated list, e.g. "1,3,5".
  final String daysOfWeek;
  final bool crossesMidnight;
  const ScheduleWindowRow({
    required this.id,
    required this.routineId,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.daysOfWeek,
    required this.crossesMidnight,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['routine_id'] = Variable<int>(routineId);
    map['start_hour'] = Variable<int>(startHour);
    map['start_minute'] = Variable<int>(startMinute);
    map['end_hour'] = Variable<int>(endHour);
    map['end_minute'] = Variable<int>(endMinute);
    map['days_of_week'] = Variable<String>(daysOfWeek);
    map['crosses_midnight'] = Variable<bool>(crossesMidnight);
    return map;
  }

  ScheduleWindowsCompanion toCompanion(bool nullToAbsent) {
    return ScheduleWindowsCompanion(
      id: Value(id),
      routineId: Value(routineId),
      startHour: Value(startHour),
      startMinute: Value(startMinute),
      endHour: Value(endHour),
      endMinute: Value(endMinute),
      daysOfWeek: Value(daysOfWeek),
      crossesMidnight: Value(crossesMidnight),
    );
  }

  factory ScheduleWindowRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleWindowRow(
      id: serializer.fromJson<int>(json['id']),
      routineId: serializer.fromJson<int>(json['routineId']),
      startHour: serializer.fromJson<int>(json['startHour']),
      startMinute: serializer.fromJson<int>(json['startMinute']),
      endHour: serializer.fromJson<int>(json['endHour']),
      endMinute: serializer.fromJson<int>(json['endMinute']),
      daysOfWeek: serializer.fromJson<String>(json['daysOfWeek']),
      crossesMidnight: serializer.fromJson<bool>(json['crossesMidnight']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'routineId': serializer.toJson<int>(routineId),
      'startHour': serializer.toJson<int>(startHour),
      'startMinute': serializer.toJson<int>(startMinute),
      'endHour': serializer.toJson<int>(endHour),
      'endMinute': serializer.toJson<int>(endMinute),
      'daysOfWeek': serializer.toJson<String>(daysOfWeek),
      'crossesMidnight': serializer.toJson<bool>(crossesMidnight),
    };
  }

  ScheduleWindowRow copyWith({
    int? id,
    int? routineId,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    String? daysOfWeek,
    bool? crossesMidnight,
  }) => ScheduleWindowRow(
    id: id ?? this.id,
    routineId: routineId ?? this.routineId,
    startHour: startHour ?? this.startHour,
    startMinute: startMinute ?? this.startMinute,
    endHour: endHour ?? this.endHour,
    endMinute: endMinute ?? this.endMinute,
    daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    crossesMidnight: crossesMidnight ?? this.crossesMidnight,
  );
  ScheduleWindowRow copyWithCompanion(ScheduleWindowsCompanion data) {
    return ScheduleWindowRow(
      id: data.id.present ? data.id.value : this.id,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      startHour: data.startHour.present ? data.startHour.value : this.startHour,
      startMinute: data.startMinute.present
          ? data.startMinute.value
          : this.startMinute,
      endHour: data.endHour.present ? data.endHour.value : this.endHour,
      endMinute: data.endMinute.present ? data.endMinute.value : this.endMinute,
      daysOfWeek: data.daysOfWeek.present
          ? data.daysOfWeek.value
          : this.daysOfWeek,
      crossesMidnight: data.crossesMidnight.present
          ? data.crossesMidnight.value
          : this.crossesMidnight,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleWindowRow(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('startHour: $startHour, ')
          ..write('startMinute: $startMinute, ')
          ..write('endHour: $endHour, ')
          ..write('endMinute: $endMinute, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('crossesMidnight: $crossesMidnight')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    routineId,
    startHour,
    startMinute,
    endHour,
    endMinute,
    daysOfWeek,
    crossesMidnight,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleWindowRow &&
          other.id == this.id &&
          other.routineId == this.routineId &&
          other.startHour == this.startHour &&
          other.startMinute == this.startMinute &&
          other.endHour == this.endHour &&
          other.endMinute == this.endMinute &&
          other.daysOfWeek == this.daysOfWeek &&
          other.crossesMidnight == this.crossesMidnight);
}

class ScheduleWindowsCompanion extends UpdateCompanion<ScheduleWindowRow> {
  final Value<int> id;
  final Value<int> routineId;
  final Value<int> startHour;
  final Value<int> startMinute;
  final Value<int> endHour;
  final Value<int> endMinute;
  final Value<String> daysOfWeek;
  final Value<bool> crossesMidnight;
  const ScheduleWindowsCompanion({
    this.id = const Value.absent(),
    this.routineId = const Value.absent(),
    this.startHour = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.endHour = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.crossesMidnight = const Value.absent(),
  });
  ScheduleWindowsCompanion.insert({
    this.id = const Value.absent(),
    required int routineId,
    this.startHour = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.endHour = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.crossesMidnight = const Value.absent(),
  }) : routineId = Value(routineId);
  static Insertable<ScheduleWindowRow> custom({
    Expression<int>? id,
    Expression<int>? routineId,
    Expression<int>? startHour,
    Expression<int>? startMinute,
    Expression<int>? endHour,
    Expression<int>? endMinute,
    Expression<String>? daysOfWeek,
    Expression<bool>? crossesMidnight,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routineId != null) 'routine_id': routineId,
      if (startHour != null) 'start_hour': startHour,
      if (startMinute != null) 'start_minute': startMinute,
      if (endHour != null) 'end_hour': endHour,
      if (endMinute != null) 'end_minute': endMinute,
      if (daysOfWeek != null) 'days_of_week': daysOfWeek,
      if (crossesMidnight != null) 'crosses_midnight': crossesMidnight,
    });
  }

  ScheduleWindowsCompanion copyWith({
    Value<int>? id,
    Value<int>? routineId,
    Value<int>? startHour,
    Value<int>? startMinute,
    Value<int>? endHour,
    Value<int>? endMinute,
    Value<String>? daysOfWeek,
    Value<bool>? crossesMidnight,
  }) {
    return ScheduleWindowsCompanion(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      crossesMidnight: crossesMidnight ?? this.crossesMidnight,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<int>(routineId.value);
    }
    if (startHour.present) {
      map['start_hour'] = Variable<int>(startHour.value);
    }
    if (startMinute.present) {
      map['start_minute'] = Variable<int>(startMinute.value);
    }
    if (endHour.present) {
      map['end_hour'] = Variable<int>(endHour.value);
    }
    if (endMinute.present) {
      map['end_minute'] = Variable<int>(endMinute.value);
    }
    if (daysOfWeek.present) {
      map['days_of_week'] = Variable<String>(daysOfWeek.value);
    }
    if (crossesMidnight.present) {
      map['crosses_midnight'] = Variable<bool>(crossesMidnight.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleWindowsCompanion(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('startHour: $startHour, ')
          ..write('startMinute: $startMinute, ')
          ..write('endHour: $endHour, ')
          ..write('endMinute: $endMinute, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('crossesMidnight: $crossesMidnight')
          ..write(')'))
        .toString();
  }
}

class $CompletionEventsTable extends CompletionEvents
    with TableInfo<$CompletionEventsTable, CompletionEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletionEventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<int> routineId = GeneratedColumn<int>(
    'routine_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES routines (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
    defaultValue: const Constant('done'),
  );
  static const VerificationMeta _completedByMemberIdMeta =
      const VerificationMeta('completedByMemberId');
  @override
  late final GeneratedColumn<int> completedByMemberId = GeneratedColumn<int>(
    'completed_by_member_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES household_members (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    routineId,
    completedAt,
    kind,
    completedByMemberId,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completion_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompletionEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('completed_by_member_id')) {
      context.handle(
        _completedByMemberIdMeta,
        completedByMemberId.isAcceptableOrUnknown(
          data['completed_by_member_id']!,
          _completedByMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompletionEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletionEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}routine_id'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      completedByMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_by_member_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $CompletionEventsTable createAlias(String alias) {
    return $CompletionEventsTable(attachedDatabase, alias);
  }
}

class CompletionEventRow extends DataClass
    implements Insertable<CompletionEventRow> {
  final int id;
  final int routineId;
  final DateTime completedAt;
  final String kind;
  final int? completedByMemberId;
  final String? note;
  const CompletionEventRow({
    required this.id,
    required this.routineId,
    required this.completedAt,
    required this.kind,
    this.completedByMemberId,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['routine_id'] = Variable<int>(routineId);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || completedByMemberId != null) {
      map['completed_by_member_id'] = Variable<int>(completedByMemberId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  CompletionEventsCompanion toCompanion(bool nullToAbsent) {
    return CompletionEventsCompanion(
      id: Value(id),
      routineId: Value(routineId),
      completedAt: Value(completedAt),
      kind: Value(kind),
      completedByMemberId: completedByMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(completedByMemberId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory CompletionEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletionEventRow(
      id: serializer.fromJson<int>(json['id']),
      routineId: serializer.fromJson<int>(json['routineId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      kind: serializer.fromJson<String>(json['kind']),
      completedByMemberId: serializer.fromJson<int?>(
        json['completedByMemberId'],
      ),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'routineId': serializer.toJson<int>(routineId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'kind': serializer.toJson<String>(kind),
      'completedByMemberId': serializer.toJson<int?>(completedByMemberId),
      'note': serializer.toJson<String?>(note),
    };
  }

  CompletionEventRow copyWith({
    int? id,
    int? routineId,
    DateTime? completedAt,
    String? kind,
    Value<int?> completedByMemberId = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => CompletionEventRow(
    id: id ?? this.id,
    routineId: routineId ?? this.routineId,
    completedAt: completedAt ?? this.completedAt,
    kind: kind ?? this.kind,
    completedByMemberId: completedByMemberId.present
        ? completedByMemberId.value
        : this.completedByMemberId,
    note: note.present ? note.value : this.note,
  );
  CompletionEventRow copyWithCompanion(CompletionEventsCompanion data) {
    return CompletionEventRow(
      id: data.id.present ? data.id.value : this.id,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      completedByMemberId: data.completedByMemberId.present
          ? data.completedByMemberId.value
          : this.completedByMemberId,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletionEventRow(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('completedAt: $completedAt, ')
          ..write('kind: $kind, ')
          ..write('completedByMemberId: $completedByMemberId, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, routineId, completedAt, kind, completedByMemberId, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletionEventRow &&
          other.id == this.id &&
          other.routineId == this.routineId &&
          other.completedAt == this.completedAt &&
          other.kind == this.kind &&
          other.completedByMemberId == this.completedByMemberId &&
          other.note == this.note);
}

class CompletionEventsCompanion extends UpdateCompanion<CompletionEventRow> {
  final Value<int> id;
  final Value<int> routineId;
  final Value<DateTime> completedAt;
  final Value<String> kind;
  final Value<int?> completedByMemberId;
  final Value<String?> note;
  const CompletionEventsCompanion({
    this.id = const Value.absent(),
    this.routineId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.completedByMemberId = const Value.absent(),
    this.note = const Value.absent(),
  });
  CompletionEventsCompanion.insert({
    this.id = const Value.absent(),
    required int routineId,
    required DateTime completedAt,
    this.kind = const Value.absent(),
    this.completedByMemberId = const Value.absent(),
    this.note = const Value.absent(),
  }) : routineId = Value(routineId),
       completedAt = Value(completedAt);
  static Insertable<CompletionEventRow> custom({
    Expression<int>? id,
    Expression<int>? routineId,
    Expression<DateTime>? completedAt,
    Expression<String>? kind,
    Expression<int>? completedByMemberId,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routineId != null) 'routine_id': routineId,
      if (completedAt != null) 'completed_at': completedAt,
      if (kind != null) 'kind': kind,
      if (completedByMemberId != null)
        'completed_by_member_id': completedByMemberId,
      if (note != null) 'note': note,
    });
  }

  CompletionEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? routineId,
    Value<DateTime>? completedAt,
    Value<String>? kind,
    Value<int?>? completedByMemberId,
    Value<String?>? note,
  }) {
    return CompletionEventsCompanion(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      completedAt: completedAt ?? this.completedAt,
      kind: kind ?? this.kind,
      completedByMemberId: completedByMemberId ?? this.completedByMemberId,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<int>(routineId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (completedByMemberId.present) {
      map['completed_by_member_id'] = Variable<int>(completedByMemberId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletionEventsCompanion(')
          ..write('id: $id, ')
          ..write('routineId: $routineId, ')
          ..write('completedAt: $completedAt, ')
          ..write('kind: $kind, ')
          ..write('completedByMemberId: $completedByMemberId, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $ReminderSettingsTableTable extends ReminderSettingsTable
    with TableInfo<$ReminderSettingsTableTable, ReminderSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_settings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  ReminderSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderSettingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $ReminderSettingsTableTable createAlias(String alias) {
    return $ReminderSettingsTableTable(attachedDatabase, alias);
  }
}

class ReminderSettingRow extends DataClass
    implements Insertable<ReminderSettingRow> {
  /// Singleton row — always id 1.
  final int id;

  /// JSON blob: {schemaVersion, notificationsEnabled, leadTimeMinutes,
  /// quietHours:{startMinutes,endMinutes}}. Versioned so future schema
  /// evolution inside the blob stays interpretable (issue #5 reuses this
  /// pattern for backups).
  final String payload;
  const ReminderSettingRow({required this.id, required this.payload});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  ReminderSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return ReminderSettingsTableCompanion(
      id: Value(id),
      payload: Value(payload),
    );
  }

  factory ReminderSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderSettingRow(
      id: serializer.fromJson<int>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payload': serializer.toJson<String>(payload),
    };
  }

  ReminderSettingRow copyWith({int? id, String? payload}) =>
      ReminderSettingRow(id: id ?? this.id, payload: payload ?? this.payload);
  ReminderSettingRow copyWithCompanion(ReminderSettingsTableCompanion data) {
    return ReminderSettingRow(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderSettingRow(')
          ..write('id: $id, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderSettingRow &&
          other.id == this.id &&
          other.payload == this.payload);
}

class ReminderSettingsTableCompanion
    extends UpdateCompanion<ReminderSettingRow> {
  final Value<int> id;
  final Value<String> payload;
  final Value<int> rowid;
  const ReminderSettingsTableCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderSettingsTableCompanion.insert({
    required int id,
    required String payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload);
  static Insertable<ReminderSettingRow> custom({
    Expression<int>? id,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return ReminderSettingsTableCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RetentionSettingsTableTable extends RetentionSettingsTable
    with TableInfo<$RetentionSettingsTableTable, RetentionSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RetentionSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'retention_settings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<RetentionSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  RetentionSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RetentionSettingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $RetentionSettingsTableTable createAlias(String alias) {
    return $RetentionSettingsTableTable(attachedDatabase, alias);
  }
}

class RetentionSettingRow extends DataClass
    implements Insertable<RetentionSettingRow> {
  /// Singleton row — always id 1.
  final int id;

  /// JSON blob: {schemaVersion, preference: keepAll|keep365Days|
  /// keep180Days|keep90Days}.
  final String payload;
  const RetentionSettingRow({required this.id, required this.payload});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  RetentionSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return RetentionSettingsTableCompanion(
      id: Value(id),
      payload: Value(payload),
    );
  }

  factory RetentionSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RetentionSettingRow(
      id: serializer.fromJson<int>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payload': serializer.toJson<String>(payload),
    };
  }

  RetentionSettingRow copyWith({int? id, String? payload}) =>
      RetentionSettingRow(id: id ?? this.id, payload: payload ?? this.payload);
  RetentionSettingRow copyWithCompanion(RetentionSettingsTableCompanion data) {
    return RetentionSettingRow(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RetentionSettingRow(')
          ..write('id: $id, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RetentionSettingRow &&
          other.id == this.id &&
          other.payload == this.payload);
}

class RetentionSettingsTableCompanion
    extends UpdateCompanion<RetentionSettingRow> {
  final Value<int> id;
  final Value<String> payload;
  final Value<int> rowid;
  const RetentionSettingsTableCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RetentionSettingsTableCompanion.insert({
    required int id,
    required String payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload);
  static Insertable<RetentionSettingRow> custom({
    Expression<int>? id,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RetentionSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return RetentionSettingsTableCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RetentionSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TailTallyDatabase extends GeneratedDatabase {
  _$TailTallyDatabase(QueryExecutor e) : super(e);
  $TailTallyDatabaseManager get managers => $TailTallyDatabaseManager(this);
  late final $HouseholdMembersTable householdMembers = $HouseholdMembersTable(
    this,
  );
  late final $PetsTable pets = $PetsTable(this);
  late final $RoutinesTable routines = $RoutinesTable(this);
  late final $ScheduleWindowsTable scheduleWindows = $ScheduleWindowsTable(
    this,
  );
  late final $CompletionEventsTable completionEvents = $CompletionEventsTable(
    this,
  );
  late final $ReminderSettingsTableTable reminderSettingsTable =
      $ReminderSettingsTableTable(this);
  late final $RetentionSettingsTableTable retentionSettingsTable =
      $RetentionSettingsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    householdMembers,
    pets,
    routines,
    scheduleWindows,
    completionEvents,
    reminderSettingsTable,
    retentionSettingsTable,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('routines', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'household_members',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('routines', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'routines',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('schedule_windows', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'routines',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('completion_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'household_members',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('completion_events', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$HouseholdMembersTableCreateCompanionBuilder =
    HouseholdMembersCompanion Function({
      Value<int> id,
      required String displayName,
      Value<bool> isLocalDeviceOwner,
    });
typedef $$HouseholdMembersTableUpdateCompanionBuilder =
    HouseholdMembersCompanion Function({
      Value<int> id,
      Value<String> displayName,
      Value<bool> isLocalDeviceOwner,
    });

final class $$HouseholdMembersTableReferences
    extends
        BaseReferences<
          _$TailTallyDatabase,
          $HouseholdMembersTable,
          HouseholdMemberRow
        > {
  $$HouseholdMembersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$RoutinesTable, List<RoutineRow>>
  _routinesRefsTable(_$TailTallyDatabase db) => MultiTypedResultKey.fromTable(
    db.routines,
    aliasName: 'household_members__id__routines__default_assignee_id',
  );

  $$RoutinesTableProcessedTableManager get routinesRefs {
    final manager = $$RoutinesTableTableManager(
      $_db,
      $_db.routines,
    ).filter((f) => f.defaultAssigneeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_routinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CompletionEventsTable, List<CompletionEventRow>>
  _completionEventsRefsTable(_$TailTallyDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.completionEvents,
        aliasName:
            'household_members__id__completion_events__completed_by_member_id',
      );

  $$CompletionEventsTableProcessedTableManager get completionEventsRefs {
    final manager =
        $$CompletionEventsTableTableManager($_db, $_db.completionEvents).filter(
          (f) => f.completedByMemberId.id.sqlEquals($_itemColumn<int>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _completionEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HouseholdMembersTableFilterComposer
    extends Composer<_$TailTallyDatabase, $HouseholdMembersTable> {
  $$HouseholdMembersTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocalDeviceOwner => $composableBuilder(
    column: $table.isLocalDeviceOwner,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> routinesRefs(
    Expression<bool> Function($$RoutinesTableFilterComposer f) f,
  ) {
    final $$RoutinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.defaultAssigneeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableFilterComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> completionEventsRefs(
    Expression<bool> Function($$CompletionEventsTableFilterComposer f) f,
  ) {
    final $$CompletionEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completionEvents,
      getReferencedColumn: (t) => t.completedByMemberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionEventsTableFilterComposer(
            $db: $db,
            $table: $db.completionEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HouseholdMembersTableOrderingComposer
    extends Composer<_$TailTallyDatabase, $HouseholdMembersTable> {
  $$HouseholdMembersTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocalDeviceOwner => $composableBuilder(
    column: $table.isLocalDeviceOwner,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HouseholdMembersTableAnnotationComposer
    extends Composer<_$TailTallyDatabase, $HouseholdMembersTable> {
  $$HouseholdMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLocalDeviceOwner => $composableBuilder(
    column: $table.isLocalDeviceOwner,
    builder: (column) => column,
  );

  Expression<T> routinesRefs<T extends Object>(
    Expression<T> Function($$RoutinesTableAnnotationComposer a) f,
  ) {
    final $$RoutinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.defaultAssigneeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableAnnotationComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> completionEventsRefs<T extends Object>(
    Expression<T> Function($$CompletionEventsTableAnnotationComposer a) f,
  ) {
    final $$CompletionEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completionEvents,
      getReferencedColumn: (t) => t.completedByMemberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.completionEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HouseholdMembersTableTableManager
    extends
        RootTableManager<
          _$TailTallyDatabase,
          $HouseholdMembersTable,
          HouseholdMemberRow,
          $$HouseholdMembersTableFilterComposer,
          $$HouseholdMembersTableOrderingComposer,
          $$HouseholdMembersTableAnnotationComposer,
          $$HouseholdMembersTableCreateCompanionBuilder,
          $$HouseholdMembersTableUpdateCompanionBuilder,
          (HouseholdMemberRow, $$HouseholdMembersTableReferences),
          HouseholdMemberRow,
          PrefetchHooks Function({bool routinesRefs, bool completionEventsRefs})
        > {
  $$HouseholdMembersTableTableManager(
    _$TailTallyDatabase db,
    $HouseholdMembersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HouseholdMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<bool> isLocalDeviceOwner = const Value.absent(),
              }) => HouseholdMembersCompanion(
                id: id,
                displayName: displayName,
                isLocalDeviceOwner: isLocalDeviceOwner,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String displayName,
                Value<bool> isLocalDeviceOwner = const Value.absent(),
              }) => HouseholdMembersCompanion.insert(
                id: id,
                displayName: displayName,
                isLocalDeviceOwner: isLocalDeviceOwner,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HouseholdMembersTable, HouseholdMemberRow>(
                    table,
                  ),
                  $$HouseholdMembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({routinesRefs = false, completionEventsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (routinesRefs) db.routines,
                    if (completionEventsRefs) db.completionEvents,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (routinesRefs)
                        await $_getPrefetchedData<
                          HouseholdMemberRow,
                          $HouseholdMembersTable,
                          RoutineRow
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdMembersTableReferences
                              ._routinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdMembersTableReferences(
                                db,
                                table,
                                p0,
                              ).routinesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.defaultAssigneeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (completionEventsRefs)
                        await $_getPrefetchedData<
                          HouseholdMemberRow,
                          $HouseholdMembersTable,
                          CompletionEventRow
                        >(
                          currentTable: table,
                          referencedTable: $$HouseholdMembersTableReferences
                              ._completionEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HouseholdMembersTableReferences(
                                db,
                                table,
                                p0,
                              ).completionEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.completedByMemberId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$HouseholdMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$TailTallyDatabase,
      $HouseholdMembersTable,
      HouseholdMemberRow,
      $$HouseholdMembersTableFilterComposer,
      $$HouseholdMembersTableOrderingComposer,
      $$HouseholdMembersTableAnnotationComposer,
      $$HouseholdMembersTableCreateCompanionBuilder,
      $$HouseholdMembersTableUpdateCompanionBuilder,
      (HouseholdMemberRow, $$HouseholdMembersTableReferences),
      HouseholdMemberRow,
      PrefetchHooks Function({bool routinesRefs, bool completionEventsRefs})
    >;
typedef $$PetsTableCreateCompanionBuilder = PetsCompanion Function({
  Value<int> id,
  required String name,
  required String species,
  Value<String?> photoRef,
});
typedef $$PetsTableUpdateCompanionBuilder = PetsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> species,
  Value<String?> photoRef,
});

final class $$PetsTableReferences
    extends BaseReferences<_$TailTallyDatabase, $PetsTable, PetRow> {
  $$PetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoutinesTable, List<RoutineRow>>
  _routinesRefsTable(_$TailTallyDatabase db) => MultiTypedResultKey.fromTable(
    db.routines,
    aliasName: 'pets__id__routines__pet_id',
  );

  $$RoutinesTableProcessedTableManager get routinesRefs {
    final manager = $$RoutinesTableTableManager(
      $_db,
      $_db.routines,
    ).filter((f) => f.petId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_routinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PetsTableFilterComposer
    extends Composer<_$TailTallyDatabase, $PetsTable> {
  $$PetsTableFilterComposer({
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

  ColumnFilters<String> get species => $composableBuilder(
    column: $table.species,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoRef => $composableBuilder(
    column: $table.photoRef,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> routinesRefs(
    Expression<bool> Function($$RoutinesTableFilterComposer f) f,
  ) {
    final $$RoutinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.petId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableFilterComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PetsTableOrderingComposer
    extends Composer<_$TailTallyDatabase, $PetsTable> {
  $$PetsTableOrderingComposer({
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

  ColumnOrderings<String> get species => $composableBuilder(
    column: $table.species,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoRef => $composableBuilder(
    column: $table.photoRef,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PetsTableAnnotationComposer
    extends Composer<_$TailTallyDatabase, $PetsTable> {
  $$PetsTableAnnotationComposer({
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

  GeneratedColumn<String> get species =>
      $composableBuilder(column: $table.species, builder: (column) => column);

  GeneratedColumn<String> get photoRef =>
      $composableBuilder(column: $table.photoRef, builder: (column) => column);

  Expression<T> routinesRefs<T extends Object>(
    Expression<T> Function($$RoutinesTableAnnotationComposer a) f,
  ) {
    final $$RoutinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.petId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableAnnotationComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PetsTableTableManager
    extends
        RootTableManager<
          _$TailTallyDatabase,
          $PetsTable,
          PetRow,
          $$PetsTableFilterComposer,
          $$PetsTableOrderingComposer,
          $$PetsTableAnnotationComposer,
          $$PetsTableCreateCompanionBuilder,
          $$PetsTableUpdateCompanionBuilder,
          (PetRow, $$PetsTableReferences),
          PetRow,
          PrefetchHooks Function({bool routinesRefs})
        > {
  $$PetsTableTableManager(_$TailTallyDatabase db, $PetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> species = const Value.absent(),
                Value<String?> photoRef = const Value.absent(),
              }) => PetsCompanion(
                id: id,
                name: name,
                species: species,
                photoRef: photoRef,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String species,
                Value<String?> photoRef = const Value.absent(),
              }) => PetsCompanion.insert(
                id: id,
                name: name,
                species: species,
                photoRef: photoRef,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PetsTable, PetRow>(table),
                  $$PetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({routinesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (routinesRefs) db.routines],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routinesRefs)
                    await $_getPrefetchedData<PetRow, $PetsTable, RoutineRow>(
                      currentTable: table,
                      referencedTable: $$PetsTableReferences._routinesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$PetsTableReferences(db, table, p0).routinesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.petId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PetsTableProcessedTableManager =
    ProcessedTableManager<
      _$TailTallyDatabase,
      $PetsTable,
      PetRow,
      $$PetsTableFilterComposer,
      $$PetsTableOrderingComposer,
      $$PetsTableAnnotationComposer,
      $$PetsTableCreateCompanionBuilder,
      $$PetsTableUpdateCompanionBuilder,
      (PetRow, $$PetsTableReferences),
      PetRow,
      PrefetchHooks Function({bool routinesRefs})
    >;
typedef $$RoutinesTableCreateCompanionBuilder = RoutinesCompanion Function({
  Value<int> id,
  required int petId,
  required String name,
  Value<int?> defaultAssigneeId,
});
typedef $$RoutinesTableUpdateCompanionBuilder = RoutinesCompanion Function({
  Value<int> id,
  Value<int> petId,
  Value<String> name,
  Value<int?> defaultAssigneeId,
});

final class $$RoutinesTableReferences
    extends BaseReferences<_$TailTallyDatabase, $RoutinesTable, RoutineRow> {
  $$RoutinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PetsTable _petIdTable(_$TailTallyDatabase db) =>
      db.pets.createAlias('routines__pet_id__pets__id');

  $$PetsTableProcessedTableManager get petId {
    final $_column = $_itemColumn<int>('pet_id')!;

    final manager = $$PetsTableTableManager(
      $_db,
      $_db.pets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_petIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $HouseholdMembersTable _defaultAssigneeIdTable(
    _$TailTallyDatabase db,
  ) => db.householdMembers.createAlias(
    'routines__default_assignee_id__household_members__id',
  );

  $$HouseholdMembersTableProcessedTableManager? get defaultAssigneeId {
    final $_column = $_itemColumn<int>('default_assignee_id');
    if ($_column == null) return null;
    final manager = $$HouseholdMembersTableTableManager(
      $_db,
      $_db.householdMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_defaultAssigneeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ScheduleWindowsTable, List<ScheduleWindowRow>>
  _scheduleWindowsRefsTable(_$TailTallyDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.scheduleWindows,
        aliasName: 'routines__id__schedule_windows__routine_id',
      );

  $$ScheduleWindowsTableProcessedTableManager get scheduleWindowsRefs {
    final manager = $$ScheduleWindowsTableTableManager(
      $_db,
      $_db.scheduleWindows,
    ).filter((f) => f.routineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _scheduleWindowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CompletionEventsTable, List<CompletionEventRow>>
  _completionEventsRefsTable(_$TailTallyDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.completionEvents,
        aliasName: 'routines__id__completion_events__routine_id',
      );

  $$CompletionEventsTableProcessedTableManager get completionEventsRefs {
    final manager = $$CompletionEventsTableTableManager(
      $_db,
      $_db.completionEvents,
    ).filter((f) => f.routineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _completionEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoutinesTableFilterComposer
    extends Composer<_$TailTallyDatabase, $RoutinesTable> {
  $$RoutinesTableFilterComposer({
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

  $$PetsTableFilterComposer get petId {
    final $$PetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.pets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetsTableFilterComposer(
            $db: $db,
            $table: $db.pets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HouseholdMembersTableFilterComposer get defaultAssigneeId {
    final $$HouseholdMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultAssigneeId,
      referencedTable: $db.householdMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdMembersTableFilterComposer(
            $db: $db,
            $table: $db.householdMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> scheduleWindowsRefs(
    Expression<bool> Function($$ScheduleWindowsTableFilterComposer f) f,
  ) {
    final $$ScheduleWindowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scheduleWindows,
      getReferencedColumn: (t) => t.routineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleWindowsTableFilterComposer(
            $db: $db,
            $table: $db.scheduleWindows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> completionEventsRefs(
    Expression<bool> Function($$CompletionEventsTableFilterComposer f) f,
  ) {
    final $$CompletionEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completionEvents,
      getReferencedColumn: (t) => t.routineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionEventsTableFilterComposer(
            $db: $db,
            $table: $db.completionEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutinesTableOrderingComposer
    extends Composer<_$TailTallyDatabase, $RoutinesTable> {
  $$RoutinesTableOrderingComposer({
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

  $$PetsTableOrderingComposer get petId {
    final $$PetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.pets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetsTableOrderingComposer(
            $db: $db,
            $table: $db.pets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HouseholdMembersTableOrderingComposer get defaultAssigneeId {
    final $$HouseholdMembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultAssigneeId,
      referencedTable: $db.householdMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdMembersTableOrderingComposer(
            $db: $db,
            $table: $db.householdMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoutinesTableAnnotationComposer
    extends Composer<_$TailTallyDatabase, $RoutinesTable> {
  $$RoutinesTableAnnotationComposer({
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

  $$PetsTableAnnotationComposer get petId {
    final $$PetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.petId,
      referencedTable: $db.pets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PetsTableAnnotationComposer(
            $db: $db,
            $table: $db.pets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HouseholdMembersTableAnnotationComposer get defaultAssigneeId {
    final $$HouseholdMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultAssigneeId,
      referencedTable: $db.householdMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.householdMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> scheduleWindowsRefs<T extends Object>(
    Expression<T> Function($$ScheduleWindowsTableAnnotationComposer a) f,
  ) {
    final $$ScheduleWindowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scheduleWindows,
      getReferencedColumn: (t) => t.routineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScheduleWindowsTableAnnotationComposer(
            $db: $db,
            $table: $db.scheduleWindows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> completionEventsRefs<T extends Object>(
    Expression<T> Function($$CompletionEventsTableAnnotationComposer a) f,
  ) {
    final $$CompletionEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completionEvents,
      getReferencedColumn: (t) => t.routineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.completionEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoutinesTableTableManager
    extends
        RootTableManager<
          _$TailTallyDatabase,
          $RoutinesTable,
          RoutineRow,
          $$RoutinesTableFilterComposer,
          $$RoutinesTableOrderingComposer,
          $$RoutinesTableAnnotationComposer,
          $$RoutinesTableCreateCompanionBuilder,
          $$RoutinesTableUpdateCompanionBuilder,
          (RoutineRow, $$RoutinesTableReferences),
          RoutineRow,
          PrefetchHooks Function({
            bool petId,
            bool defaultAssigneeId,
            bool scheduleWindowsRefs,
            bool completionEventsRefs,
          })
        > {
  $$RoutinesTableTableManager(_$TailTallyDatabase db, $RoutinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> petId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> defaultAssigneeId = const Value.absent(),
              }) => RoutinesCompanion(
                id: id,
                petId: petId,
                name: name,
                defaultAssigneeId: defaultAssigneeId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int petId,
                required String name,
                Value<int?> defaultAssigneeId = const Value.absent(),
              }) => RoutinesCompanion.insert(
                id: id,
                petId: petId,
                name: name,
                defaultAssigneeId: defaultAssigneeId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RoutinesTable, RoutineRow>(table),
                  $$RoutinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                petId = false,
                defaultAssigneeId = false,
                scheduleWindowsRefs = false,
                completionEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (scheduleWindowsRefs) db.scheduleWindows,
                    if (completionEventsRefs) db.completionEvents,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (petId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.petId,
                            referencedTable: $$RoutinesTableReferences
                                ._petIdTable(db),
                            referencedColumn: $$RoutinesTableReferences
                                ._petIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (defaultAssigneeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.defaultAssigneeId,
                            referencedTable: $$RoutinesTableReferences
                                ._defaultAssigneeIdTable(db),
                            referencedColumn: $$RoutinesTableReferences
                                ._defaultAssigneeIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (scheduleWindowsRefs)
                        await $_getPrefetchedData<
                          RoutineRow,
                          $RoutinesTable,
                          ScheduleWindowRow
                        >(
                          currentTable: table,
                          referencedTable: $$RoutinesTableReferences
                              ._scheduleWindowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RoutinesTableReferences(
                                db,
                                table,
                                p0,
                              ).scheduleWindowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.routineId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (completionEventsRefs)
                        await $_getPrefetchedData<
                          RoutineRow,
                          $RoutinesTable,
                          CompletionEventRow
                        >(
                          currentTable: table,
                          referencedTable: $$RoutinesTableReferences
                              ._completionEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RoutinesTableReferences(
                                db,
                                table,
                                p0,
                              ).completionEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.routineId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RoutinesTableProcessedTableManager =
    ProcessedTableManager<
      _$TailTallyDatabase,
      $RoutinesTable,
      RoutineRow,
      $$RoutinesTableFilterComposer,
      $$RoutinesTableOrderingComposer,
      $$RoutinesTableAnnotationComposer,
      $$RoutinesTableCreateCompanionBuilder,
      $$RoutinesTableUpdateCompanionBuilder,
      (RoutineRow, $$RoutinesTableReferences),
      RoutineRow,
      PrefetchHooks Function({
        bool petId,
        bool defaultAssigneeId,
        bool scheduleWindowsRefs,
        bool completionEventsRefs,
      })
    >;
typedef $$ScheduleWindowsTableCreateCompanionBuilder =
    ScheduleWindowsCompanion Function({
      Value<int> id,
      required int routineId,
      Value<int> startHour,
      Value<int> startMinute,
      Value<int> endHour,
      Value<int> endMinute,
      Value<String> daysOfWeek,
      Value<bool> crossesMidnight,
    });
typedef $$ScheduleWindowsTableUpdateCompanionBuilder =
    ScheduleWindowsCompanion Function({
      Value<int> id,
      Value<int> routineId,
      Value<int> startHour,
      Value<int> startMinute,
      Value<int> endHour,
      Value<int> endMinute,
      Value<String> daysOfWeek,
      Value<bool> crossesMidnight,
    });

final class $$ScheduleWindowsTableReferences
    extends
        BaseReferences<
          _$TailTallyDatabase,
          $ScheduleWindowsTable,
          ScheduleWindowRow
        > {
  $$ScheduleWindowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RoutinesTable _routineIdTable(_$TailTallyDatabase db) =>
      db.routines.createAlias('schedule_windows__routine_id__routines__id');

  $$RoutinesTableProcessedTableManager get routineId {
    final $_column = $_itemColumn<int>('routine_id')!;

    final manager = $$RoutinesTableTableManager(
      $_db,
      $_db.routines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScheduleWindowsTableFilterComposer
    extends Composer<_$TailTallyDatabase, $ScheduleWindowsTable> {
  $$ScheduleWindowsTableFilterComposer({
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

  ColumnFilters<int> get startHour => $composableBuilder(
    column: $table.startHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endHour => $composableBuilder(
    column: $table.endHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get crossesMidnight => $composableBuilder(
    column: $table.crossesMidnight,
    builder: (column) => ColumnFilters(column),
  );

  $$RoutinesTableFilterComposer get routineId {
    final $$RoutinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableFilterComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleWindowsTableOrderingComposer
    extends Composer<_$TailTallyDatabase, $ScheduleWindowsTable> {
  $$ScheduleWindowsTableOrderingComposer({
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

  ColumnOrderings<int> get startHour => $composableBuilder(
    column: $table.startHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endHour => $composableBuilder(
    column: $table.endHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get crossesMidnight => $composableBuilder(
    column: $table.crossesMidnight,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoutinesTableOrderingComposer get routineId {
    final $$RoutinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableOrderingComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleWindowsTableAnnotationComposer
    extends Composer<_$TailTallyDatabase, $ScheduleWindowsTable> {
  $$ScheduleWindowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startHour =>
      $composableBuilder(column: $table.startHour, builder: (column) => column);

  GeneratedColumn<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endHour =>
      $composableBuilder(column: $table.endHour, builder: (column) => column);

  GeneratedColumn<int> get endMinute =>
      $composableBuilder(column: $table.endMinute, builder: (column) => column);

  GeneratedColumn<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get crossesMidnight => $composableBuilder(
    column: $table.crossesMidnight,
    builder: (column) => column,
  );

  $$RoutinesTableAnnotationComposer get routineId {
    final $$RoutinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableAnnotationComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScheduleWindowsTableTableManager
    extends
        RootTableManager<
          _$TailTallyDatabase,
          $ScheduleWindowsTable,
          ScheduleWindowRow,
          $$ScheduleWindowsTableFilterComposer,
          $$ScheduleWindowsTableOrderingComposer,
          $$ScheduleWindowsTableAnnotationComposer,
          $$ScheduleWindowsTableCreateCompanionBuilder,
          $$ScheduleWindowsTableUpdateCompanionBuilder,
          (ScheduleWindowRow, $$ScheduleWindowsTableReferences),
          ScheduleWindowRow,
          PrefetchHooks Function({bool routineId})
        > {
  $$ScheduleWindowsTableTableManager(
    _$TailTallyDatabase db,
    $ScheduleWindowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduleWindowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduleWindowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduleWindowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> routineId = const Value.absent(),
                Value<int> startHour = const Value.absent(),
                Value<int> startMinute = const Value.absent(),
                Value<int> endHour = const Value.absent(),
                Value<int> endMinute = const Value.absent(),
                Value<String> daysOfWeek = const Value.absent(),
                Value<bool> crossesMidnight = const Value.absent(),
              }) => ScheduleWindowsCompanion(
                id: id,
                routineId: routineId,
                startHour: startHour,
                startMinute: startMinute,
                endHour: endHour,
                endMinute: endMinute,
                daysOfWeek: daysOfWeek,
                crossesMidnight: crossesMidnight,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int routineId,
                Value<int> startHour = const Value.absent(),
                Value<int> startMinute = const Value.absent(),
                Value<int> endHour = const Value.absent(),
                Value<int> endMinute = const Value.absent(),
                Value<String> daysOfWeek = const Value.absent(),
                Value<bool> crossesMidnight = const Value.absent(),
              }) => ScheduleWindowsCompanion.insert(
                id: id,
                routineId: routineId,
                startHour: startHour,
                startMinute: startMinute,
                endHour: endHour,
                endMinute: endMinute,
                daysOfWeek: daysOfWeek,
                crossesMidnight: crossesMidnight,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScheduleWindowsTable, ScheduleWindowRow>(table),
                  $$ScheduleWindowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({routineId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (routineId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.routineId,
                        referencedTable: $$ScheduleWindowsTableReferences
                            ._routineIdTable(db),
                        referencedColumn: $$ScheduleWindowsTableReferences
                            ._routineIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ScheduleWindowsTableProcessedTableManager =
    ProcessedTableManager<
      _$TailTallyDatabase,
      $ScheduleWindowsTable,
      ScheduleWindowRow,
      $$ScheduleWindowsTableFilterComposer,
      $$ScheduleWindowsTableOrderingComposer,
      $$ScheduleWindowsTableAnnotationComposer,
      $$ScheduleWindowsTableCreateCompanionBuilder,
      $$ScheduleWindowsTableUpdateCompanionBuilder,
      (ScheduleWindowRow, $$ScheduleWindowsTableReferences),
      ScheduleWindowRow,
      PrefetchHooks Function({bool routineId})
    >;
typedef $$CompletionEventsTableCreateCompanionBuilder =
    CompletionEventsCompanion Function({
      Value<int> id,
      required int routineId,
      required DateTime completedAt,
      Value<String> kind,
      Value<int?> completedByMemberId,
      Value<String?> note,
    });
typedef $$CompletionEventsTableUpdateCompanionBuilder =
    CompletionEventsCompanion Function({
      Value<int> id,
      Value<int> routineId,
      Value<DateTime> completedAt,
      Value<String> kind,
      Value<int?> completedByMemberId,
      Value<String?> note,
    });

final class $$CompletionEventsTableReferences
    extends
        BaseReferences<
          _$TailTallyDatabase,
          $CompletionEventsTable,
          CompletionEventRow
        > {
  $$CompletionEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RoutinesTable _routineIdTable(_$TailTallyDatabase db) =>
      db.routines.createAlias('completion_events__routine_id__routines__id');

  $$RoutinesTableProcessedTableManager get routineId {
    final $_column = $_itemColumn<int>('routine_id')!;

    final manager = $$RoutinesTableTableManager(
      $_db,
      $_db.routines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $HouseholdMembersTable _completedByMemberIdTable(
    _$TailTallyDatabase db,
  ) => db.householdMembers.createAlias(
    'completion_events__completed_by_member_id__household_members__id',
  );

  $$HouseholdMembersTableProcessedTableManager? get completedByMemberId {
    final $_column = $_itemColumn<int>('completed_by_member_id');
    if ($_column == null) return null;
    final manager = $$HouseholdMembersTableTableManager(
      $_db,
      $_db.householdMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_completedByMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CompletionEventsTableFilterComposer
    extends Composer<_$TailTallyDatabase, $CompletionEventsTable> {
  $$CompletionEventsTableFilterComposer({
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

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$RoutinesTableFilterComposer get routineId {
    final $$RoutinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableFilterComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HouseholdMembersTableFilterComposer get completedByMemberId {
    final $$HouseholdMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedByMemberId,
      referencedTable: $db.householdMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdMembersTableFilterComposer(
            $db: $db,
            $table: $db.householdMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionEventsTableOrderingComposer
    extends Composer<_$TailTallyDatabase, $CompletionEventsTable> {
  $$CompletionEventsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoutinesTableOrderingComposer get routineId {
    final $$RoutinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableOrderingComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HouseholdMembersTableOrderingComposer get completedByMemberId {
    final $$HouseholdMembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedByMemberId,
      referencedTable: $db.householdMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdMembersTableOrderingComposer(
            $db: $db,
            $table: $db.householdMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionEventsTableAnnotationComposer
    extends Composer<_$TailTallyDatabase, $CompletionEventsTable> {
  $$CompletionEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$RoutinesTableAnnotationComposer get routineId {
    final $$RoutinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.routineId,
      referencedTable: $db.routines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoutinesTableAnnotationComposer(
            $db: $db,
            $table: $db.routines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HouseholdMembersTableAnnotationComposer get completedByMemberId {
    final $$HouseholdMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedByMemberId,
      referencedTable: $db.householdMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.householdMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionEventsTableTableManager
    extends
        RootTableManager<
          _$TailTallyDatabase,
          $CompletionEventsTable,
          CompletionEventRow,
          $$CompletionEventsTableFilterComposer,
          $$CompletionEventsTableOrderingComposer,
          $$CompletionEventsTableAnnotationComposer,
          $$CompletionEventsTableCreateCompanionBuilder,
          $$CompletionEventsTableUpdateCompanionBuilder,
          (CompletionEventRow, $$CompletionEventsTableReferences),
          CompletionEventRow,
          PrefetchHooks Function({bool routineId, bool completedByMemberId})
        > {
  $$CompletionEventsTableTableManager(
    _$TailTallyDatabase db,
    $CompletionEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletionEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletionEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletionEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> routineId = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int?> completedByMemberId = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => CompletionEventsCompanion(
                id: id,
                routineId: routineId,
                completedAt: completedAt,
                kind: kind,
                completedByMemberId: completedByMemberId,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int routineId,
                required DateTime completedAt,
                Value<String> kind = const Value.absent(),
                Value<int?> completedByMemberId = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => CompletionEventsCompanion.insert(
                id: id,
                routineId: routineId,
                completedAt: completedAt,
                kind: kind,
                completedByMemberId: completedByMemberId,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CompletionEventsTable, CompletionEventRow>(
                    table,
                  ),
                  $$CompletionEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({routineId = false, completedByMemberId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (routineId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.routineId,
                            referencedTable: $$CompletionEventsTableReferences
                                ._routineIdTable(db),
                            referencedColumn: $$CompletionEventsTableReferences
                                ._routineIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (completedByMemberId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.completedByMemberId,
                            referencedTable: $$CompletionEventsTableReferences
                                ._completedByMemberIdTable(db),
                            referencedColumn: $$CompletionEventsTableReferences
                                ._completedByMemberIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$CompletionEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$TailTallyDatabase,
      $CompletionEventsTable,
      CompletionEventRow,
      $$CompletionEventsTableFilterComposer,
      $$CompletionEventsTableOrderingComposer,
      $$CompletionEventsTableAnnotationComposer,
      $$CompletionEventsTableCreateCompanionBuilder,
      $$CompletionEventsTableUpdateCompanionBuilder,
      (CompletionEventRow, $$CompletionEventsTableReferences),
      CompletionEventRow,
      PrefetchHooks Function({bool routineId, bool completedByMemberId})
    >;
typedef $$ReminderSettingsTableTableCreateCompanionBuilder =
    ReminderSettingsTableCompanion Function({
      required int id,
      required String payload,
      Value<int> rowid,
    });
typedef $$ReminderSettingsTableTableUpdateCompanionBuilder =
    ReminderSettingsTableCompanion Function({
      Value<int> id,
      Value<String> payload,
      Value<int> rowid,
    });

class $$ReminderSettingsTableTableFilterComposer
    extends Composer<_$TailTallyDatabase, $ReminderSettingsTableTable> {
  $$ReminderSettingsTableTableFilterComposer({
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

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReminderSettingsTableTableOrderingComposer
    extends Composer<_$TailTallyDatabase, $ReminderSettingsTableTable> {
  $$ReminderSettingsTableTableOrderingComposer({
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

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReminderSettingsTableTableAnnotationComposer
    extends Composer<_$TailTallyDatabase, $ReminderSettingsTableTable> {
  $$ReminderSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$ReminderSettingsTableTableTableManager
    extends
        RootTableManager<
          _$TailTallyDatabase,
          $ReminderSettingsTableTable,
          ReminderSettingRow,
          $$ReminderSettingsTableTableFilterComposer,
          $$ReminderSettingsTableTableOrderingComposer,
          $$ReminderSettingsTableTableAnnotationComposer,
          $$ReminderSettingsTableTableCreateCompanionBuilder,
          $$ReminderSettingsTableTableUpdateCompanionBuilder,
          (
            ReminderSettingRow,
            BaseReferences<
              _$TailTallyDatabase,
              $ReminderSettingsTableTable,
              ReminderSettingRow
            >,
          ),
          ReminderSettingRow,
          PrefetchHooks Function()
        > {
  $$ReminderSettingsTableTableTableManager(
    _$TailTallyDatabase db,
    $ReminderSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderSettingsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ReminderSettingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ReminderSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderSettingsTableCompanion(
                id: id,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int id,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => ReminderSettingsTableCompanion.insert(
                id: id,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReminderSettingsTableTable, ReminderSettingRow>(
                    table,
                  ),
                  BaseReferences<
                    _$TailTallyDatabase,
                    $ReminderSettingsTableTable,
                    ReminderSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReminderSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$TailTallyDatabase,
      $ReminderSettingsTableTable,
      ReminderSettingRow,
      $$ReminderSettingsTableTableFilterComposer,
      $$ReminderSettingsTableTableOrderingComposer,
      $$ReminderSettingsTableTableAnnotationComposer,
      $$ReminderSettingsTableTableCreateCompanionBuilder,
      $$ReminderSettingsTableTableUpdateCompanionBuilder,
      (
        ReminderSettingRow,
        BaseReferences<
          _$TailTallyDatabase,
          $ReminderSettingsTableTable,
          ReminderSettingRow
        >,
      ),
      ReminderSettingRow,
      PrefetchHooks Function()
    >;
typedef $$RetentionSettingsTableTableCreateCompanionBuilder =
    RetentionSettingsTableCompanion Function({
      required int id,
      required String payload,
      Value<int> rowid,
    });
typedef $$RetentionSettingsTableTableUpdateCompanionBuilder =
    RetentionSettingsTableCompanion Function({
      Value<int> id,
      Value<String> payload,
      Value<int> rowid,
    });

class $$RetentionSettingsTableTableFilterComposer
    extends Composer<_$TailTallyDatabase, $RetentionSettingsTableTable> {
  $$RetentionSettingsTableTableFilterComposer({
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

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RetentionSettingsTableTableOrderingComposer
    extends Composer<_$TailTallyDatabase, $RetentionSettingsTableTable> {
  $$RetentionSettingsTableTableOrderingComposer({
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

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RetentionSettingsTableTableAnnotationComposer
    extends Composer<_$TailTallyDatabase, $RetentionSettingsTableTable> {
  $$RetentionSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$RetentionSettingsTableTableTableManager
    extends
        RootTableManager<
          _$TailTallyDatabase,
          $RetentionSettingsTableTable,
          RetentionSettingRow,
          $$RetentionSettingsTableTableFilterComposer,
          $$RetentionSettingsTableTableOrderingComposer,
          $$RetentionSettingsTableTableAnnotationComposer,
          $$RetentionSettingsTableTableCreateCompanionBuilder,
          $$RetentionSettingsTableTableUpdateCompanionBuilder,
          (
            RetentionSettingRow,
            BaseReferences<
              _$TailTallyDatabase,
              $RetentionSettingsTableTable,
              RetentionSettingRow
            >,
          ),
          RetentionSettingRow,
          PrefetchHooks Function()
        > {
  $$RetentionSettingsTableTableTableManager(
    _$TailTallyDatabase db,
    $RetentionSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RetentionSettingsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RetentionSettingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RetentionSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RetentionSettingsTableCompanion(
                id: id,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int id,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => RetentionSettingsTableCompanion.insert(
                id: id,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $RetentionSettingsTableTable,
                    RetentionSettingRow
                  >(table),
                  BaseReferences<
                    _$TailTallyDatabase,
                    $RetentionSettingsTableTable,
                    RetentionSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RetentionSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$TailTallyDatabase,
      $RetentionSettingsTableTable,
      RetentionSettingRow,
      $$RetentionSettingsTableTableFilterComposer,
      $$RetentionSettingsTableTableOrderingComposer,
      $$RetentionSettingsTableTableAnnotationComposer,
      $$RetentionSettingsTableTableCreateCompanionBuilder,
      $$RetentionSettingsTableTableUpdateCompanionBuilder,
      (
        RetentionSettingRow,
        BaseReferences<
          _$TailTallyDatabase,
          $RetentionSettingsTableTable,
          RetentionSettingRow
        >,
      ),
      RetentionSettingRow,
      PrefetchHooks Function()
    >;

class $TailTallyDatabaseManager {
  final _$TailTallyDatabase _db;
  $TailTallyDatabaseManager(this._db);
  $$HouseholdMembersTableTableManager get householdMembers =>
      $$HouseholdMembersTableTableManager(_db, _db.householdMembers);
  $$PetsTableTableManager get pets => $$PetsTableTableManager(_db, _db.pets);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db, _db.routines);
  $$ScheduleWindowsTableTableManager get scheduleWindows =>
      $$ScheduleWindowsTableTableManager(_db, _db.scheduleWindows);
  $$CompletionEventsTableTableManager get completionEvents =>
      $$CompletionEventsTableTableManager(_db, _db.completionEvents);
  $$ReminderSettingsTableTableTableManager get reminderSettingsTable =>
      $$ReminderSettingsTableTableTableManager(_db, _db.reminderSettingsTable);
  $$RetentionSettingsTableTableTableManager get retentionSettingsTable =>
      $$RetentionSettingsTableTableTableManager(
        _db,
        _db.retentionSettingsTable,
      );
}
