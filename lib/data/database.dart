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

@DriftDatabase(
  tables: [HouseholdMembers, Pets, Routines, ScheduleWindows, CompletionEvents],
)
class TailTallyDatabase extends _$TailTallyDatabase {
  TailTallyDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
    onUpgrade: (m, from, to) async {
      // v1 -> v2: completion events gained a free-form note field.
      if (from < 2) {
        await m.addColumn(completionEvents, completionEvents.note);
      }
    },
  );
}
