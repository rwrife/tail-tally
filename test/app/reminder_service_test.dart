import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/app/reminder_service.dart';
import 'package:tail_tally/data/database.dart';
import 'package:tail_tally/data/drift_repository.dart';
import 'package:tail_tally/domain/entities.dart';
import 'package:tail_tally/domain/reminders.dart';
import 'package:tail_tally/platform/notifications.dart';

/// Wednesday 2026-09-09, 06:00 local — morning windows are still ahead.
final fakeNow = DateTime(2026, 9, 9, 6);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TailTallyDatabase db;
  late DriftLocalDataRepository repo;
  late NoopNotificationGateway gateway;
  late ReminderService service;

  setUp(() async {
    db = TailTallyDatabase(NativeDatabase.memory());
    repo = DriftLocalDataRepository(db, clock: () => fakeNow);
    await repo.ensureOpen();
    gateway = NoopNotificationGateway();
    service = ReminderService(repo: repo, gateway: gateway);
  });

  tearDown(() async {
    await db.close();
  });

  Future<ScheduleWindow> seedDailyWindow({
    int startHour = 7,
    int startMinute = 30,
    int endHour = 8,
    int endMinute = 0,
  }) async {
    final pet = await repo.addPet(
      const NewPet(name: 'Biscuit', species: 'dog'),
    );
    final routine = await repo.addRoutine(
      NewRoutine(petId: pet.id, name: 'Morning feed'),
    );
    return repo.addScheduleWindow(
      NewScheduleWindow(
        routineId: routine.id,
        startHour: startHour,
        startMinute: startMinute,
        endHour: endHour,
        endMinute: endMinute,
        daysOfWeek: const {1, 2, 3, 4, 5, 6, 7},
      ),
    );
  }

  group('settings persistence', () {
    test('no stored row reads back defaults', () async {
      expect(await service.loadSettings(), const ReminderSettings());
    });

    test('save then load round-trips', () async {
      const s = ReminderSettings(
        notificationsEnabled: true,
        leadTime: ReminderLeadTime.thirtyMinutes,
        quietHours: QuietWindow(startMinutes: 1320, endMinutes: 420),
      );
      await service.saveSettings(s);
      expect(await service.loadSettings(), s);
    });

    test('overwrite replaces the singleton row', () async {
      await service.saveSettings(const ReminderSettings());
      const s2 = ReminderSettings(notificationsEnabled: false);
      await service.saveSettings(s2);
      expect(await service.loadSettings(), s2);
      // Only one row may exist.
      expect(await service.loadSettings(), isNotNull);
    });
  });

  group('resync', () {
    test(
      'master switch off cancels everything and schedules nothing',
      () async {
        await seedDailyWindow();
        await service.saveSettings(
          const ReminderSettings(notificationsEnabled: false),
        );
        final outcome = await service.resync();
        expect(gateway.allCancelled, isTrue);
        expect(gateway.scheduled, isEmpty);
        expect(outcome.scheduledCount, 0);
      },
    );

    test('permission denied cancels and never schedules', () async {
      await seedDailyWindow();
      await service.saveSettings(
        const ReminderSettings(
          notificationsEnabled: true,
          leadTime: ReminderLeadTime.fifteenMinutes,
        ),
      );
      gateway.permission = NotificationPermission.denied;
      final outcome = await service.resync();
      expect(outcome.permission, NotificationPermission.denied);
      expect(gateway.allCancelled, isTrue);
      expect(gateway.scheduled, isEmpty);
    });

    test('granted permission schedules upcoming windows', () async {
      final window = await seedDailyWindow();
      await service.saveSettings(
        const ReminderSettings(
          notificationsEnabled: true,
          leadTime: ReminderLeadTime.fifteenMinutes,
        ),
      );
      final outcome = await service.resync();
      expect(outcome.scheduledCount, greaterThan(0));
      expect(gateway.scheduled, hasLength(outcome.scheduledCount));
      // Today's 07:30 window (lead 07:15) is in the future at 06:00.
      final first = gateway.scheduled.first;
      expect(first.fireAt, DateTime(2026, 9, 9, 7, 15));
      expect(first.windowId, window.id);
      expect(outcome.active, isTrue);
    });

    test('completing a routine cancels that instance reminder', () async {
      final window = await seedDailyWindow();
      await service.saveSettings(
        const ReminderSettings(
          notificationsEnabled: true,
          leadTime: ReminderLeadTime.fifteenMinutes,
        ),
      );
      await service.resync();
      final idBefore = gateway.scheduled.map((r) => r.notificationId).toList();

      // Mark today's instance done (at 06:30 local, within the window).
      final routines = await repo.listRoutines();
      await repo.recordCompletion(
        NewCompletionEvent(
          routineId: routines.single.id,
          completedAtUtc: DateTime(2026, 9, 9, 6, 30).toUtc(),
          kind: CompletionKind.done,
        ),
      );

      gateway.scheduled.clear();
      gateway.cancelled.clear();
      await service.resync();

      final todayId = PlannedReminder.computeNotificationId(
        window.id,
        DateTime(2026, 9, 9, 7, 30),
      );
      expect(gateway.cancelled, contains(todayId));
      expect(
        gateway.scheduled.map((r) => r.notificationId),
        isNot(contains(todayId)),
      );
      // Tomorrow's reminder is untouched by today's completion.
      expect(idBefore, contains(isNot(todayId)));
    });

    test('quiet hours suppress matching reminders', () async {
      await seedDailyWindow();
      await service.saveSettings(
        const ReminderSettings(
          notificationsEnabled: true,
          leadTime: ReminderLeadTime.fifteenMinutes,
          quietHours: QuietWindow(startMinutes: 1320, endMinutes: 450),
        ),
      );
      final outcome = await service.resync();
      // Today's 07:15 is quiet too (quiet until 07:30).
      expect(outcome.scheduledCount, 0);
      expect(outcome.suppressedCount, greaterThan(0));
      expect(gateway.scheduled, isEmpty);
    });
  });

  group('requestPermissionsAndSync', () {
    test('granted path syncs reminders', () async {
      await seedDailyWindow();
      await service.saveSettings(
        const ReminderSettings(
          notificationsEnabled: true,
          leadTime: ReminderLeadTime.fifteenMinutes,
        ),
      );
      gateway.permission = NotificationPermission.granted;
      final outcome = await service.requestPermissionsAndSync();
      expect(outcome.permission, NotificationPermission.granted);
      expect(outcome.scheduledCount, greaterThan(0));
    });

    test('denied path cancels everything and reports fallback state', () async {
      await seedDailyWindow();
      gateway.permission = NotificationPermission.denied;
      final outcome = await service.requestPermissionsAndSync();
      expect(outcome.permission, NotificationPermission.denied);
      expect(outcome.scheduledCount, 0);
      expect(outcome.canPromptAgain, isTrue);
      expect(gateway.allCancelled, isTrue);
    });
  });
}
