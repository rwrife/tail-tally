/// Accessibility regression tests (issue #6).
///
/// These lock in the UI contract that made Tail Tally usable with
/// TalkBack/VoiceOver, large system text, and rotation:
///   * every timeline card carries a word-based status chip and a
///     descriptive action label (no color-only or icon-only meaning);
///   * status/result text changes are announced via live regions;
///   * layout survives 1.5x text scale and landscape orientation
///     without overflow on the core screens.
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/app/data_privacy_service.dart';
import 'package:tail_tally/app/privacy_settings_screen.dart';
import 'package:tail_tally/app/reminder_service.dart';
import 'package:tail_tally/app/reminder_settings_screen.dart';
import 'package:tail_tally/app/tail_tally_app.dart';
import 'package:tail_tally/data/database.dart';
import 'package:tail_tally/data/drift_repository.dart';
import 'package:tail_tally/data/seed_data.dart';
import 'package:tail_tally/platform/notifications.dart';

import 'privacy_settings_screen_test.dart' show AcceptingFileGateway;

void main() {
  late TailTallyDatabase db;
  late DriftLocalDataRepository repo;
  late NoopNotificationGateway gateway;

  setUp(() async {
    db = TailTallyDatabase(NativeDatabase.memory());
    repo = DriftLocalDataRepository(db, clock: () => DateTime(2026, 9, 9, 9));
    await repo.ensureOpen();
    await seedSampleData(repo);
    gateway = NoopNotificationGateway();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      TailTallyApp(repository: repo, notificationGateway: gateway),
    );
    await tester.pumpAndSettle();
  }

  group('non-color status cues', () {
    testWidgets('cards announce status as a word, not just color', (
      tester,
    ) async {
      await pumpApp(tester);

      // The seed puts Morning walk overdue and the rest coming up; both the
      // group header and the per-card chip use these words.
      expect(find.text('Overdue'), findsWidgets);
      expect(find.text('Coming up'), findsWidgets);

      // Each chip is wrapped in a Semantics that prefixes its meaning, so a
      // screen reader says "Status: Overdue" rather than relying on the
      // container color.
      final chips = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Status: Overdue',
      );
      expect(chips, findsWidgets);
    });

    testWidgets('completion adds the Done status word on the card', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Done').first);
      await tester.pumpAndSettle(); // note dialog
      await tester.tap(find.byKey(const Key('note-save')));
      await tester.pumpAndSettle(); // refresh

      // The completed card's chip reads "Done" as a word next to the handoff
      // line — the green check icon is only a redundant accent.
      final doneCard = find.widgetWithText(Card, 'Biscuit — Morning walk');
      expect(
        find.descendant(of: doneCard, matching: find.text('Done')),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: doneCard,
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == 'Status: Done',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('done buttons name the task they complete', (tester) async {
      await pumpApp(tester);

      final labels = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.semanticsLabel)
          .whereType<String>()
          .where((l) => l.startsWith('Mark '));
      // Every pending card gets a descriptive action label like
      // "Mark Morning walk for Biscuit done".
      expect(labels, isNotEmpty);
      expect(labels.every((l) => l.endsWith(' done')), isTrue);
    });
  });

  group('screen-reader labels', () {
    testWidgets('pet filter chips describe the filter action', (tester) async {
      await pumpApp(tester);

      final chip = find.byWidgetPredicate(
        (w) => w is Text && w.semanticsLabel == 'Filter to Mochi, cat',
      );
      expect(chip, findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && w.semanticsLabel == 'Show all pets',
        ),
        findsOneWidget,
      );
    });
  });

  group('dynamic text scaling and orientation', () {
    testWidgets('timeline renders at 1.5x text scale without overflow', (
      tester,
    ) async {
      await pumpApp(tester);

      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Today'), findsOneWidget);
      // Pet filter remains reachable at large text (horizontal scroller).
      expect(find.text('All pets'), findsOneWidget);
    });

    testWidgets('timeline renders in landscape without overflow', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.binding.setSurfaceSize(const Size(917, 411));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Today'), findsOneWidget);
    });
  });

  group('settings screens', () {
    testWidgets('reminder settings stays usable at 1.5x text scale', (
      tester,
    ) async {
      gateway.permission = NotificationPermission.granted;
      await tester.pumpWidget(
        MaterialApp(
          home: ReminderSettingsScreen(
            service: ReminderService(repo: repo, gateway: gateway),
          ),
        ),
      );
      await tester.pumpAndSettle();

      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Routine reminders'), findsOneWidget);
      // The master switch keeps its key (screen-reader test contract).
      expect(find.byKey(const Key('reminders-enabled')), findsOneWidget);
    });

    testWidgets('privacy status message is a live region', (tester) async {
      final files = AcceptingFileGateway();
      final service = DataPrivacyService(
        repo: repo,
        files: files,
        appSchemaVersion: TailTallyDatabase.currentSchemaVersion,
      );
      await tester.pumpWidget(
        MaterialApp(home: PrivacySettingsScreen(service: service)),
      );
      await tester.pumpAndSettle();

      // Change retention so a status message appears.
      await tester.tap(find.byKey(const Key('retention-preference')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep the last 3 months').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('privacy-status')), findsOneWidget);
      final live = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      );
      expect(live, findsOneWidget);
    });
  });
}
