/// Complete/undo workflow with duplicate-completion guardrails (issue #3).
///
/// Pure Dart against the repository contract. The UI layer keeps undo
/// *bounded* (only recent completions are offered for undo); the workflow
/// itself provides the operations and the guards.
library;

import 'entities.dart';
import 'schedule.dart';

/// Outcome of a completion attempt.
sealed class CompletionOutcome {
  const CompletionOutcome();
}

/// The completion was recorded.
class Completed extends CompletionOutcome {
  const Completed(this.event);
  final CompletionEvent event;
}

/// The instance already has a satisfying `done` completion — the guard
/// refused to record a duplicate.
class AlreadyCompleted extends CompletionOutcome {
  const AlreadyCompleted(this.existing);
  final CompletionEvent existing;
}

/// Records and removes completions for window instances.
class TaskWorkflow {
  TaskWorkflow(this.repo);

  final LocalDataRepository repo;

  /// One-tap completion of [instance] at the repo clock time.
  ///
  /// [note] is optional free-form text. [memberId] is who is completing it
  /// (the shared-handoff marker); null stores no attribution.
  ///
  /// Returns [AlreadyCompleted] — without writing anything — when the
  /// instance is already satisfied, so double-taps, retries, and two
  /// household members racing do not produce duplicate log entries for the
  /// same window instance. The check and the insert run inside one SQLite
  /// transaction (with the immediate-writer lock held), and the schema adds
  /// a partial unique index on `done` events per (routine, instant), so the
  /// guard holds under real concurrency.
  Future<CompletionOutcome> complete(
    WindowInstance instance, {
    String? note,
    int? memberId,
  }) async {
    return repo.transaction(() async {
      final existing = satisfyingCompletion(
        instance,
        await repo.listCompletions(routineId: instance.window.routineId),
      );
      if (existing != null) return AlreadyCompleted(existing);
      final event = await repo.recordCompletion(
        NewCompletionEvent(
          routineId: instance.window.routineId,
          completedAtUtc: repo.now(),
          kind: CompletionKind.done,
          completedByMemberId: memberId,
          note: note,
        ),
      );
      return Completed(event);
    });
  }

  /// Undo by removing the completion event entirely (audit-clean: the log
  /// is a record of verified facts, not corrections).
  Future<void> undo(int completionId) => repo.deleteCompletion(completionId);

  /// Convenience guard the UI uses to decide whether an instance can still
  /// be completed.
  Future<bool> isSatisfied(WindowInstance instance) async {
    final existing = satisfyingCompletion(
      instance,
      await repo.listCompletions(routineId: instance.window.routineId),
    );
    return existing != null;
  }
}

/// Bounded undo ledger: remembers only the most recent [capacity] completions
/// made in this app session, newest first. Older completions can no longer be
/// undone from the timeline UI (they can still be corrected via history in a
/// later slice), which keeps the undo surface small and predictable.
class UndoLedger {
  UndoLedger({this.capacity = 3});

  final int capacity;
  final List<int> _ids = [];

  void record(int completionId) {
    _ids.insert(0, completionId);
    if (_ids.length > capacity) _ids.removeRange(capacity, _ids.length);
  }

  List<int> get undoableIds => List.unmodifiable(_ids);

  bool canUndo(int completionId) => _ids.contains(completionId);

  void forget(int completionId) => _ids.remove(completionId);
}
