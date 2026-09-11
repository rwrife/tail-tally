/// Orchestrates reminder scheduling end-to-end (issue #4):
/// loads persisted settings + schedule data, runs [ReminderPlanner], and
/// applies the plan through a [NotificationGateway] with permission-aware
/// behavior — when the OS denies notifications, plans are never attempted
/// and any previously scheduled reminders are cancelled instead.
library;

import '../domain/entities.dart';
import '../domain/reminders.dart';
import '../domain/schedule.dart';
import '../platform/notifications.dart';

/// Result of a [ReminderService.resync] pass, for UI feedback.
class ResyncOutcome {
  const ResyncOutcome({
    required this.permission,
    required this.scheduledCount,
    required this.cancelledCount,
    required this.suppressedCount,
    this.canPromptAgain = true,
  });

  final NotificationPermission permission;
  final int scheduledCount;
  final int cancelledCount;

  /// Reminders the planner wanted to schedule but quiet hours dropped.
  final int suppressedCount;

  /// Whether re-asking the OS for permission could still show a prompt.
  final bool canPromptAgain;

  bool get active =>
      permission == NotificationPermission.granted && scheduledCount > 0;
}

class ReminderService {
  ReminderService({
    required this._repo,
    required this._gateway,
    this._planner = const ReminderPlanner(),
  });

  final LocalDataRepository _repo;
  final NotificationGateway _gateway;
  final ReminderPlanner _planner;

  /// Exposed so the settings screen can check permission state directly.
  NotificationGateway get gateway => _gateway;

  Future<ReminderSettings> loadSettings() async =>
      ReminderSettings.decode(await _repo.readReminderSettingsJson());

  Future<void> saveSettings(ReminderSettings settings) =>
      _repo.writeReminderSettingsJson(settings.encode());

  /// Just-in-time permission request with graceful fallback:
  /// granted -> resync immediately; denied -> cancel everything so no
  /// half-configured state lingers.
  Future<ResyncOutcome> requestPermissionsAndSync() async {
    final outcome = await _gateway.requestPermission();
    if (outcome.permission != NotificationPermission.granted) {
      await _gateway.cancelAll();
      return ResyncOutcome(
        permission: outcome.permission,
        scheduledCount: 0,
        cancelledCount: 0,
        suppressedCount: 0,
        canPromptAgain: outcome.canPromptAgain,
      );
    }
    return resync();
  }

  /// Recompute reminders from current data and settings.
  Future<ResyncOutcome> resync() async {
    final settings = await loadSettings();
    if (!settings.notificationsEnabled) {
      await _gateway.cancelAll();
      return const ResyncOutcome(
        permission: NotificationPermission.granted,
        scheduledCount: 0,
        cancelledCount: 0,
        suppressedCount: 0,
      );
    }

    final permission = await _gateway.checkPermission();
    if (permission != NotificationPermission.granted) {
      // Permission revoked since last sync: clean slate rather than
      // queueing schedules the OS will drop silently.
      await _gateway.cancelAll();
      return ResyncOutcome(
        permission: permission,
        scheduledCount: 0,
        cancelledCount: 0,
        suppressedCount: 0,
      );
    }

    final pets = await _repo.listPets();
    final petNames = {for (final p in pets) p.id: p.name};
    final routines = await _repo.listRoutines();
    final routinesById = {for (final r in routines) r.id: r};
    final windows = await _repo.listScheduleWindows();
    final now = _repo.now();

    // Completed instances inside the lookahead window: any window
    // instance with a `done` completion whose key the planner knows.
    final completedKeys = <String>{};
    final completions = await _repo.listCompletions(
      fromUtc: now.subtract(const Duration(days: 60)).toUtc(),
    );
    for (final window in windows) {
      final routineCompletions = completions
          .where(
            (c) =>
                c.routineId == window.routineId &&
                c.kind == CompletionKind.done,
          )
          .toList();
      for (var offset = 0; offset <= 7; offset++) {
        final day = dayStart(now).add(Duration(days: offset));
        final inst = instanceStartingOn(window, day);
        if (inst == null) continue;
        final sat = satisfyingCompletion(inst, routineCompletions);
        if (sat != null) {
          completedKeys.add(instanceKey(window.id, inst.start));
        }
      }
    }

    final plan = _planner.plan(
      windows: windows,
      routinesById: routinesById,
      petNamesByRoutineId: {
        for (final r in routines)
          if (petNames[r.petId] != null) r.id: petNames[r.petId]!,
      },
      settings: settings,
      now: now,
      completedInstanceKeys: completedKeys,
    );

    for (final id in plan.cancelledNotificationIds) {
      await _gateway.cancel(id);
    }
    for (final r in plan.scheduled) {
      await _gateway.schedule(r);
    }
    final quietHourSuppressions = plan.suppressed
        .where((r) => r.suppressedFor == SuppressionReason.quietHours)
        .length;
    return ResyncOutcome(
      permission: permission,
      scheduledCount: plan.scheduled.length,
      cancelledCount: plan.cancelledNotificationIds.length,
      suppressedCount: quietHourSuppressions,
    );
  }
}
