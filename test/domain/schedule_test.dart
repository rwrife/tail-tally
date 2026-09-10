import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/domain/entities.dart';
import 'package:tail_tally/domain/schedule.dart';

/// Wall-clock tests: `now` values are constructed as *local* DateTimes,
/// matching the timestamp contract in entities.dart.
ScheduleWindow window({
  int id = 1,
  int routineId = 10,
  int startHour = 7,
  int startMinute = 0,
  int endHour = 8,
  int endMinute = 30,
  Set<int> days = const {1, 2, 3, 4, 5, 6, 7},
  bool crossesMidnight = false,
}) => ScheduleWindow(
  id: id,
  routineId: routineId,
  startHour: startHour,
  startMinute: startMinute,
  endHour: endHour,
  endMinute: endMinute,
  daysOfWeek: days,
  crossesMidnight: crossesMidnight,
);

CompletionEvent completion({
  int id = 100,
  int routineId = 10,
  required DateTime atUtc,
  CompletionKind kind = CompletionKind.done,
}) => CompletionEvent(
  id: id,
  routineId: routineId,
  completedAtUtc: atUtc,
  kind: kind,
);

void main() {
  group('dayStart', () {
    test('truncates to local midnight', () {
      expect(dayStart(DateTime(2026, 9, 9, 14, 35, 12)), DateTime(2026, 9, 9));
    });
  });

  group('instanceStartingOn', () {
    test('active on a matching weekday', () {
      final inst = instanceStartingOn(window(), DateTime(2026, 9, 9))!;
      expect(inst.start, DateTime(2026, 9, 9, 7));
      expect(inst.end, DateTime(2026, 9, 9, 8, 30));
      expect(inst.endDay, inst.startDay);
    });

    test('inactive on a non-matching weekday', () {
      // 2026-09-13 is a Sunday (weekday 7).
      expect(
        instanceStartingOn(window(days: {1, 3, 5}), DateTime(2026, 9, 13)),
        isNull,
      );
    });

    test('midnight-crossing window ends next local day', () {
      final inst = instanceStartingOn(
        window(startHour: 22, startMinute: 0, endHour: 6, endMinute: 0),
        DateTime(2026, 9, 9),
      )!;
      expect(inst.start, DateTime(2026, 9, 9, 22));
      expect(inst.end, DateTime(2026, 9, 10, 6));
      expect(inst.endDay, DateTime(2026, 9, 10));
    });

    test('containsLocal is inclusive at both bounds', () {
      final inst = instanceStartingOn(window(), DateTime(2026, 9, 9))!;
      expect(inst.containsLocal(DateTime(2026, 9, 9, 7)), isTrue);
      expect(inst.containsLocal(DateTime(2026, 9, 9, 8, 30)), isTrue);
      expect(inst.containsLocal(DateTime(2026, 9, 9, 6, 59)), isFalse);
      expect(inst.containsLocal(DateTime(2026, 9, 9, 8, 31)), isFalse);
    });
  });

  group('instancesActiveOn', () {
    test(
      'includes the morning tail of yesterday’s midnight-crossing window',
      () {
        final w = window(
          startHour: 22,
          startMinute: 0,
          endHour: 6,
          endMinute: 0,
          crossesMidnight: true,
        );
        final wed = DateTime(2026, 9, 9);
        final onWed = instancesActiveOn(w, wed);
        // One instance starting Wed 22:00 and yesterday's tail until Wed 06:00.
        expect(onWed, hasLength(2));
        expect(onWed.first.start, DateTime(2026, 9, 8, 22));
        expect(onWed.first.end, DateTime(2026, 9, 9, 6));
        expect(onWed.last.start, DateTime(2026, 9, 9, 22));
      },
    );

    test('single instance for a same-day window', () {
      expect(instancesActiveOn(window(), DateTime(2026, 9, 9)), hasLength(1));
    });

    test('weekday-only window active only on its days', () {
      // 2026-09-12 Sat, 2026-09-14 Mon.
      expect(
        instancesActiveOn(window(days: {7, 1}), DateTime(2026, 9, 12)),
        isEmpty,
      );
      expect(
        instancesActiveOn(window(days: {7, 1}), DateTime(2026, 9, 14)),
        hasLength(1),
      );
    });
  });

  group('satisfyingCompletion', () {
    final inst = WindowInstance(
      window: window(),
      start: DateTime(2026, 9, 9, 7),
      end: DateTime(2026, 9, 9, 8, 30),
    );

    test('completion inside the window satisfies it', () {
      final c = completion(atUtc: DateTime(2026, 9, 9, 7, 30).toUtc());
      expect(satisfyingCompletion(inst, [c])?.id, 100);
    });

    test('early completion after the previous window still satisfies', () {
      // Previous instance closed 2026-09-08 08:30 local.
      final c = completion(atUtc: DateTime(2026, 9, 9, 6, 45).toUtc());
      expect(satisfyingCompletion(inst, [c])?.id, 100);
    });

    test('completion before the previous window close does not satisfy', () {
      final c = completion(atUtc: DateTime(2026, 9, 8, 8, 0).toUtc());
      expect(satisfyingCompletion(inst, [c]), isNull);
    });

    test(
      'late completion after this window close still satisfies that day',
      () {
        // Before the *next* instance opens (tomorrow 07:00), so it belongs to
        // this instance — completing an overdue task later in the day counts.
        final c = completion(atUtc: DateTime(2026, 9, 9, 9, 0).toUtc());
        expect(satisfyingCompletion(inst, [c])?.id, 100);
      },
    );

    test('completion on or after the next instance open does not satisfy', () {
      final c = completion(atUtc: DateTime(2026, 9, 10, 7, 0).toUtc());
      expect(satisfyingCompletion(inst, [c]), isNull);
    });

    test('skipped events never satisfy', () {
      final c = completion(
        atUtc: DateTime(2026, 9, 9, 7, 30).toUtc(),
        kind: CompletionKind.skipped,
      );
      expect(satisfyingCompletion(inst, [c]), isNull);
    });

    test('other routines’ completions never satisfy', () {
      final c = completion(
        routineId: 11,
        atUtc: DateTime(2026, 9, 9, 7, 30).toUtc(),
      );
      expect(satisfyingCompletion(inst, [c]), isNull);
    });

    test('most recent matching completion wins', () {
      final older = completion(
        id: 1,
        atUtc: DateTime(2026, 9, 9, 7, 5).toUtc(),
      );
      final newer = completion(
        id: 2,
        atUtc: DateTime(2026, 9, 9, 8, 0).toUtc(),
      );
      expect(satisfyingCompletion(inst, [older, newer])?.id, 2);
    });

    test('midnight-crossing window matched across UTC boundary', () {
      final cross = WindowInstance(
        window: window(startHour: 22, endHour: 6),
        start: DateTime(2026, 9, 9, 22),
        end: DateTime(2026, 9, 10, 6),
      );
      final c = completion(atUtc: DateTime(2026, 9, 10, 5, 30).toUtc());
      expect(satisfyingCompletion(cross, [c])?.id, 100);
    });
  });

  group('statusOf', () {
    final inst = WindowInstance(
      window: window(),
      start: DateTime(2026, 9, 9, 7),
      end: DateTime(2026, 9, 9, 8, 30),
    );

    test('scheduled before the window opens', () {
      expect(
        statusOf(inst, localNow: DateTime(2026, 9, 9, 6, 59)),
        TaskStatus.scheduled,
      );
    });

    test('due while the window is open (inclusive at close)', () {
      expect(
        statusOf(inst, localNow: DateTime(2026, 9, 9, 7, 15)),
        TaskStatus.due,
      );
      expect(
        statusOf(inst, localNow: DateTime(2026, 9, 9, 8, 30)),
        TaskStatus.due,
      );
    });

    test('overdue after close', () {
      expect(
        statusOf(inst, localNow: DateTime(2026, 9, 9, 8, 31)),
        TaskStatus.overdue,
      );
    });

    test('completed wins over time-based status', () {
      expect(
        statusOf(
          inst,
          localNow: DateTime(2026, 9, 9, 23, 0),
          completion: completion(atUtc: DateTime(2026, 9, 9, 7, 30).toUtc()),
        ),
        TaskStatus.completed,
      );
    });
  });

  group('previousInstanceEnd', () {
    test('daily window’s previous close is yesterday', () {
      final inst = instanceStartingOn(window(), DateTime(2026, 9, 9))!;
      expect(previousInstanceEnd(inst), DateTime(2026, 9, 8, 8, 30));
    });

    test(
      'first-ever instance of a weekly window has no previous close nearby',
      () {
        // Window only active Mondays; lookback default 28 days still finds one.
        final w = window(days: {1});
        final inst = instanceStartingOn(w, DateTime(2026, 9, 7))!;
        expect(previousInstanceEnd(inst), DateTime(2026, 8, 31, 8, 30));
      },
    );
  });
}
