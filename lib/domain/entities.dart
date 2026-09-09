/// Domain entities and repository contracts for Tail Tally's local data model.
///
/// This file is pure Dart: it must not import Flutter, Drift/SQLite,
/// platform channels, or any network or account service.
///
/// Timestamp contract
/// ------------------
/// Completion events are the only data in the model that pins an absolute
/// instant, so they are stored as UTC [DateTime] values (`DateTime.toUtc()`
/// is enforced by the repository layer). Every other timestamp field —
/// schedule-window daily times and per-day targets — is *wall-clock* data:
/// a (dayOfYear, hour, minute) pair with no timezone attached. The device's
/// local timezone is the single source of truth for interpreting wall-clock
/// values, so DST shifts and timezone travel move routine windows exactly as
/// a household expects ("feed at 07:30 local"), while completion history
/// stays on a stable UTC timeline. Mixed-offset instants in exported or
/// imported data must be normalized with `toUtc()` before being written.
library;

/// A member of the household who can own or complete routines.
class HouseholdMember {
  const HouseholdMember({
    required this.id,
    required this.displayName,
    this.isLocalDeviceOwner = false,
  });

  final int id;
  final String displayName;

  /// True for the member representing whoever is holding this device.
  final bool isLocalDeviceOwner;
}

/// A pet profile. Photos stay out of the database (file references only)
/// so the store remains compact and export-friendly.
class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.species,
    this.photoRef,
  });

  final int id;
  final String name;

  /// Free-form species label (dog, cat, rabbit, ...) — no clinical data.
  final String species;
  final String? photoRef;
}

/// A reusable routine template such as "Morning feed" or "Litter scoop".
class Routine {
  const Routine({
    required this.id,
    required this.petId,
    required this.name,
    this.defaultAssigneeId,
  });

  final int id;
  final int petId;
  final String name;

  /// Member normally responsible for this routine, if the household
  /// pre-assigns defaults. Null means "whoever is around".
  final int? defaultAssigneeId;
}

/// A recurring time window in which a routine should happen.
class ScheduleWindow {
  const ScheduleWindow({
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

  /// Daily start/end time of the window, as device-local wall clock.
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  /// ISO weekdays (Mon=1 .. Sun=7) on which the window is active.
  final Set<int> daysOfWeek;

  /// True when the window wraps past midnight (e.g. 22:00 to 06:00).
  final bool crossesMidnight;
}

/// A single recorded instance of a routine being done (or explicitly
/// skipped) at an absolute instant.
class CompletionEvent {
  const CompletionEvent({
    required this.id,
    required this.routineId,
    required this.completedAtUtc,
    required this.kind,
    this.completedByMemberId,
    this.note,
  });

  final int id;
  final int routineId;

  /// Absolute instant of the completion, always in UTC.
  final DateTime completedAtUtc;
  final CompletionKind kind;

  /// Who completed it — the handoff marker in shared households.
  final int? completedByMemberId;
  final String? note;
}

enum CompletionKind { done, skipped }

/// Insertion draft for a new pet (id not yet assigned).
class NewPet {
  const NewPet({required this.name, required this.species, this.photoRef});

  final String name;
  final String species;
  final String? photoRef;
}

/// Insertion draft for a new household member.
class NewMember {
  const NewMember({required this.displayName, this.isLocalDeviceOwner = false});

  final String displayName;
  final bool isLocalDeviceOwner;
}

/// Insertion draft for a new routine.
class NewRoutine {
  const NewRoutine({
    required this.petId,
    required this.name,
    this.defaultAssigneeId,
  });

  final int petId;
  final String name;
  final int? defaultAssigneeId;
}

/// Insertion draft for a new schedule window.
class NewScheduleWindow {
  const NewScheduleWindow({
    required this.routineId,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.daysOfWeek,
    this.crossesMidnight = false,
  });

  final int routineId;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final Set<int> daysOfWeek;
  final bool crossesMidnight;
}

/// Insertion draft for a completion event.
class NewCompletionEvent {
  const NewCompletionEvent({
    required this.routineId,
    required this.completedAtUtc,
    required this.kind,
    this.completedByMemberId,
    this.note,
  });

  final int routineId;
  final DateTime completedAtUtc;
  final CompletionKind kind;
  final int? completedByMemberId;
  final String? note;
}

/// Read/write contract for Tail Tally's local store.
///
/// Implementations live in `lib/data/`; the domain and app layers only ever
/// see this interface. All clock reads go through [clock] so behavior around
/// "due now" logic is testable and deterministic.
abstract class LocalDataRepository {
  /// Supply the current time; injected for deterministic tests.
  DateTime now();

  Future<void> ensureOpen();
  Future<void> close();

  Future<HouseholdMember> addMember(NewMember draft);
  Future<List<HouseholdMember>> listMembers();
  Future<void> renameMember(int id, String displayName);
  Future<void> removeMember(int id);

  Future<Pet> addPet(NewPet draft);
  Future<List<Pet>> listPets();
  Future<Pet> updatePet(Pet pet);
  Future<void> removePet(int id);

  Future<Routine> addRoutine(NewRoutine draft);
  Future<List<Routine>> listRoutines({int? petId});
  Future<void> removeRoutine(int id);

  Future<ScheduleWindow> addScheduleWindow(NewScheduleWindow draft);
  Future<List<ScheduleWindow>> listScheduleWindows({int? routineId});
  Future<void> removeScheduleWindow(int id);

  Future<CompletionEvent> recordCompletion(NewCompletionEvent draft);
  Future<List<CompletionEvent>> listCompletions({
    int? routineId,
    DateTime? fromUtc,
    DateTime? toUtc,
  });

  /// Most recent completion for [routineId], or null if never completed.
  Future<CompletionEvent?> lastCompletionFor(int routineId);

  /// Undo a mistaken completion by removing the event entirely.
  Future<void> deleteCompletion(int id);
}
