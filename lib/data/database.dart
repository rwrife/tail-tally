import 'package:drift/drift.dart';

part 'database.g.dart';

/// Household members who can own or complete routines.
@DataClassName('HouseholdMemberRow')
class HouseholdMembers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName => text().withLength(min: 1, max: 120)();
  BoolColumn get isLocalDeviceOwner =>
      boolean().withDefault(const Constant(false))();
}

@DataClassName('PetRow')
class Pets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get species => text().withLength(min: 1, max: 60)();

  /// Optional file reference for a photo; bytes live outside the database.
  TextColumn get photoRef => text().nullable()();
}

@DataClassName('RoutineRow')
class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get petId =>
      integer().references(Pets, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  IntColumn get defaultAssigneeId => integer().nullable().references(
    HouseholdMembers,
    #id,
    onDelete: KeyAction.setNull,
  )();
}

@DataClassName('ScheduleWindowRow')
class ScheduleWindows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId =>
      integer().references(Routines, #id, onDelete: KeyAction.cascade)();

  /// Device-local wall-clock window bounds, e.g. 07:30 to 08:00.
  IntColumn get startHour => integer().withDefault(const Constant(0))();
  IntColumn get startMinute => integer().withDefault(const Constant(0))();
  IntColumn get endHour => integer().withDefault(const Constant(0))();
  IntColumn get endMinute => integer().withDefault(const Constant(0))();

  /// ISO weekdays (Mon=1..Sun=7) as a comma-separated list, e.g. "1,3,5".
  TextColumn get daysOfWeek =>
      text().withDefault(const Constant('1,2,3,4,5,6,7'))();

  BoolColumn get crossesMidnight =>
      boolean().withDefault(const Constant(false))();
}

/// Completion/skip log. `completedAt` is an absolute instant stored by
/// Drift as epoch milliseconds, so the history timeline is stable across
/// timezone changes and DST shifts (see the timestamp contract in
/// `lib/domain/entities.dart`).
@DataClassName('CompletionEventRow')
class CompletionEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId =>
      integer().references(Routines, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get kind => text().withDefault(const Constant('done'))();
  IntColumn get completedByMemberId => integer().nullable().references(
    HouseholdMembers,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get note => text().nullable()();
}

@DataClassName('ReminderSettingRow')
class ReminderSettingsTable extends Table {
  /// Singleton row — always id 1.
  IntColumn get id => integer()();

  /// JSON blob: {schemaVersion, notificationsEnabled, leadTimeMinutes,
  /// quietHours:{startMinutes,endMinutes}}. Versioned so future schema
  /// evolution inside the blob stays interpretable (issue #5 reuses this
  /// pattern for backups).
  TextColumn get payload => text()();
}

/// Retention preferences singleton (issue #5). Same singleton-blob
/// pattern as [ReminderSettingsTable]: empty table means "keep all"
/// (default), and the payload is versioned for future evolution.
@DataClassName('RetentionSettingRow')
class RetentionSettingsTable extends Table {
  /// Singleton row — always id 1.
  IntColumn get id => integer()();

  /// JSON blob: {schemaVersion, preference: keepAll|keep365Days|
  /// keep180Days|keep90Days}.
  TextColumn get payload => text()();
}

@DriftDatabase(
  tables: [
    HouseholdMembers,
    Pets,
    Routines,
    ScheduleWindows,
    CompletionEvents,
    ReminderSettingsTable,
    RetentionSettingsTable,
  ],
)
class TailTallyDatabase extends _$TailTallyDatabase {
  TailTallyDatabase(super.e);

  /// Current store schema version, exposed for backup manifests (issue #5)
  /// so exported files record which app schema produced them.
  static const currentSchemaVersion = 5;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // v3: DB-level duplicate guard — at most one `done` event per
      // (routine, instant). Skips keep their duplicates; only the
      // completion path is unique-constrained.
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS completion_events_done_unique '
        'ON completion_events (routine_id, completed_at) '
        "WHERE kind = 'done'",
      );
    },
    onUpgrade: (m, from, to) async {
      // v1 -> v2: completion events gained a free-form note field.
      if (from < 2) {
        await m.addColumn(completionEvents, completionEvents.note);
      }
      // v2 -> v3: partial unique index enforcing one `done` completion per
      // (routine, instant). Existing v2 data cannot violate it — the index
      // is created fresh and future inserts go through the workflow, which
      // never writes two `done` events for one window instance.
      if (from < 3) {
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS completion_events_done_unique '
          'ON completion_events (routine_id, completed_at) '
          "WHERE kind = 'done'",
        );
      }
      // v3 -> v4: reminder settings singleton table (issue #4). A fresh
      // empty table means "no user preferences yet" — reads fall back to
      // defaults, so no data backfill is required.
      if (from < 4) {
        await m.createTable(reminderSettingsTable);
      }
      // v4 -> v5: retention preferences singleton table (issue #5). Same
      // no-backfill rule: an empty table means the keep-all default.
      if (from < 5) {
        await m.createTable(retentionSettingsTable);
      }
    },
  );
}
