import 'package:drift/drift.dart';

import '../domain/entities.dart';
import 'database.dart';

/// Drift-backed implementation of [LocalDataRepository].
///
/// Timestamp contract: completion instants are normalized to UTC before
/// being written; everything else (schedule windows) is stored as
/// timezone-naive wall-clock values interpreted in the device's current
/// local timezone at read time. See the doc in `lib/domain/entities.dart`.
class DriftLocalDataRepository implements LocalDataRepository {
  DriftLocalDataRepository(this.db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final TailTallyDatabase db;
  final DateTime Function() _clock;

  @override
  DateTime now() => _clock();

  @override
  Future<void> ensureOpen() => db.customSelect('SELECT 1').get();

  @override
  Future<void> close() => db.close();

  @override
  Future<T> transaction<T>(Future<T> Function() action) =>
      db.transaction(action);

  // ---------------------------------------------------------------- members

  @override
  Future<HouseholdMember> addMember(NewMember draft) async {
    final row = HouseholdMembersCompanion.insert(
      displayName: draft.displayName,
      isLocalDeviceOwner: Value(draft.isLocalDeviceOwner),
    );
    final id = await db.into(db.householdMembers).insert(row);
    return _memberById(id);
  }

  @override
  Future<List<HouseholdMember>> listMembers() async {
    final rows = await db.select(db.householdMembers).get();
    return rows.map(_toMember).toList();
  }

  @override
  Future<void> renameMember(int id, String displayName) {
    final query = db.update(db.householdMembers)..where((r) => r.id.equals(id));
    return query.write(
      HouseholdMembersCompanion(displayName: Value(displayName)),
    );
  }

  @override
  Future<void> removeMember(int id) {
    return (db.delete(db.householdMembers)..where((r) => r.id.equals(id))).go();
  }

  // ------------------------------------------------------------------- pets

  @override
  Future<Pet> addPet(NewPet draft) async {
    final id = await db
        .into(db.pets)
        .insert(
          PetsCompanion.insert(
            name: draft.name,
            species: draft.species,
            photoRef: Value(draft.photoRef),
          ),
        );
    return _petById(id);
  }

  @override
  Future<List<Pet>> listPets() async {
    final rows = await db.select(db.pets).get();
    return rows.map(_toPet).toList();
  }

  @override
  Future<Pet> updatePet(Pet pet) async {
    await db
        .update(db.pets)
        .replace(
          PetRow(
            id: pet.id,
            name: pet.name,
            species: pet.species,
            photoRef: pet.photoRef,
          ),
        );
    return _petById(pet.id);
  }

  @override
  Future<void> removePet(int id) {
    return (db.delete(db.pets)..where((r) => r.id.equals(id))).go();
  }

  // --------------------------------------------------------------- routines

  @override
  Future<Routine> addRoutine(NewRoutine draft) async {
    final id = await db
        .into(db.routines)
        .insert(
          RoutinesCompanion.insert(
            petId: draft.petId,
            name: draft.name,
            defaultAssigneeId: Value(draft.defaultAssigneeId),
          ),
        );
    return _routineById(id);
  }

  @override
  Future<List<Routine>> listRoutines({int? petId}) async {
    final query = db.select(db.routines);
    if (petId != null) query.where((r) => r.petId.equals(petId));
    return (await query.get()).map(_toRoutine).toList();
  }

  @override
  Future<void> removeRoutine(int id) {
    return (db.delete(db.routines)..where((r) => r.id.equals(id))).go();
  }

  // -------------------------------------------------------- schedule windows

  @override
  Future<ScheduleWindow> addScheduleWindow(NewScheduleWindow draft) async {
    final id = await db
        .into(db.scheduleWindows)
        .insert(
          ScheduleWindowsCompanion.insert(
            routineId: draft.routineId,
            startHour: Value(draft.startHour),
            startMinute: Value(draft.startMinute),
            endHour: Value(draft.endHour),
            endMinute: Value(draft.endMinute),
            daysOfWeek: Value(_encodeDays(draft.daysOfWeek)),
            crossesMidnight: Value(draft.crossesMidnight),
          ),
        );
    return _windowById(id);
  }

  @override
  Future<List<ScheduleWindow>> listScheduleWindows({int? routineId}) async {
    final query = db.select(db.scheduleWindows);
    if (routineId != null) query.where((r) => r.routineId.equals(routineId));
    return (await query.get()).map(_toWindow).toList();
  }

  @override
  Future<void> removeScheduleWindow(int id) {
    return (db.delete(db.scheduleWindows)..where((r) => r.id.equals(id))).go();
  }

  // ----------------------------------------------------- completion events

  @override
  Future<CompletionEvent> recordCompletion(NewCompletionEvent draft) async {
    final id = await db
        .into(db.completionEvents)
        .insert(
          CompletionEventsCompanion.insert(
            routineId: draft.routineId,
            completedAt: draft.completedAtUtc.toUtc(),
            kind: Value(draft.kind.name),
            completedByMemberId: Value(draft.completedByMemberId),
            note: Value(draft.note),
          ),
        );
    final row = await (db.select(
      db.completionEvents,
    )..where((r) => r.id.equals(id))).getSingle();
    return _toCompletion(row);
  }

  @override
  Future<List<CompletionEvent>> listCompletions({
    int? routineId,
    DateTime? fromUtc,
    DateTime? toUtc,
  }) async {
    final query = db.select(db.completionEvents)
      ..orderBy([(r) => OrderingTerm.desc(r.completedAt)]);
    if (routineId != null) {
      query.where((r) => r.routineId.equals(routineId));
    }
    if (fromUtc != null) {
      query.where((r) => r.completedAt.isBiggerOrEqualValue(fromUtc.toUtc()));
    }
    if (toUtc != null) {
      query.where((r) => r.completedAt.isSmallerThanValue(toUtc.toUtc()));
    }
    return (await query.get()).map(_toCompletion).toList();
  }

  @override
  Future<CompletionEvent?> lastCompletionFor(int routineId) async {
    final query = db.select(db.completionEvents)
      ..where((r) => r.routineId.equals(routineId))
      ..orderBy([(r) => OrderingTerm.desc(r.completedAt)])
      ..limit(1);
    final rows = await query.get();
    if (rows.isEmpty) return null;
    return _toCompletion(rows.first);
  }

  @override
  Future<void> deleteCompletion(int id) {
    return (db.delete(db.completionEvents)..where((r) => r.id.equals(id))).go();
  }

  // ------------------------------------------------------ reminder settings

  static const _settingsId = 1;

  @override
  Future<String?> readReminderSettingsJson() async {
    final rows = await (db.select(
      db.reminderSettingsTable,
    )..where((r) => r.id.equals(_settingsId))).get();
    if (rows.isEmpty) return null;
    return rows.first.payload;
  }

  @override
  Future<void> writeReminderSettingsJson(String payload) {
    return db.transaction(() async {
      await db.delete(db.reminderSettingsTable).go();
      await db
          .into(db.reminderSettingsTable)
          .insert(
            ReminderSettingRow(id: _settingsId, payload: payload),
            mode: InsertMode.insertOrReplace,
          );
    });
  }

  // ------------------------------------------------------------- conversions

  static String _encodeDays(Set<int> days) {
    final sorted = days.toList()..sort();
    return sorted.join(',');
  }

  static Set<int> _decodeDays(String raw) => raw
      .split(',')
      .where((s) => s.trim().isNotEmpty)
      .map((s) => int.parse(s.trim()))
      .toSet();

  HouseholdMember _toMember(HouseholdMemberRow r) => HouseholdMember(
    id: r.id,
    displayName: r.displayName,
    isLocalDeviceOwner: r.isLocalDeviceOwner,
  );

  Future<HouseholdMember> _memberById(int id) async {
    final row = await (db.select(
      db.householdMembers,
    )..where((r) => r.id.equals(id))).getSingle();
    return _toMember(row);
  }

  Pet _toPet(PetRow r) =>
      Pet(id: r.id, name: r.name, species: r.species, photoRef: r.photoRef);

  Future<Pet> _petById(int id) async {
    final row = await (db.select(
      db.pets,
    )..where((r) => r.id.equals(id))).getSingle();
    return _toPet(row);
  }

  Routine _toRoutine(RoutineRow r) => Routine(
    id: r.id,
    petId: r.petId,
    name: r.name,
    defaultAssigneeId: r.defaultAssigneeId,
  );

  Future<Routine> _routineById(int id) async {
    final row = await (db.select(
      db.routines,
    )..where((r) => r.id.equals(id))).getSingle();
    return _toRoutine(row);
  }

  ScheduleWindow _toWindow(ScheduleWindowRow r) => ScheduleWindow(
    id: r.id,
    routineId: r.routineId,
    startHour: r.startHour,
    startMinute: r.startMinute,
    endHour: r.endHour,
    endMinute: r.endMinute,
    daysOfWeek: _decodeDays(r.daysOfWeek),
    crossesMidnight: r.crossesMidnight,
  );

  Future<ScheduleWindow> _windowById(int id) async {
    final row = await (db.select(
      db.scheduleWindows,
    )..where((r) => r.id.equals(id))).getSingle();
    return _toWindow(row);
  }

  CompletionEvent _toCompletion(CompletionEventRow r) => CompletionEvent(
    id: r.id,
    routineId: r.routineId,
    completedAtUtc: r.completedAt.toUtc(),
    kind: CompletionKind.values.firstWhere(
      (k) => k.name == r.kind,
      orElse: () => CompletionKind.done,
    ),
    completedByMemberId: r.completedByMemberId,
    note: r.note,
  );
}
