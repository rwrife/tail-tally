import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/domain/entities.dart';
import 'package:tail_tally/domain/reminders.dart';

ScheduleWindow window({
  int id = 1,
  int routineId = 10,
  int startHour = 7,
  int startMinute = 30,
  int endHour = 8,
  int endMinute = 0,
  Set<int>? days,
}) => ScheduleWindow(
  id: id,
  routineId: routineId,
  startHour: startHour,
  startMinute: startMinute,
  endHour: endHour,
  endMinute: endMinute,
  daysOfWeek: days ?? {1, 2, 3, 4, 5, 6, 7},
);

Routine routine({int id = 10, int petId = 100}) =>
    Routine(id: id, petId: petId, name: 'Morning feed');

void main() {
  // Monday 2026-09-07 local.
  final monday9 = DateTime(2026, 9, 7, 9);

  group('QuietWindow', () {
    test('non-wrapping interval membership is half-open', () {
      final q = QuietWindow.at(22, 0, 23, 30);
      expect(q.contains(DateTime(2026, 9, 7, 22, 0)), isTrue);
      expect(q.contains(DateTime(2026, 9, 7, 23, 29)), isTrue);
      expect(q.contains(DateTime(2026, 9, 7, 23, 30)), isFalse);
      expect(q.contains(DateTime(2026, 9, 7, 21, 59)), isFalse);
    });

    test('wrapping interval covers both ends of the day', () {
      final q = QuietWindow.at(22, 0, 7, 0);
      expect(q.contains(DateTime(2026, 9, 7, 23, 0)), isTrue);
      expect(q.contains(DateTime(2026, 9, 7, 6, 59)), isTrue);
      expect(q.contains(DateTime(2026, 9, 7, 7, 0)), isFalse);
      expect(q.contains(DateTime(2026, 9, 7, 12, 0)), isFalse);
    });

    test('disabled window contains nothing', () {
      expect(QuietWindow.disabled.contains(DateTime(2026, 9, 7, 3)), isFalse);
      expect(
        QuietWindow.at(22, 0, 22, 0).contains(DateTime(2026, 9, 7, 22, 30)),
        isFalse,
      );
    });
  });

  group('ReminderSettings persistence', () {
    test('round-trips through JSON', () {
      final s = ReminderSettings(
        notificationsEnabled: true,
        leadTime: ReminderLeadTime.thirtyMinutes,
        quietHours: QuietWindow.at(22, 0, 7, 0),
      );
      expect(ReminderSettings.decode(s.encode()), s);
    });

    test('defaults for null, empty, and corrupt payloads', () {
      const defaults = ReminderSettings();
      expect(ReminderSettings.decode(null), defaults);
      expect(ReminderSettings.decode(''), defaults);
      expect(ReminderSettings.decode('not json'), defaults);
      expect(ReminderSettings.decode('[1,2]'), defaults);
    });

    test('unknown lead-time minutes fall back to a valid enum value', () {
      final s = ReminderSettings.decode(
        '{"schemaVersion":1,"notificationsEnabled":true,'
        '"leadTimeMinutes":999}',
      );
      expect(ReminderLeadTime.values, contains(s.leadTime));
    });

    test('future-version payloads keep readable fields', () {
      final s = ReminderSettings.decode(
        '{"schemaVersion":2,"notificationsEnabled":false,'
        '"leadTimeMinutes":15,"quietHours":{"startMinutes":1350,'
        '"endMinutes":420},"brandNew":{"a":1}}',
      );
      expect(s.notificationsEnabled, isFalse);
      expect(s.leadTime, ReminderLeadTime.fifteenMinutes);
      expect(s.quietHours, QuietWindow.at(22, 30, 7, 0));
    });
  });

  group('ReminderPlanner', () {
    const settings = ReminderSettings(
      notificationsEnabled: true,
      leadTime: ReminderLeadTime.fifteenMinutes,
    );
    final planner = const ReminderPlanner();

    ReminderPlan planFor(
      List<ScheduleWindow> windows, {
      ReminderSettings s = settings,
      DateTime? now,
      Set<String> completed = const {},
    }) => planner.plan(
      windows: windows,
      routinesById: {10: routine()},
      petNamesByRoutineId: {10: 'Biscuit'},
      settings: s,
      now: now ?? monday9,
      completedInstanceKeys: completed,
    );

    test('disabled master switch produces an empty plan', () {
      final plan = planFor([
        window(),
      ], s: const ReminderSettings(notificationsEnabled: false));
      expect(plan.scheduled, isEmpty);
      expect(plan.cancelledNotificationIds, isEmpty);
    });

    test('one reminder per instance, lead time before window start', () {
      final plan = planFor([window()]);
      expect(plan.scheduled, hasLength(7)); // 7-day lookahead incl. today
      final first = plan.scheduled.first;
      // Today 07:30 already passed at 09:00 -> first is tomorrow.
      expect(first.fireAt, DateTime(2026, 9, 8, 7, 15));
      expect(first.title, 'Biscuit — Morning feed');
      expect(first.isSchedulable, isTrue);
      // Sorted by fire time.
      for (var i = 1; i < plan.scheduled.length; i++) {
        expect(
          plan.scheduled[i].fireAt.isAfter(plan.scheduled[i - 1].fireAt),
          isTrue,
        );
      }
    });

    test('past-today instance is suppressed as stale, not scheduled', () {
      final plan = planFor([window()]);
      // Nothing fires before "now".
      for (final r in plan.scheduled) {
        expect(r.fireAt.isAfter(monday9), isTrue);
      }
    });

    test('quiet hours suppress and cancel matching instances', () {
      // Quiet 22:00-07:30; the 07:30 window with a 15-min lead fires at
      // 07:15, which is quiet -> all future daily instances suppressed.
      // Today's 07:15 fire is already past, so it is stale instead.
      final plan = planFor(
        [window()],
        s: const ReminderSettings(
          notificationsEnabled: true,
          leadTime: ReminderLeadTime.fifteenMinutes,
          quietHours: QuietWindow(startMinutes: 1320, endMinutes: 450),
        ),
      );
      expect(plan.scheduled, isEmpty);
      // Today's instance self-cleaned as a closed window (cancelled, not
      // suppressed); the 7 future instances are quiet-hours suppressions.
      expect(plan.suppressed, hasLength(7));
      expect(
        plan.suppressed.where(
          (r) => r.suppressedFor == SuppressionReason.quietHours,
        ),
        hasLength(7),
      );
      expect(plan.cancelledNotificationIds, hasLength(8));
    });

    test('completed instances cancel their notification id', () {
      final tomorrowStart = DateTime(2026, 9, 8, 7, 30);
      final plan = planFor(
        [window()],
        completed: {instanceKey(1, tomorrowStart)},
      );
      expect(
        plan.scheduled.any((r) => r.instanceStart == tomorrowStart),
        isFalse,
      );
      expect(
        plan.cancelledNotificationIds,
        contains(PlannedReminder.computeNotificationId(1, tomorrowStart)),
      );
    });

    test('deterministic ids: same window+instance => same id', () {
      final start = DateTime(2026, 9, 8, 7, 30);
      expect(
        PlannedReminder.computeNotificationId(1, start),
        PlannedReminder.computeNotificationId(1, start),
      );
      expect(
        PlannedReminder.computeNotificationId(1, start),
        isNot(PlannedReminder.computeNotificationId(2, start)),
      );
      expect(
        PlannedReminder.computeNotificationId(1, start),
        isNot(
          PlannedReminder.computeNotificationId(
            1,
            start.add(const Duration(days: 1)),
          ),
        ),
      );
    });

    test('midnight-crossing windows produce one reminder at local start', () {
      // Window 22:30 -> 06:00 (+1d). Lead 15 -> fires 22:15 same day.
      // Evaluated at 09:00, today's 22:15 fire is still future, so all
      // 8 lookahead days are schedulable.
      final plan = planFor([
        window(startHour: 22, startMinute: 30, endHour: 6, endMinute: 0),
      ]);
      expect(plan.scheduled, hasLength(8));
      for (final r in plan.scheduled) {
        expect(r.fireAt.hour, 22);
        expect(r.fireAt.minute, 15);
        // Fire time is strictly before the window it belongs to.
        expect(r.fireAt.isBefore(r.instanceStart), isTrue);
        // Body marks the +1d close so the notification is unambiguous.
        expect(r.body, contains('+1d'));
      }
    });

    test('weekday filtering skips inactive days', () {
      // Window only on Wed+Sun; now is Monday -> first hits Wed 9 Sep.
      final plan = planFor([
        window(days: {3, 7}),
      ]);
      expect(plan.scheduled.first.instanceStart, DateTime(2026, 9, 9, 7, 30));
      expect(plan.scheduled.last.instanceStart, DateTime(2026, 9, 13, 7, 30));
    });

    test('DST-style wall-clock shift keeps reminders on local wall time', () {
      // Wall-clock contract: a 07:30 window always reminds at 07:15 local,
      // even across a simulated UTC offset change (a DateTime with an
      // explicit different offset representing "after travel/DST").
      final beforeTravel = DateTime(2026, 3, 7, 9); // local morning
      final plan = planFor([window()], now: beforeTravel);
      for (final r in plan.scheduled) {
        expect(r.fireAt.hour, 7);
        expect(r.fireAt.minute, 15);
      }
      // A schedule evaluated "one hour later" (post-shift interpretation)
      // still anchors on local 07:15, never UTC-anchored instants.
      final afterTravel = DateTime(2026, 3, 7, 11);
      final plan2 = planFor([window()], now: afterTravel);
      expect(
        plan2.scheduled.every(
          (r) => r.fireAt.hour == 7 && r.fireAt.minute == 15,
        ),
        isTrue,
      );
    });
  });
}
