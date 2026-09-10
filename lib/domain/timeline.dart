/// Daily timeline assembly for the primary workflow (issue #3).
///
/// Pure Dart: depends only on the repository contract and scheduling rules.
library;

import 'entities.dart';
import 'schedule.dart';

/// One row of the day's timeline: a window instance resolved against its
/// routine, pet, and (when satisfied) the completion that covers it.
class TimelineEntry {
  const TimelineEntry({
    required this.instance,
    required this.routine,
    required this.pet,
    required this.status,
    this.completion,
    this.completedByName,
  });

  final WindowInstance instance;
  final Routine routine;
  final Pet pet;
  final TaskStatus status;

  /// The `done` event that satisfies this instance, if any.
  final CompletionEvent? completion;

  /// Display name of the household member who completed it — the
  /// shared-handoff marker. Null while the instance is not completed.
  final String? completedByName;
}

/// Groups timeline entries the way the UI displays them.
enum TimelineGroup {
  overdue,
  due,
  scheduled,
  completed;

  static const List<TimelineGroup> displayOrder = [
    TimelineGroup.overdue,
    TimelineGroup.due,
    TimelineGroup.scheduled,
    TimelineGroup.completed,
  ];

  static TimelineGroup of(TaskStatus status) =>
      TimelineGroup.values.firstWhere((g) => g.name == status.name);
}

/// Builds the day timeline from local data.
class DailyTimelineBuilder {
  DailyTimelineBuilder(this.repo);

  final LocalDataRepository repo;

  /// Completions are fetched this far back so the "previous window close"
  /// lower bound in [satisfyingCompletion] can always find a match.
  static const _completionLookback = Duration(days: 30);

  /// Entries for the local day of [localNow] (default: repo clock).
  ///
  /// [petIds] narrows the view to selected pets; null means all pets.
  Future<List<TimelineEntry>> build({
    DateTime? localNow,
    Set<int>? petIds,
  }) async {
    final now = localNow ?? repo.now();
    final day = dayStart(now);

    final pets = (await repo.listPets())
        .where((p) => petIds == null || petIds.contains(p.id))
        .toList();
    if (pets.isEmpty) return const [];
    final petsById = {for (final p in pets) p.id: p};

    final routines = (await repo.listRoutines())
        .where((r) => petsById.containsKey(r.petId))
        .toList();
    if (routines.isEmpty) return const [];
    final routinesById = {for (final r in routines) r.id: r};

    final windows = (await repo.listScheduleWindows())
        .where((w) => routinesById.containsKey(w.routineId))
        .toList();

    final since = day.subtract(_completionLookback);
    final completions = await repo.listCompletions(fromUtc: since);
    final completionsByRoutine = <int, List<CompletionEvent>>{};
    for (final c in completions) {
      completionsByRoutine.putIfAbsent(c.routineId, () => []).add(c);
    }
    final members = {for (final m in await repo.listMembers()) m.id: m};

    final entries = <TimelineEntry>[];
    final seen = <({int windowId, DateTime start})>{};
    for (final window in windows) {
      for (final instance in instancesActiveOn(window, day)) {
        final key = (windowId: window.id, start: instance.start);
        if (!seen.add(key)) continue;
        final completion = satisfyingCompletion(
          instance,
          completionsByRoutine[window.routineId] ?? const [],
        );
        final status = statusOf(
          instance,
          localNow: now,
          completion: completion,
        );
        entries.add(
          TimelineEntry(
            instance: instance,
            routine: routinesById[window.routineId]!,
            pet: petsById[routinesById[window.routineId]!.petId]!,
            status: status,
            completion: completion,
            completedByName: completion?.completedByMemberId == null
                ? null
                : members[completion!.completedByMemberId]?.displayName,
          ),
        );
      }
    }

    int compare(TimelineEntry a, TimelineEntry b) {
      final byGroup = TimelineGroup.displayOrder
          .indexOf(TimelineGroup.of(a.status))
          .compareTo(
            TimelineGroup.displayOrder.indexOf(TimelineGroup.of(b.status)),
          );
      if (byGroup != 0) return byGroup;
      return a.instance.start.compareTo(b.instance.start);
    }

    return entries..sort(compare);
  }

  /// Entries bucketed by display group, in [TimelineGroup.displayOrder].
  Future<Map<TimelineGroup, List<TimelineEntry>>> buildGrouped({
    DateTime? localNow,
    Set<int>? petIds,
  }) async {
    final entries = await build(localNow: localNow, petIds: petIds);
    final grouped = <TimelineGroup, List<TimelineEntry>>{
      for (final g in TimelineGroup.displayOrder) g: <TimelineEntry>[],
    };
    for (final e in entries) {
      grouped[TimelineGroup.of(e.status)]!.add(e);
    }
    return grouped;
  }
}
