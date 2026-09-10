import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/data/database.dart';
import 'package:tail_tally/data/drift_repository.dart';
import 'package:tail_tally/data/seed_data.dart';
import 'package:tail_tally/domain/entities.dart';

void main() {
  late TailTallyDatabase db;
  late DriftLocalDataRepository repo;
  late DateTime fakeNow;

  setUp(() {
    db = TailTallyDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 9, 9, 12);
    repo = DriftLocalDataRepository(db, clock: () => fakeNow);
  });

  tearDown(() async {
    await db.close();
  });

  group('clock injection', () {
    test('repo.now uses the injected clock deterministically', () {
      expect(repo.now(), fakeNow);
      fakeNow = fakeNow.add(const Duration(hours: 1));
      expect(repo.now(), fakeNow);
    });
  });

  group('members CRUD', () {
    test('add, list, rename, remove', () async {
      final a = await repo.addMember(
        const NewMember(displayName: 'Alex', isLocalDeviceOwner: true),
      );
      final b = await repo.addMember(const NewMember(displayName: 'Blair'));

      var members = await repo.listMembers();
      expect(members, hasLength(2));
      expect(a.isLocalDeviceOwner, isTrue);
      expect(b.isLocalDeviceOwner, isFalse);

      await repo.renameMember(a.id, 'Alexandra');
      members = await repo.listMembers();
      expect(members.firstWhere((m) => m.id == a.id).displayName, 'Alexandra');

      await repo.removeMember(b.id);
      members = await repo.listMembers();
      expect(members.map((m) => m.displayName), ['Alexandra']);
    });
  });

  group('pets CRUD', () {
    test('add, list, update, remove', () async {
      final pet = await repo.addPet(
        const NewPet(name: 'Biscuit', species: 'dog', photoRef: 'files/a.jpg'),
      );
      expect(pet.id, greaterThan(0));
      expect(pet.photoRef, 'files/a.jpg');

      await repo.updatePet(
        Pet(id: pet.id, name: 'Biscuit', species: 'dog', photoRef: null),
      );
      final pets = await repo.listPets();
      expect(pets.single.photoRef, isNull);

      await repo.removePet(pet.id);
      expect(await repo.listPets(), isEmpty);
    });

    test('removing a pet cascades to its routines and windows', () async {
      final pet = await repo.addPet(
        const NewPet(name: 'Mochi', species: 'cat'),
      );
      final routine = await repo.addRoutine(
        NewRoutine(petId: pet.id, name: 'Litter scoop'),
      );
      await repo.addScheduleWindow(
        NewScheduleWindow(
          routineId: routine.id,
          startHour: 21,
          startMinute: 0,
          endHour: 22,
          endMinute: 0,
          daysOfWeek: const {1, 3, 5},
        ),
      );

      await repo.removePet(pet.id);

      expect(await repo.listPets(), isEmpty);
      expect(await repo.listRoutines(), isEmpty);
      expect(await repo.listScheduleWindows(), isEmpty);
    });
  });

  group('routines and schedule windows', () {
    test('routine default assignee survives round trip', () async {
      final member = await repo.addMember(const NewMember(displayName: 'Sam'));
      final pet = await repo.addPet(const NewPet(name: 'Rex', species: 'dog'));
      final routine = await repo.addRoutine(
        NewRoutine(
          petId: pet.id,
          name: 'Morning walk',
          defaultAssigneeId: member.id,
        ),
      );
      expect(routine.defaultAssigneeId, member.id);
      final loaded = await repo.listRoutines(petId: pet.id);
      expect(loaded.single.defaultAssigneeId, member.id);
    });

    test('schedule window days-of-week and midnight flag round trip', () async {
      final pet = await repo.addPet(const NewPet(name: 'Rex', species: 'dog'));
      final routine = await repo.addRoutine(
        NewRoutine(petId: pet.id, name: 'Walk'),
      );
      final window = await repo.addScheduleWindow(
        NewScheduleWindow(
          routineId: routine.id,
          startHour: 22,
          startMinute: 30,
          endHour: 6,
          endMinute: 0,
          daysOfWeek: const {1, 3, 5, 7},
          crossesMidnight: true,
        ),
      );

      final loaded = await repo.listScheduleWindows(routineId: routine.id);
      expect(loaded.single.daysOfWeek, {1, 3, 5, 7});
      expect(loaded.single.crossesMidnight, isTrue);
      expect(loaded.single.startHour, window.startHour);
      expect(loaded.single.endMinute, window.endMinute);
    });

    test('removing a routine cascades to windows and completions', () async {
      final pet = await repo.addPet(const NewPet(name: 'Rex', species: 'dog'));
      final routine = await repo.addRoutine(
        NewRoutine(petId: pet.id, name: 'Feed'),
      );
      await repo.addScheduleWindow(
        NewScheduleWindow(
          routineId: routine.id,
          startHour: 8,
          startMinute: 0,
          endHour: 9,
          endMinute: 0,
          daysOfWeek: const {1},
        ),
      );
      await repo.recordCompletion(
        NewCompletionEvent(
          routineId: routine.id,
          completedAtUtc: fakeNow,
          kind: CompletionKind.done,
        ),
      );

      await repo.removeRoutine(routine.id);
      expect(await repo.listScheduleWindows(), isEmpty);
      expect(await repo.listCompletions(), isEmpty);
    });
  });

  group('completion events', () {
    late int petId;
    late int routineId;
    late int memberId;

    setUp(() async {
      final member = await repo.addMember(
        const NewMember(displayName: 'Jordan', isLocalDeviceOwner: true),
      );
      final pet = await repo.addPet(
        const NewPet(name: 'Bella', species: 'dog'),
      );
      final routine = await repo.addRoutine(
        NewRoutine(petId: pet.id, name: 'Evening feed'),
      );
      memberId = member.id;
      petId = pet.id;
      routineId = routine.id;
      expect(petId, isNonNegative);
    });

    test('record, list newest-first, filter by range', () async {
      final base = DateTime.utc(2026, 9, 1, 8);
      for (var i = 0; i < 3; i++) {
        await repo.recordCompletion(
          NewCompletionEvent(
            routineId: routineId,
            completedAtUtc: base.add(Duration(days: i)),
            kind: CompletionKind.done,
            completedByMemberId: memberId,
            note: i == 1 ? 'ate slowly' : null,
          ),
        );
      }

      final all = await repo.listCompletions(routineId: routineId);
      expect(all, hasLength(3));
      expect(all.first.completedAtUtc, base.add(const Duration(days: 2)));
      expect(all.first.note, isNull);
      expect(all[1].note, 'ate slowly');

      final ranged = await repo.listCompletions(
        routineId: routineId,
        fromUtc: base,
        toUtc: base.add(const Duration(days: 2)),
      );
      expect(ranged, hasLength(2));
    });

    test('mixed-offset inputs are normalized to UTC instants', () async {
      // Same instant expressed as local time and as UTC must store
      // identically (epoch-based storage per the timestamp contract).
      // The second event is a `skipped` at the same instant: `done` events
      // are unique per (routine, instant) by the v3 partial index, skips
      // are outside that constraint.
      final asUtc = DateTime.utc(2026, 9, 8, 21, 30);
      final asLocal = asUtc.toLocal();

      final a = await repo.recordCompletion(
        NewCompletionEvent(
          routineId: routineId,
          completedAtUtc: asUtc,
          kind: CompletionKind.done,
        ),
      );
      final b = await repo.recordCompletion(
        NewCompletionEvent(
          routineId: routineId,
          completedAtUtc: asLocal,
          kind: CompletionKind.skipped,
        ),
      );

      expect(a.completedAtUtc, asUtc);
      expect(
        b.completedAtUtc.toUtc().millisecondsSinceEpoch,
        asUtc.millisecondsSinceEpoch,
      );
    });

    test(
      'duplicate done events at the same instant are rejected by the store',
      () async {
        final at = DateTime.utc(2026, 9, 8, 21, 30);
        await repo.recordCompletion(
          NewCompletionEvent(
            routineId: routineId,
            completedAtUtc: at,
            kind: CompletionKind.done,
          ),
        );
        await expectLater(
          repo.recordCompletion(
            NewCompletionEvent(
              routineId: routineId,
              completedAtUtc: at,
              kind: CompletionKind.done,
            ),
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('lastCompletionFor returns most recent or null', () async {
      expect(await repo.lastCompletionFor(routineId), isNull);

      final earlier = await repo.recordCompletion(
        NewCompletionEvent(
          routineId: routineId,
          completedAtUtc: DateTime.utc(2026, 9, 1),
          kind: CompletionKind.skipped,
        ),
      );
      final later = await repo.recordCompletion(
        NewCompletionEvent(
          routineId: routineId,
          completedAtUtc: DateTime.utc(2026, 9, 5),
          kind: CompletionKind.done,
          completedByMemberId: memberId,
        ),
      );

      final last = await repo.lastCompletionFor(routineId);
      expect(last?.id, later.id);
      expect(last?.kind, CompletionKind.done);
      expect(later.completedByMemberId, memberId);
      expect(earlier.kind, CompletionKind.skipped);
    });

    test('deleteCompletion removes the event (undo path)', () async {
      final event = await repo.recordCompletion(
        NewCompletionEvent(
          routineId: routineId,
          completedAtUtc: fakeNow,
          kind: CompletionKind.done,
        ),
      );
      await repo.deleteCompletion(event.id);
      expect(await repo.listCompletions(), isEmpty);
      expect(await repo.lastCompletionFor(routineId), isNull);
    });
  });

  group('seed data', () {
    test('seeds once and is idempotent', () async {
      await seedSampleData(repo);
      final pets = await repo.listPets();
      expect(pets, hasLength(2));
      expect(await repo.listMembers(), hasLength(2));
      expect(await repo.listRoutines(), hasLength(3));
      expect(await repo.listScheduleWindows(), hasLength(3));

      await seedSampleData(repo);
      expect(await repo.listPets(), hasLength(2));
    });
  });
}
