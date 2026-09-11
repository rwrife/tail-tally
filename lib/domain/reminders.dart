/// Pure-Dart reminder planning for routine windows (issue #4).
///
/// This file deliberately has no Flutter, plugin, or platform-channel
/// imports: it turns [WindowInstance]s plus user preferences into a
/// deterministic list of [PlannedReminder]s. The platform layer in
/// `lib/platform/` consumes that list and talks to the notification
/// plugin. Everything time-related is *device-local wall-clock* data,
/// matching the timestamp contract in `entities.dart`.
library;

import 'dart:convert';

import 'entities.dart';
import 'schedule.dart';

/// How many minutes before a window opens the reminder should fire.
/// Persisted as minutes so it survives serialization without enums.
enum ReminderLeadTime {
  atWindowStart(0, 'At window start'),
  fiveMinutes(5, '5 minutes before'),
  fifteenMinutes(15, '15 minutes before'),
  thirtyMinutes(30, '30 minutes before');

  const ReminderLeadTime(this.minutes, this.label);

  /// Minutes before the window start that the reminder fires.
  final int minutes;
  final String label;

  static ReminderLeadTime fromMinutes(int minutes) => values.firstWhere(
    (v) => v.minutes == minutes,
    orElse: () => ReminderLeadTime.fiveMinutes,
  );
}

/// One day of quiet hours as minutes since local midnight, half-open
/// interval `[startMinutes, endMinutes)`. When [startMinutes] is greater
/// than [endMinutes] the interval wraps past midnight (e.g. 22:00–07:00).
class QuietWindow {
  const QuietWindow({required this.startMinutes, required this.endMinutes});

  static const minutesPerDay = 24 * 60;

  final int startMinutes;
  final int endMinutes;

  static QuietWindow at(
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
  ) {
    return QuietWindow(
      startMinutes: startHour * 60 + startMinute,
      endMinutes: endHour * 60 + endMinute,
    );
  }

  /// True when quiet hours are effectively disabled (start == end means an
  /// empty interval — everything is quiet, so we treat equal bounds as
  /// "off" and let the caller persist [disabled]).
  bool get isDisabled => startMinutes == endMinutes;

  static const QuietWindow disabled = QuietWindow(
    startMinutes: 0,
    endMinutes: 0,
  );

  /// Whether the wall-clock [local] instant falls inside this interval.
  bool contains(DateTime local) {
    if (isDisabled) return false;
    final m = local.hour * 60 + local.minute;
    if (startMinutes <= endMinutes) {
      return m >= startMinutes && m < endMinutes;
    }
    // Wrapping interval such as 22:00–07:00.
    return m >= startMinutes || m < endMinutes;
  }

  Map<String, int> toJson() => {
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
  };

  factory QuietWindow.fromJson(Map<String, dynamic> json) => QuietWindow(
    startMinutes: (json['startMinutes'] as num).toInt(),
    endMinutes: (json['endMinutes'] as num).toInt(),
  );

  @override
  bool operator ==(Object other) =>
      other is QuietWindow &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes;

  @override
  int get hashCode => Object.hash(startMinutes, endMinutes);

  @override
  String toString() => 'QuietWindow($startMinutes..$endMinutes)';
}

/// Why a planned reminder was suppressed instead of scheduled.
enum SuppressionReason {
  /// The reminder fire time falls inside the user's quiet hours.
  quietHours,

  /// The reminder time is already in the past relative to [now].
  stale,
}

/// A reminder the platform layer should (or should not) schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.windowId,
    required this.routineId,
    required this.title,
    required this.body,
    required this.instanceStart,
    required this.fireAt,
    this.suppressedFor,
  });

  /// Deterministic notification id so reschedules replace the same
  /// notification and completed instances stop re-firing it.
  /// Combines the window id with the *local calendar day* the instance
  /// starts on (not raw epoch ms — daily repeats differ only by day, and
  /// wall-clock day is the instance identity here). Fits in 32 bits:
  /// 15 bits of window id (<= 32767) and 16 bits of day key.
  static int computeNotificationId(int windowId, DateTime instanceStart) {
    final dayKey =
        instanceStart.year * 400 + instanceStart.month * 32 + instanceStart.day;
    return ((windowId & 0x7FFF) << 16) | (dayKey & 0xFFFF);
  }

  int get notificationId => computeNotificationId(windowId, instanceStart);

  final int windowId;
  final int routineId;
  final String title;
  final String body;

  /// Local wall-clock instant the routine window opens.
  final DateTime instanceStart;

  /// Local wall-clock instant the notification should fire.
  final DateTime fireAt;

  /// Null when this reminder should be scheduled; otherwise why it was
  /// dropped. Suppressed entries are still returned so callers (and tests)
  /// can distinguish "quiet hours" from "nothing to do".
  final SuppressionReason? suppressedFor;

  bool get isSchedulable => suppressedFor == null;

  PlannedReminder _suppress(SuppressionReason reason) => PlannedReminder(
    windowId: windowId,
    routineId: routineId,
    title: title,
    body: body,
    instanceStart: instanceStart,
    fireAt: fireAt,
    suppressedFor: reason,
  );

  @override
  String toString() =>
      'PlannedReminder(window $windowId @ $fireAt'
      '${suppressedFor == null ? '' : ' suppressed:$suppressedFor'})';
}

/// User-facing reminder preferences, persisted locally as JSON.
class ReminderSettings {
  const ReminderSettings({
    this.notificationsEnabled = false,
    this.leadTime = ReminderLeadTime.fiveMinutes,
    this.quietHours = QuietWindow.disabled,
  });

  /// Master switch. Opt-in: defaults to off, and when false nothing is
  /// scheduled and every existing notification is cancelled.
  final bool notificationsEnabled;
  final ReminderLeadTime leadTime;
  final QuietWindow quietHours;

  static const currentSchemaVersion = 1;

  Map<String, dynamic> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'notificationsEnabled': notificationsEnabled,
    'leadTimeMinutes': leadTime.minutes,
    'quietHours': quietHours.toJson(),
  };

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    // Tolerant read: unknown/future versions fall back to defaults for
    // any missing keys rather than throwing, mirroring the repo's
    // "never crash on odd local data" style.
    final lead = (json['leadTimeMinutes'] as num?)?.toInt();
    final quiet = json['quietHours'];
    return ReminderSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      leadTime: lead == null
          ? ReminderLeadTime.fiveMinutes
          : ReminderLeadTime.fromMinutes(lead),
      quietHours: quiet is Map<String, dynamic>
          ? QuietWindow.fromJson(quiet)
          : QuietWindow.disabled,
    );
  }

  String encode() => jsonEncode(toJson());

  /// Parse persisted JSON; returns defaults for null/invalid input.
  static ReminderSettings decode(String? raw) {
    if (raw == null || raw.isEmpty) return const ReminderSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const ReminderSettings();
      return ReminderSettings.fromJson(decoded);
    } on FormatException {
      return const ReminderSettings();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.notificationsEnabled == notificationsEnabled &&
      other.leadTime == leadTime &&
      other.quietHours == quietHours;

  @override
  int get hashCode => Object.hash(notificationsEnabled, leadTime, quietHours);
}

/// Plans reminders for window instances within the next [lookaheadDays].
///
/// Rules:
/// - One reminder per window instance, fired [ReminderLeadTime] minutes
///   before the instance opens.
/// - Instances already completed or whose window has fully closed get an
///   explicit *cancel* (their deterministic id), so completing a routine
///   removes the pending notification and stale windows self-clean.
/// - A reminder whose fire time lands in quiet hours is suppressed
///   (returned with [SuppressionReason.quietHours]) — it is cancelled,
///   not silently postponed, keeping behavior predictable.
/// - A reminder whose fire time is already past relative to [now] is
///   suppressed as [SuppressionReason.stale].
class ReminderPlanner {
  const ReminderPlanner();

  /// Plan over the local day of [now] plus the following [lookaheadDays].
  ///
  /// [completedInstanceKeys] identifies instances that are already done,
  /// built with [instanceKey]; matching instances get their notification id
  /// cancelled instead of scheduled.
  ReminderPlan plan({
    required List<ScheduleWindow> windows,
    required Map<int, Routine> routinesById,
    required Map<int, String> petNamesByRoutineId,
    required ReminderSettings settings,
    required DateTime now,
    Set<String> completedInstanceKeys = const {},
    int lookaheadDays = 7,
  }) {
    if (!settings.notificationsEnabled) {
      return const ReminderPlan.empty();
    }
    final day = dayStart(now);
    final scheduled = <PlannedReminder>[];
    final suppressed = <PlannedReminder>[];
    final cancelledIds = <int>[];
    final seenIds = <int>{};

    for (final window in windows) {
      final routine = routinesById[window.routineId];
      if (routine == null) continue;
      final petName = petNamesByRoutineId[window.routineId];

      for (var offset = 0; offset <= lookaheadDays; offset++) {
        final candidateDay = day.add(Duration(days: offset));
        final instance = instanceStartingOn(window, candidateDay);
        if (instance == null) continue;

        final fireAt = instance.start.subtract(
          Duration(minutes: settings.leadTime.minutes),
        );
        final id = PlannedReminder.computeNotificationId(
          window.id,
          instance.start,
        );
        if (!seenIds.add(id)) continue;

        // Completed instances never notify, and we cancel any stale
        // notification from a previous plan.
        if (completedInstanceKeys.contains(
          instanceKey(window.id, instance.start),
        )) {
          cancelledIds.add(id);
          continue;
        }
        // Window fully closed with nothing due — self-clean old ids.
        if (instance.end.isBefore(now)) {
          cancelledIds.add(id);
          continue;
        }

        var planned = PlannedReminder(
          windowId: window.id,
          routineId: window.routineId,
          title: petName == null ? routine.name : '$petName — ${routine.name}',
          body:
              'Window ${_fmt(instance.start)}–${_fmt(instance.end)}'
              '${instance.endDay.isAfter(instance.startDay) ? ' (+1d)' : ''}',
          instanceStart: instance.start,
          fireAt: fireAt,
        );

        if (!planned.fireAt.isAfter(now)) {
          planned = planned._suppress(SuppressionReason.stale);
        } else if (settings.quietHours.contains(planned.fireAt)) {
          planned = planned._suppress(SuppressionReason.quietHours);
        }

        if (planned.isSchedulable) {
          scheduled.add(planned);
        } else {
          suppressed.add(planned);
          cancelledIds.add(id);
        }
      }
    }

    scheduled.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return ReminderPlan(
      scheduled: scheduled,
      cancelledNotificationIds: cancelledIds.toSet().toList()..sort(),
      suppressed: suppressed,
    );
  }

  static String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

/// Stable identity for one concrete window instance, used to mark it
/// completed when planning reminders.
String instanceKey(int windowId, DateTime instanceStart) =>
    '$windowId@${instanceStart.microsecondsSinceEpoch}';

/// Result of a planning pass.
class ReminderPlan {
  const ReminderPlan({
    required this.scheduled,
    required this.cancelledNotificationIds,
    this.suppressed = const [],
  });

  const ReminderPlan.empty()
    : scheduled = const [],
      cancelledNotificationIds = const [],
      suppressed = const [];

  /// Reminders to (re)schedule, sorted by fire time.
  final List<PlannedReminder> scheduled;

  /// Deterministic notification ids to cancel (completed instances,
  /// closed windows, suppressed or stale entries).
  final List<int> cancelledNotificationIds;

  /// Entries that would have been scheduled but were suppressed
  /// (quiet hours / stale), each carrying its [SuppressionReason].
  final List<PlannedReminder> suppressed;
}
