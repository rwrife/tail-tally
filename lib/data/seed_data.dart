import '../domain/entities.dart';
import 'drift_repository.dart';

/// Seeds a development database with a small sample household.
///
/// Only meant for local development and widget tests; the production app
/// starts empty. Safe to call repeatedly — seeding is skipped when pets
/// already exist.
Future<void> seedSampleData(DriftLocalDataRepository repo) async {
  final existingPets = await repo.listPets();
  if (existingPets.isNotEmpty) return;

  final you = await repo.addMember(
    const NewMember(displayName: 'You', isLocalDeviceOwner: true),
  );
  final roommate = await repo.addMember(
    const NewMember(displayName: 'Roommate'),
  );

  final dog = await repo.addPet(const NewPet(name: 'Biscuit', species: 'dog'));
  final cat = await repo.addPet(const NewPet(name: 'Mochi', species: 'cat'));

  final walk = await repo.addRoutine(
    NewRoutine(petId: dog.id, name: 'Morning walk', defaultAssigneeId: you.id),
  );
  final feed = await repo.addRoutine(
    NewRoutine(petId: dog.id, name: 'Evening feed'),
  );
  final litter = await repo.addRoutine(
    NewRoutine(
      petId: cat.id,
      name: 'Litter scoop',
      defaultAssigneeId: roommate.id,
    ),
  );

  await repo.addScheduleWindow(
    NewScheduleWindow(
      routineId: walk.id,
      startHour: 7,
      startMinute: 0,
      endHour: 8,
      endMinute: 30,
      daysOfWeek: const {1, 2, 3, 4, 5, 6, 7},
    ),
  );
  await repo.addScheduleWindow(
    NewScheduleWindow(
      routineId: feed.id,
      startHour: 18,
      startMinute: 0,
      endHour: 19,
      endMinute: 0,
      daysOfWeek: const {1, 2, 3, 4, 5, 6, 7},
    ),
  );
  await repo.addScheduleWindow(
    NewScheduleWindow(
      routineId: litter.id,
      startHour: 21,
      startMinute: 0,
      endHour: 22,
      endMinute: 0,
      daysOfWeek: const {1, 3, 5, 7},
    ),
  );

  final now = repo.now().toUtc();
  await repo.recordCompletion(
    NewCompletionEvent(
      routineId: walk.id,
      completedAtUtc: now.subtract(const Duration(hours: 30)),
      kind: CompletionKind.done,
      completedByMemberId: you.id,
    ),
  );
}
