import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/app/reminder_service.dart';
import 'package:tail_tally/app/reminder_settings_screen.dart';
import 'package:tail_tally/data/database.dart';
import 'package:tail_tally/data/drift_repository.dart';
import 'package:tail_tally/domain/entities.dart';
import 'package:tail_tally/domain/reminders.dart';
import 'package:tail_tally/platform/notifications.dart';

void main() {
  late TailTallyDatabase db;
  late DriftLocalDataRepository repo;
  late NoopNotificationGateway gateway;
  late ReminderService service;

  setUp(() async {
    db = TailTallyDatabase(NativeDatabase.memory());
    repo = DriftLocalDataRepository(db, clock: () => DateTime(2026, 9, 9, 6));
    await repo.ensureOpen();
    gateway = NoopNotificationGateway();
    service = ReminderService(repo: repo, gateway: gateway);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ReminderSettingsScreen(service: service)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> seed() async {
    final pet = await repo.addPet(
      const NewPet(name: 'Biscuit', species: 'dog'),
    );
    await repo.addRoutine(NewRoutine(petId: pet.id, name: 'Morning feed'));
    await repo.addScheduleWindow(
      NewScheduleWindow(
        routineId: 1,
        startHour: 7,
        startMinute: 30,
        endHour: 8,
        endMinute: 0,
        daysOfWeek: const {1, 2, 3, 4, 5, 6, 7},
      ),
    );
  }

  testWidgets(
    'permission-denied fallback explains that reminders are optional',
    (tester) async {
      await seed();
      gateway.permission = NotificationPermission.denied;
      await pumpScreen(tester);

      expect(find.byKey(const Key('permission-fallback')), findsOneWidget);
      expect(
        find.textContaining('Notification permission not granted'),
        findsOneWidget,
      );

      // Turning reminders on routes through the permission request first.
      await tester.tap(find.byKey(const Key('reminders-enabled')));
      await tester.pumpAndSettle();

      expect(gateway.allCancelled, isTrue);
      expect(gateway.scheduled, isEmpty);
      // The fallback message confirms the app still works without permission.
      // It sits below the fold in the lazy list, so scroll to it first.
      await tester.scrollUntilVisible(
        find.byKey(const Key('reminder-status')),
        200,
      );
      expect(
        find.textContaining('timeline and history keep working'),
        findsOneWidget,
      );
      // Settings were NOT silently enabled while permission is denied.
      final saved = await service.loadSettings();
      expect(saved.notificationsEnabled, isFalse);
    },
  );

  testWidgets('granted permission enables reminders and reports scheduling', (
    tester,
  ) async {
    await seed();
    gateway.permission = NotificationPermission.granted;
    await pumpScreen(tester);

    expect(find.byKey(const Key('permission-fallback')), findsNothing);

    await tester.tap(find.byKey(const Key('reminders-enabled')));
    await tester.pumpAndSettle();

    expect(gateway.scheduled, isNotEmpty);
    expect(find.byKey(const Key('reminder-status')), findsOneWidget);
    final saved = await service.loadSettings();
    expect(saved.notificationsEnabled, isTrue);
  });

  testWidgets('lead time change persists and reschedules', (tester) async {
    await seed();
    gateway.permission = NotificationPermission.granted;
    await pumpScreen(tester);

    // Enable first.
    await tester.tap(find.byKey(const Key('reminders-enabled')));
    await tester.pumpAndSettle();

    // Forget the 5-minute-lead schedules from enabling.
    gateway.scheduled.clear();

    await tester.tap(find.byKey(const Key('lead-time')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 minutes before').last);
    await tester.pumpAndSettle();

    final saved = await service.loadSettings();
    expect(saved.leadTime, ReminderLeadTime.thirtyMinutes);
    // Latest fire times use the 30-min lead.
    expect(gateway.scheduled.every((r) => r.fireAt.minute == 0), isTrue);
  });
}
