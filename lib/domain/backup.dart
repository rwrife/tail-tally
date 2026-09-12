/// Versioned JSON backup format (issue #5).
///
/// A backup is a single JSON document containing every table payload the
/// app owns plus explicit schema-compatibility metadata. Backups are pure
/// data structures: encoding/decoding happens here in plain Dart, and only
/// the `data/` layer touches the database when materializing one.
///
/// Timestamp contract: [BackupManifest.createdAtUtc] is an absolute
/// instant (UTC). Schedule-window fields inside [BackupSnapshot] stay
/// timezone-naive wall-clock values, exactly as stored (see the contract
/// in `lib/domain/entities.dart`).
library;

import 'dart:convert';

/// Thrown when a backup payload cannot be understood, with a
/// human-readable reason safe to show in the UI.
class BackupFormatException implements Exception {
  const BackupFormatException(this.reason);

  final String reason;

  @override
  String toString() => 'BackupFormatException: $reason';
}

/// Compatibility metadata embedded in every backup file.
class BackupManifest {
  const BackupManifest({
    required this.backupVersion,
    required this.appSchemaVersion,
    required this.createdAtUtc,
    this.deviceLabel,
  });

  /// Format version of the backup document itself. Bump only for
  /// breaking changes to the envelope; additive table changes keep it.
  static const currentBackupVersion = 1;

  /// Tail Tally's *minimum* app version that can import a backup of this
  /// backup version. Format v1 is additive-friendly, so v1 backups stay
  /// readable by schema v4 and later.
  static const minimumSchemaForBackupVersion = {currentBackupVersion: 4};

  /// The schema version of the app that produced the backup. An import
  /// from a *newer* app is refused — v1 has no forward-compat promise.
  final int backupVersion;
  final int appSchemaVersion;
  final DateTime createdAtUtc;
  final String? deviceLabel;

  static BackupManifest fromJson(Map<String, Object?> json) {
    final backupVersion = _asInt(json['backupVersion'], 'backupVersion');
    final appSchemaVersion = _asInt(
      json['appSchemaVersion'],
      'appSchemaVersion',
    );
    final created = _asString(json['createdAtUtc'], 'createdAtUtc');
    final createdAt = DateTime.tryParse(created);
    if (createdAt == null) {
      throw const BackupFormatException(
        'manifest.createdAtUtc is missing or not an ISO-8601 instant',
      );
    }
    return BackupManifest(
      backupVersion: backupVersion,
      appSchemaVersion: appSchemaVersion,
      createdAtUtc: createdAt.toUtc(),
      deviceLabel: json['deviceLabel'] is String
          ? json['deviceLabel']! as String
          : null,
    );
  }

  Map<String, Object?> toJson() => {
    'backupVersion': backupVersion,
    'appSchemaVersion': appSchemaVersion,
    'createdAtUtc': createdAtUtc.toIso8601String(),
    if (deviceLabel != null) 'deviceLabel': deviceLabel,
  };

  /// Decide whether an app running [appSchemaVersion] may import [manifest].
  ///
  /// Returns null when compatible, or a user-facing reason string.
  static String? checkCompatibility(
    BackupManifest manifest, {
    required int appSchemaVersion,
  }) {
    final minSchema = minimumSchemaForBackupVersion[manifest.backupVersion];
    if (minSchema == null) {
      return 'Backup format version ${manifest.backupVersion} is unknown to '
          'this app (supported: '
          '${minimumSchemaForBackupVersion.keys.join(", ")}).';
    }
    if (appSchemaVersion < minSchema) {
      return 'This backup needs Tail Tally with data schema v$minSchema or '
          'newer; this device is on schema v$appSchemaVersion.';
    }
    if (manifest.appSchemaVersion > appSchemaVersion) {
      return 'This backup came from a newer Tail Tally (schema '
          'v${manifest.appSchemaVersion}); update the app before importing.';
    }
    return null;
  }
}

/// One household member in a backup (id preserved for cross-references).
class BackupMember {
  const BackupMember({
    required this.id,
    required this.displayName,
    this.isLocalDeviceOwner = false,
  });

  final int id;
  final String displayName;
  final bool isLocalDeviceOwner;

  Map<String, Object?> toJson() => {
    'id': id,
    'displayName': displayName,
    'isLocalDeviceOwner': isLocalDeviceOwner,
  };

  static BackupMember fromJson(Map<String, Object?> json) => BackupMember(
    id: _asInt(json['id'], 'member.id'),
    displayName: _asString(json['displayName'], 'member.displayName'),
    isLocalDeviceOwner: json['isLocalDeviceOwner'] == true,
  );
}

class BackupPet {
  const BackupPet({
    required this.id,
    required this.name,
    required this.species,
    this.photoRef,
  });

  final int id;
  final String name;
  final String species;
  final String? photoRef;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'species': species,
    if (photoRef != null) 'photoRef': photoRef,
  };

  static BackupPet fromJson(Map<String, Object?> json) => BackupPet(
    id: _asInt(json['id'], 'pet.id'),
    name: _asString(json['name'], 'pet.name'),
    species: _asString(json['species'], 'pet.species'),
    photoRef: json['photoRef'] is String ? json['photoRef']! as String : null,
  );
}

class BackupRoutine {
  const BackupRoutine({
    required this.id,
    required this.petId,
    required this.name,
    this.defaultAssigneeId,
  });

  final int id;
  final int petId;
  final String name;
  final int? defaultAssigneeId;

  Map<String, Object?> toJson() => {
    'id': id,
    'petId': petId,
    'name': name,
    if (defaultAssigneeId != null) 'defaultAssigneeId': defaultAssigneeId,
  };

  static BackupRoutine fromJson(Map<String, Object?> json) => BackupRoutine(
    id: _asInt(json['id'], 'routine.id'),
    petId: _asInt(json['petId'], 'routine.petId'),
    name: _asString(json['name'], 'routine.name'),
    defaultAssigneeId: json['defaultAssigneeId'] is int
        ? json['defaultAssigneeId']! as int
        : null,
  );
}

class BackupScheduleWindow {
  const BackupScheduleWindow({
    required this.id,
    required this.routineId,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.daysOfWeek,
    this.crossesMidnight = false,
  });

  final int id;
  final int routineId;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final Set<int> daysOfWeek;
  final bool crossesMidnight;

  Map<String, Object?> toJson() => {
    'id': id,
    'routineId': routineId,
    'startHour': startHour,
    'startMinute': startMinute,
    'endHour': endHour,
    'endMinute': endMinute,
    'daysOfWeek': (daysOfWeek.toList()..sort()).join(','),
    'crossesMidnight': crossesMidnight,
  };

  static BackupScheduleWindow fromJson(Map<String, Object?> json) {
    final rawDays = _asString(json['daysOfWeek'], 'window.daysOfWeek');
    final days = rawDays
        .split(',')
        .where((s) => s.trim().isNotEmpty)
        .map((s) => int.parse(s.trim()))
        .toSet();
    return BackupScheduleWindow(
      id: _asInt(json['id'], 'window.id'),
      routineId: _asInt(json['routineId'], 'window.routineId'),
      startHour: _asInt(json['startHour'], 'window.startHour'),
      startMinute: _asInt(json['startMinute'], 'window.startMinute'),
      endHour: _asInt(json['endHour'], 'window.endHour'),
      endMinute: _asInt(json['endMinute'], 'window.endMinute'),
      daysOfWeek: days,
      crossesMidnight: json['crossesMidnight'] == true,
    );
  }
}

class BackupCompletion {
  const BackupCompletion({
    required this.routineId,
    required this.completedAtUtc,
    required this.kind,
    this.completedByMemberId,
    this.note,
  });

  final int routineId;

  /// Always normalized to UTC on encode and decode.
  final DateTime completedAtUtc;
  final String kind;
  final int? completedByMemberId;
  final String? note;

  Map<String, Object?> toJson() => {
    'routineId': routineId,
    'completedAtUtc': completedAtUtc.toUtc().toIso8601String(),
    'kind': kind,
    if (completedByMemberId != null) 'completedByMemberId': completedByMemberId,
    if (note != null) 'note': note,
  };

  static BackupCompletion fromJson(Map<String, Object?> json) {
    final raw = _asString(json['completedAtUtc'], 'completion.completedAtUtc');
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw const BackupFormatException(
        'a completion event has a missing or unparseable completedAtUtc',
      );
    }
    return BackupCompletion(
      routineId: _asInt(json['routineId'], 'completion.routineId'),
      completedAtUtc: parsed.toUtc(),
      kind: json['kind'] is String ? json['kind']! as String : 'done',
      completedByMemberId: json['completedByMemberId'] is int
          ? json['completedByMemberId']! as int
          : null,
      note: json['note'] is String ? json['note']! as String : null,
    );
  }
}

/// The full contents of one backup document.
class BackupSnapshot {
  const BackupSnapshot({
    required this.manifest,
    this.members = const [],
    this.pets = const [],
    this.routines = const [],
    this.windows = const [],
    this.completions = const [],
    this.reminderSettingsJson,
    this.retentionSettingsJson,
  });

  final BackupManifest manifest;
  final List<BackupMember> members;
  final List<BackupPet> pets;
  final List<BackupRoutine> routines;
  final List<BackupScheduleWindow> windows;
  final List<BackupCompletion> completions;

  /// Opaque pass-through of the versioned reminder-settings blob.
  final String? reminderSettingsJson;

  /// Opaque pass-through of the versioned retention-settings blob.
  final String? retentionSettingsJson;

  Map<String, Object?> toJson() => {
    'manifest': manifest.toJson(),
    'members': members.map((m) => m.toJson()).toList(),
    'pets': pets.map((p) => p.toJson()).toList(),
    'routines': routines.map((r) => r.toJson()).toList(),
    'scheduleWindows': windows.map((w) => w.toJson()).toList(),
    'completionEvents': completions.map((c) => c.toJson()).toList(),
    if (reminderSettingsJson != null)
      'reminderSettings': jsonDecode(reminderSettingsJson!) as Object?,
    if (retentionSettingsJson != null)
      'retentionSettings': jsonDecode(retentionSettingsJson!) as Object?,
  };

  static BackupSnapshot fromJson(Map<String, Object?> json) {
    final manifestJson = json['manifest'];
    if (manifestJson is! Map<String, Object?>) {
      throw const BackupFormatException('backup has no "manifest" object');
    }
    return BackupSnapshot(
      manifest: BackupManifest.fromJson(manifestJson),
      members: _objectList(
        json['members'],
        'members',
      ).map(BackupMember.fromJson).toList(),
      pets: _objectList(json['pets'], 'pets').map(BackupPet.fromJson).toList(),
      routines: _objectList(
        json['routines'],
        'routines',
      ).map(BackupRoutine.fromJson).toList(),
      windows: _objectList(
        json['scheduleWindows'],
        'scheduleWindows',
      ).map(BackupScheduleWindow.fromJson).toList(),
      completions: _objectList(
        json['completionEvents'],
        'completionEvents',
      ).map(BackupCompletion.fromJson).toList(),
      reminderSettingsJson: json['reminderSettings'] == null
          ? null
          : jsonEncode(json['reminderSettings']),
      retentionSettingsJson: json['retentionSettings'] == null
          ? null
          : jsonEncode(json['retentionSettings']),
    );
  }
}

/// Encode [snapshot] as pretty-printed JSON text for a backup file.
String encodeBackup(BackupSnapshot snapshot) =>
    const JsonEncoder.withIndent('  ').convert(snapshot.toJson());

/// Parse backup file text, rejecting anything that is not a JSON object.
BackupSnapshot decodeBackup(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    throw BackupFormatException('not valid JSON: ${e.message}');
  }
  if (decoded is! Map<String, Object?>) {
    throw const BackupFormatException('backup root must be a JSON object');
  }
  return BackupSnapshot.fromJson(decoded);
}

/// Referential-integrity validation applied before an import writes
/// anything. Returns null when [snapshot] can be materialized, otherwise
/// a user-facing reason.
String? validateSnapshot(BackupSnapshot snapshot) {
  final petIds = snapshot.pets.map((p) => p.id).toSet();
  if (petIds.length != snapshot.pets.length) {
    return 'backup contains duplicate pet ids';
  }
  final memberIds = snapshot.members.map((m) => m.id).toSet();
  final routineIds = snapshot.routines.map((r) => r.id).toSet();
  if (routineIds.length != snapshot.routines.length) {
    return 'backup contains duplicate routine ids';
  }
  for (final routine in snapshot.routines) {
    if (!petIds.contains(routine.petId)) {
      return 'routine "${routine.name}" references pet ${routine.petId}, '
          'which is not in the backup';
    }
    if (routine.defaultAssigneeId != null &&
        !memberIds.contains(routine.defaultAssigneeId)) {
      return 'routine "${routine.name}" references household member '
          '${routine.defaultAssigneeId}, which is not in the backup';
    }
  }
  for (final window in snapshot.windows) {
    if (!routineIds.contains(window.routineId)) {
      return 'a schedule window references routine ${window.routineId}, '
          'which is not in the backup';
    }
  }
  for (final completion in snapshot.completions) {
    if (!routineIds.contains(completion.routineId)) {
      return 'a completion event references routine ${completion.routineId}, '
          'which is not in the backup';
    }
    if (completion.completedByMemberId != null &&
        !memberIds.contains(completion.completedByMemberId)) {
      return 'a completion event references household member '
          '${completion.completedByMemberId}, which is not in the backup';
    }
  }
  return null;
}

List<Map<String, Object?>> _objectList(Object? value, String field) {
  if (value == null) return const [];
  if (value is! List) {
    throw BackupFormatException('"$field" must be a list');
  }
  return value.map((e) {
    if (e is! Map<String, Object?>) {
      throw BackupFormatException('"$field" contains a non-object entry');
    }
    return e;
  }).toList();
}

int _asInt(Object? value, String field) {
  if (value is! int) {
    throw BackupFormatException('"$field" is missing or not an integer');
  }
  return value;
}

String _asString(Object? value, String field) {
  if (value is! String) {
    throw BackupFormatException('"$field" is missing or not a string');
  }
  return value;
}
