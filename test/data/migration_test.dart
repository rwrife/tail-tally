import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/data/database.dart';
import 'package:tail_tally/data/drift_repository.dart';
import 'package:tail_tally/domain/entities.dart';

/// Exercises the v1 -> v2 migration path: an on-disk database created by a
/// previous schema version (completion events without `note`) must upgrade
/// in place, preserve existing rows, and gain the new column.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('tail_tally_migration');
    dbFile = File('${tempDir.path}/tail_tally_test.db');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('v1 database upgrades to v2 and preserves completion history', () async {
    // --- Phase 1: create the database, write history, then "downgrade" the
    // schema on disk to the v1 shape (no note column, user_version = 1).
    final v2 = TailTallyDatabase(NativeDatabase(dbFile));
    final v2Repo = DriftLocalDataRepository(v2);
    await v2Repo.ensureOpen();

    final pet = await v2Repo.addPet(
      const NewPet(name: 'Biscuit', species: 'dog'),
    );
    final routine = await v2Repo.addRoutine(
      NewRoutine(petId: pet.id, name: 'Morning walk'),
    );
    final completedAt = DateTime.utc(2026, 9, 1, 7, 30);
    await v2Repo.recordCompletion(
      NewCompletionEvent(
        routineId: routine.id,
        completedAtUtc: completedAt,
        kind: CompletionKind.done,
      ),
    );
    await v2.customStatement('ALTER TABLE completion_events DROP COLUMN note');
    await v2.customStatement('PRAGMA user_version = 1');
    await v2.close();

    // --- Phase 2: reopen with the current app code; beforeOpen must run
    // onUpgrade(1 -> 2) and re-add the note column.
    final upgraded = TailTallyDatabase(NativeDatabase(dbFile));
    final upgradedRepo = DriftLocalDataRepository(upgraded);
    await upgradedRepo.ensureOpen();

    final history = await upgradedRepo.listCompletions(routineId: routine.id);
    expect(history, hasLength(1));
    expect(history.single.completedAtUtc, completedAt);
    expect(history.single.note, isNull);

    // The new column is writable after migration.
    await upgradedRepo.recordCompletion(
      NewCompletionEvent(
        routineId: routine.id,
        completedAtUtc: DateTime.utc(2026, 9, 2, 7, 45),
        kind: CompletionKind.done,
        note: 'took the long route',
      ),
    );
    final updated = await upgradedRepo.listCompletions(routineId: routine.id);
    expect(updated.first.note, 'took the long route');
    expect(updated, hasLength(2));

    await upgraded.close();
  });
}
