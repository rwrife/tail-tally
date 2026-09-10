import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/data/database.dart';
import 'package:tail_tally/data/drift_repository.dart';
import 'package:tail_tally/data/seed_data.dart';
import 'package:tail_tally/domain/entities.dart';
import 'package:tail_tally/domain/schedule.dart';
import 'package:tail_tally/domain/task_workflow.dart';
import 'package:tail_tally/domain/timeline.dart';

void main() {
  late TailTallyDatabase db;
  late DriftLocalDataRepository repo;
  late DateTime fakeNow;

  setUp(() async {
    db = TailTallyDatabase(NativeDatabase.memory());
    // Wednesday 2026-09-09, 09:00 local.
    fakeNow = DateTime(2026, 9, 9, 9);
    repo = DriftLocalDataRepository(db, clock: () => fakeNow);
    await repo.ensureOpen();
  });

  tearDown(() async {
    await db.close();
  });

  Future<Pet> pet(String name) =>
      repo.addPet(NewPet(name: name, species: 'dog'));
  Future<Routine> routine(int petId, String name) =>
      repo.addRoutine(NewRoutine(petId: petId, name: name));
  Future<ScheduleWindow> daily(int routineId, int sh, int sm, int eh, int em) =>
      repo.addScheduleWindow(
        NewScheduleWindow(
          routineId: routineId,
          startHour: sh,
          startMinute: sm,
          endHour: eh,
          endMinute: em,
          daysOfWeek: const {1, 2, 3, 4, 5, 6, 7},
        ),
      );

  group('DailyTimelineBuilder', () {
    test('empty database produces an empty timeline', () async {
      expect(await DailyTimelineBuilder(repo).build(), isEmpty);
    });

    test('due/upcoming/overdue buckets from seed data at 09:00', () async {
      await seedSampleData(repo);
      // Seed: walk 07:00–08:30 daily (closed 30min ago, completed ~30h ago →
      // satisfies *yesterday's* window, not today's), feed 18:00–19:00
      // (later today), litter 21:00–22:00 on odd days incl. Wed.
      final groups = await DailyTimelineBuilder(repo).buildGrouped();
      expect(groups[TimelineGroup.overdue]!.map((e) => e.routine.name), [
        'Morning walk',
      ]);
      expect(groups[TimelineGroup.due], isEmpty);
      expect(
        groups[TimelineGroup.scheduled]!.map((e) => e.routine.name).toSet(),
        {'Evening feed', 'Litter scoop'},
      );
      expect(groups[TimelineGroup.completed], isEmpty);
    });

    test(
      'completion moves an instance into the completed group with handoff',
      () async {
        await seedSampleData(repo);
        final builder = DailyTimelineBuilder(repo);
        final before = await builder.build();
        final walk = before.firstWhere((e) => e.routine.name == 'Morning walk');

        final you = (await repo.listMembers()).firstWhere(
          (m) => m.isLocalDeviceOwner,
        );
        final outcome = await TaskWorkflow(repo)
            .complete(walk.instance, note: 'long route', memberId: you.id);
        expect(outcome, isA<Completed>());

        final after = await builder.build();
        final done = after.firstWhere((e) => e.routine.name == 'Morning walk');
        expect(done.status, TaskStatus.completed);
        expect(done.completedByName, 'You');
        expect(done.completion?.note, 'long route');
        final groups2 = await builder.buildGrouped();
        expect(
          groups2[TimelineGroup.overdue]!.where(
            (e) => e.routine.name == 'Morning walk',
          ),
          isEmpty,
        );
        expect(
          groups2[TimelineGroup.completed]!.map((e) => e.routine.name),
          contains('Morning walk'),
        );
      },
    );

    test('pet filter narrows the timeline', () async {
      await seedSampleData(repo);
      final dog = (await repo.listPets()).firstWhere(
        (p) => p.name == 'Biscuit',
      );
      final entries = await DailyTimelineBuilder(repo).build(petIds: {dog.id});
      expect(entries.map((e) => e.pet.name).toSet(), {'Biscuit'});
      expect(entries, isNotEmpty);
    });

    test('window with no completion at all is not wrongly satisfied', () async {
      final p = await pet('Rex');
      final r = await routine(p.id, 'Meds');
      await daily(r.id, 7, 0, 7, 30);
      // A completion from two days ago (inside the 30-day fetch window).
      await repo.recordCompletion(
        NewCompletionEvent(
          routineId: r.id,
          completedAtUtc: DateTime(2026, 9, 7, 7, 15).toUtc(),
          kind: CompletionKind.done,
        ),
      );
      final entries = await DailyTimelineBuilder(repo).build();
      expect(entries.single.status, TaskStatus.overdue);
    });
  });

  group('TaskWorkflow', () {
    Future<(Pet, Routine, ScheduleWindow)> fixture() async {
      final p = await pet('Biscuit');
      final r = await routine(p.id, 'Morning walk');
      final w = await daily(r.id, 7, 0, 8, 30);
      final inst = instanceStartingOn(w, fakeNow)!;
      return (p, r, inst.window);
    }

    test('complete records a UTC-normalized event with attribution', () async {
      final (_, _, w) = await fixture();
      final inst = instanceStartingOn(w, fakeNow)!;
      final you = await repo.addMember(
        const NewMember(displayName: 'You', isLocalDeviceOwner: true),
      );
      final outcome = await TaskWorkflow(repo)
          .complete(inst, note: 'park', memberId: you.id);
      expect(outcome, isA<Completed>());
      final event = (outcome as Completed).event;
      expect(event.completedAtUtc.isUtc, isTrue);
      expect(event.completedAtUtc, fakeNow.toUtc());
      expect(event.completedByMemberId, you.id);
      expect(event.note, 'park');
    });

    test(
      'duplicate completion is refused and no second event is written',
      () async {
        final (_, r, w) = await fixture();
        final inst = instanceStartingOn(w, fakeNow)!;
        final wf = TaskWorkflow(repo);
        final first = await wf.complete(inst);
        expect(first, isA<Completed>());

        final second = await wf.complete(inst, note: 'second tap');
        expect(second, isA<AlreadyCompleted>());
        expect(
          (second as AlreadyCompleted).existing.id,
          (first as Completed).event.id,
        );
        expect(await repo.listCompletions(routineId: r.id), hasLength(1));
      },
    );

    test('two members racing: only the first sticks', () async {
      final (_, _, w) = await fixture();
      final inst = instanceStartingOn(w, fakeNow)!;
      final a = await repo.addMember(const NewMember(displayName: 'Alex'));
      final b = await repo.addMember(const NewMember(displayName: 'Blair'));
      final wf = TaskWorkflow(repo);
      final results = await Future.wait([
        wf.complete(inst, memberId: a.id),
        wf.complete(inst, memberId: b.id),
      ]);
      expect(
        results.whereType<Completed>(),
        hasLength(1),
        reason: 'exactly one completion should stick',
      );
      expect(results.whereType<AlreadyCompleted>(), hasLength(1));
    });

    test('undo removes the event and reopens the instance', () async {
      final (_, r, w) = await fixture();
      final inst = instanceStartingOn(w, fakeNow)!;
      final wf = TaskWorkflow(repo);
      final outcome = await wf.complete(inst) as Completed;

      expect(await wf.isSatisfied(inst), isTrue);
      await wf.undo(outcome.event.id);
      expect(await wf.isSatisfied(inst), isFalse);
      expect(await repo.listCompletions(routineId: r.id), isEmpty);
      expect(inst.window.id, greaterThan(0));
    });

    test('skipped events do not block a later done completion', () async {
      final (_, r, w) = await fixture();
      final inst = instanceStartingOn(w, fakeNow)!;
      await repo.recordCompletion(
        NewCompletionEvent(
          routineId: r.id,
          completedAtUtc: fakeNow.toUtc(),
          kind: CompletionKind.skipped,
        ),
      );
      final outcome = await TaskWorkflow(repo).complete(inst);
      expect(outcome, isA<Completed>());
      expect(await repo.listCompletions(routineId: r.id), hasLength(2));
    });
  });

  group('UndoLedger', () {
    test('bounded to capacity, newest first', () {
      final ledger = UndoLedger(capacity: 3);
      for (final id in [1, 2, 3, 4]) {
        ledger.record(id);
      }
      expect(ledger.undoableIds, [4, 3, 2]);
      expect(ledger.canUndo(1), isFalse);
      expect(ledger.canUndo(2), isTrue);
      ledger.forget(3);
      expect(ledger.undoableIds, [4, 2]);
    });
  });
}
