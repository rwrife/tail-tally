/// Pure-Dart scheduling rules for turning [ScheduleWindow]s into concrete
/// daily task instances and evaluating their status.
///
/// Wall-clock contract: windows are device-local wall-clock data (see the
/// timestamp contract in `entities.dart`). All functions here take a
/// *local* `DateTime` for "now" and produce *local* [DateTime] instance
/// bounds. Completion matching converts instance bounds with `toUtc()` so
/// comparisons happen entirely in UTC.
library;

import 'entities.dart';

/// Where a scheduled task instance stands right now.
enum TaskStatus {
  /// The window already closed and nothing satisfied it.
  overdue,

  /// The window is open at the current instant.
  due,

  /// The window belongs to the current day list but has not opened yet.
  scheduled,

  /// A `done` completion satisfies this instance.
  completed,
}

/// A concrete occurrence of a [ScheduleWindow] with absolute local bounds.
///
/// The instance "belongs" to the day its window starts on. A window that
/// crosses midnight produces an instance whose [end] lands on the next day;
/// the morning tail of that instance is still attributed to the previous day.
class WindowInstance {
  const WindowInstance({
    required this.window,
    required this.start,
    required this.end,
  });

  final ScheduleWindow window;

  /// Local wall-clock instant the window opens.
  final DateTime start;

  /// Local wall-clock instant the window closes (may be the next day for
  /// midnight-crossing windows). Inclusive for "still due" purposes.
  final DateTime end;

  DateTime get startDay => dayStart(start);
  DateTime get endDay => dayStart(end);

  bool containsLocal(DateTime localNow) =>
      !localNow.isBefore(start) && !localNow.isAfter(end);

  @override
  String toString() =>
      'WindowInstance(routine ${window.routineId}, '
      '${start.hour}:${start.minute.toString().padLeft(2, "0")}–'
      '${end.hour}:${end.minute.toString().padLeft(2, "0")}'
      '${endDay.isAfter(startDay) ? " (+1d)" : ""})';
}

/// Midnight of the local calendar day containing [local].
DateTime dayStart(DateTime local) =>
    DateTime(local.year, local.month, local.day);

/// The instance of [window] that starts on the local day of [day], or null
/// when the window is inactive that day.
///
/// A window whose end is not after its start (whether or not
/// [ScheduleWindow.crossesMidnight] was set) is treated as wrapping into
/// the next day.
WindowInstance? instanceStartingOn(ScheduleWindow window, DateTime day) {
  if (!window.daysOfWeek.contains(day.weekday)) return null;
  final start = DateTime(
    day.year,
    day.month,
    day.day,
    window.startHour,
    window.startMinute,
  );
  var end = DateTime(
    day.year,
    day.month,
    day.day,
    window.endHour,
    window.endMinute,
  );
  if (!end.isAfter(start)) {
    end = end.add(const Duration(days: 1));
  }
  return WindowInstance(window: window, start: start, end: end);
}

/// All instances whose active span touches the local day of [day]:
/// instances starting that day, plus the morning tail of an instance that
/// started yesterday and crossed midnight into this day.
List<WindowInstance> instancesActiveOn(ScheduleWindow window, DateTime day) {
  final result = <WindowInstance>[];
  final previous = instanceStartingOn(
    window,
    dayStart(day).subtract(const Duration(days: 1)),
  );
  if (previous != null && previous.end.isAfter(dayStart(day))) {
    result.add(previous);
  }
  final today = instanceStartingOn(window, day);
  if (today != null) result.add(today);
  return result;
}

/// End of the most recent instance of [window] that finished before [inst]
/// started, or null if no such instance exists within [lookbackDays].
DateTime? previousInstanceEnd(WindowInstance inst, {int lookbackDays = 28}) {
  for (var i = 1; i <= lookbackDays; i++) {
    final day = inst.startDay.subtract(Duration(days: i));
    final candidate = instanceStartingOn(inst.window, day);
    if (candidate != null && candidate.end.isBefore(inst.start)) {
      return candidate.end;
    }
  }
  return null;
}

/// Start of the next instance of [window] after [inst] starts, or null if
/// none occurs within [lookaheadDays].
DateTime? nextInstanceStart(WindowInstance inst, {int lookaheadDays = 28}) {
  for (var i = 1; i <= lookaheadDays; i++) {
    final day = inst.startDay.add(Duration(days: i));
    final candidate = instanceStartingOn(inst.window, day);
    if (candidate != null && candidate.start.isAfter(inst.start)) {
      return candidate.start;
    }
  }
  return null;
}

/// The completion event that satisfies [inst], or null if none does.
///
/// Attribution rule: a `done` completion belongs to the instance whose
/// (previous close, next open) interval contains its instant. This means:
/// - completing a window early still counts,
/// - completing an *overdue* window later in the day (or night) still
///   counts for that day's instance,
/// - a completion made on or after the next instance opens is attributed to
///   the *next* instance, never this one,
/// - `skipped` events never satisfy (they are deliberate "not done" records).
CompletionEvent? satisfyingCompletion(
  WindowInstance inst,
  List<CompletionEvent> completions,
) {
  final lower = previousInstanceEnd(inst);
  final upper = nextInstanceStart(inst);
  CompletionEvent? best;
  for (final c in completions) {
    if (c.routineId != inst.window.routineId) continue;
    if (c.kind != CompletionKind.done) continue;
    final t = c.completedAtUtc;
    if (lower != null && !t.isAfter(lower.toUtc())) continue;
    if (upper != null && !t.isBefore(upper.toUtc())) continue;
    if (best == null || t.isAfter(best.completedAtUtc)) best = c;
  }
  return best;
}

/// Status of [inst] at [localNow] given the satisfying [completion]
/// (null when unsatisfied).
TaskStatus statusOf(
  WindowInstance inst, {
  required DateTime localNow,
  CompletionEvent? completion,
}) {
  if (completion != null) return TaskStatus.completed;
  if (localNow.isAfter(inst.end)) return TaskStatus.overdue;
  if (!localNow.isBefore(inst.start)) return TaskStatus.due;
  return TaskStatus.scheduled;
}
