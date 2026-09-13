import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/app/tail_tally_app.dart';
import 'package:tail_tally/data/database.dart';
import 'package:tail_tally/data/drift_repository.dart';
import 'package:tail_tally/data/seed_data.dart';
import 'package:tail_tally/domain/timeline.dart';

void main() {
  late TailTallyDatabase db;
  late DriftLocalDataRepository repo;
  late DateTime fakeNow;

  setUp(() async {
    db = TailTallyDatabase(NativeDatabase.memory());
    // Wednesday 2026-09-09, 09:00 local — with seed data that means:
    // Morning walk overdue, Evening feed + Litter scoop coming up.
    fakeNow = DateTime(2026, 9, 9, 9);
    repo = DriftLocalDataRepository(db, clock: () => fakeNow);
    await repo.ensureOpen();
    await seedSampleData(repo);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(TailTallyApp(repository: repo));
    await tester.pumpAndSettle(); // let the initial async refresh resolve
  }

  testWidgets('timeline shows grouped day view with status labels', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Today'), findsOneWidget);
    // Group headers are key-scoped because per-card status chips reuse the
    // same words as visible non-color status cues (issue #6).
    Finder header(TimelineGroup group) =>
        find.byKey(Key('group-header-${group.name}'));
    expect(header(TimelineGroup.overdue), findsOneWidget);
    expect(header(TimelineGroup.scheduled), findsOneWidget);
    expect(header(TimelineGroup.due), findsNothing);
    expect(header(TimelineGroup.completed), findsNothing);

    expect(find.text('Biscuit — Morning walk'), findsOneWidget);
    expect(find.text('Biscuit — Evening feed'), findsOneWidget);
    expect(find.textContaining('Litter scoop'), findsOneWidget);
  });

  testWidgets('complete flow: tap Done, add note, see handoff marker', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Done').first);
    await tester.pumpAndSettle(); // note dialog
    await tester.enterText(find.byType(TextField), 'long route');
    await tester.tap(find.byKey(const Key('note-save')));
    await tester.pumpAndSettle(); // refresh + snackbar

    expect(find.textContaining('Morning walk marked done'), findsOneWidget);
    expect(find.textContaining('Done by You • long route'), findsOneWidget);
    expect(find.byKey(const Key('group-header-completed')), findsOneWidget);

    // The completed card no longer offers a Done button.
    expect(
      find.descendant(
        of: find.widgetWithText(Card, 'Biscuit — Morning walk'),
        matching: find.widgetWithText(FilledButton, 'Done'),
      ),
      findsNothing,
    );
  });

  testWidgets('cancel in the note dialog records nothing', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Done').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Still overdue, no completion logged.
    expect(find.byKey(const Key('group-header-overdue')), findsOneWidget);
    expect(find.byKey(const Key('group-header-completed')), findsNothing);
    final events = await repo.listCompletions();
    expect(events.where((e) => e.note != null), isEmpty);
  });

  testWidgets('undo from the snackbar restores the Done button', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Done').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-save'))); // no note
    await tester.pumpAndSettle();

    expect(find.textContaining('Done by You'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle(); // undo + refresh

    expect(find.textContaining('Done by You'), findsNothing);
    expect(find.byKey(const Key('group-header-overdue')), findsOneWidget);
    final events = await repo.listCompletions();
    // Only yesterday's seeded event survives; today's completion was undone.
    expect(events, hasLength(1));
    expect(
      events.single.completedAtUtc,
      fakeNow.toUtc().subtract(const Duration(hours: 30)),
    );
  });

  testWidgets('pet filter narrows the timeline', (tester) async {
    await pumpApp(tester);

    // Timeline card for Mochi exists before filtering.
    expect(find.text('Mochi — Litter scoop'), findsOneWidget);
    await tester.tap(find.text('Mochi (cat)'));
    await tester.pumpAndSettle();

    expect(find.text('Mochi — Litter scoop'), findsOneWidget);
    expect(find.textContaining('Biscuit —'), findsNothing);

    await tester.tap(find.text('All pets'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Biscuit —'), findsNWidgets(2));
  });
}
