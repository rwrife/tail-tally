import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/app/data_privacy_service.dart';
import 'package:tail_tally/data/database.dart';
import 'package:tail_tally/data/drift_repository.dart';
import 'package:tail_tally/domain/backup.dart';
import 'package:tail_tally/domain/entities.dart';
import 'package:tail_tally/domain/retention.dart';
import 'package:tail_tally/platform/file_sharing.dart';

void main() {
  late TailTallyDatabase db;
  late DriftLocalDataRepository repo;
  late NoopFileGateway files;
  late DateTime fakeNow;
  late DataPrivacyService service;

  setUp(() async {
    db = TailTallyDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 9, 12, 12);
    repo = DriftLocalDataRepository(db, clock: () => fakeNow);
    await repo.ensureOpen();
    files = NoopFileGateway();
    service = DataPrivacyService(
      repo: repo,
      files: files,
      appSchemaVersion: TailTallyDatabase.currentSchemaVersion,
      clock: () => fakeNow,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedTypicalData() async {
    final you = await repo.addMember(
      const NewMember(displayName: 'You', isLocalDeviceOwner: true),
    );
    final pet = await repo.addPet(
      const NewPet(name: 'Biscuit', species: 'dog'),
    );
    final routine = await repo.addRoutine(
      NewRoutine(
        petId: pet.id,
        name: 'Morning walk',
        defaultAssigneeId: you.id,
      ),
    );
    await repo.addScheduleWindow(
      NewScheduleWindow(
        routineId: routine.id,
        startHour: 7,
        startMinute: 0,
        endHour: 8,
        endMinute: 30,
        daysOfWeek: const {1, 2, 3, 4, 5, 6, 7},
      ),
    );
    await repo.recordCompletion(
      NewCompletionEvent(
        routineId: routine.id,
        completedAtUtc: DateTime.utc(2026, 9, 11, 7, 5),
        kind: CompletionKind.done,
        completedByMemberId: you.id,
        note: 'sunny',
      ),
    );
    await repo.writeReminderSettingsJson('{"schemaVersion":1}');
    await repo.writeRetentionSettingsJson(
      '{"schemaVersion":1,"preference":"keep365Days"}',
    );
  }

  group('backup export', () {
    test(
      'export writes a versioned JSON payload through the gateway',
      () async {
        await seedTypicalData();
        files.saveResult = true;
        final fileName = await service.exportBackup(deviceLabel: 'unit-test');

        expect(fileName, 'tail-tally-backup-20260912-120000.json');
        expect(files.saved, hasLength(1));
        final saved = files.saved.single;
        expect(saved.mimeType, 'application/json');
        expect(saved.content, contains('"backupVersion": 1'));
        expect(saved.content, contains('"appSchemaVersion": 5'));
        expect(saved.content, contains('Biscuit'));
        expect(saved.content, contains('sunny'));
        expect(saved.content, contains('keep365Days'));
      },
    );

    test('cancel (gateway save false) returns null filename', () async {
      await seedTypicalData();
      // NoopFileGateway always reports save failure — models cancel.
      final fileName = await service.exportBackup();
      expect(fileName, isNull);
      expect(files.saved, hasLength(1)); // payload built, but not "written"
    });
  });

  group('backup import', () {
    test('round trip: export, wipe, import restores everything', () async {
      await seedTypicalData();
      final snapshot = await service.buildBackup();
      final json = _encodeForImport(snapshot);

      final summary = await service.importBackupText(json);
      expect(summary.pets, 1);
      expect(summary.routines, 1);
      expect(summary.completions, 1);

      // Ids are preserved so history and cross-references survive.
      final pets = await repo.listPets();
      expect(pets.single.name, 'Biscuit');
      final routines = await repo.listRoutines();
      expect(routines.single.defaultAssigneeId, isNotNull);
      final completions = await repo.listCompletions();
      expect(completions.single.note, 'sunny');
      expect(
        completions.single.completedAtUtc,
        DateTime.utc(2026, 9, 11, 7, 5),
      );
      expect(await repo.readReminderSettingsJson(), '{"schemaVersion":1}');
      expect(await repo.readRetentionSettingsJson(), contains('keep365Days'));
    });

    test('import replaces existing data, not merges', () async {
      await seedTypicalData();
      // Snapshot taken while only Biscuit exists.
      final snapshot = await service.buildBackup();
      final trimmedJson = _encodeForImport(snapshot);

      final miso = await repo.addPet(
        const NewPet(name: 'Miso', species: 'cat'),
      );
      expect(await repo.listPets(), hasLength(2));

      await service.importBackupText(trimmedJson);
      // Re-export from imported state — Miso was replaced away.
      final again = await service.buildBackup();
      expect(again.pets.map((p) => p.name), ['Biscuit']);
      final pets = await repo.listPets();
      expect(pets.map((p) => p.id), isNot(contains(miso.id)));
    });

    test('incompatible future schema is refused and store untouched', () async {
      await seedTypicalData();
      final future =
          '{"manifest":{"backupVersion":1,"appSchemaVersion":99,'
          '"createdAtUtc":"2026-09-01T00:00:00Z"},"pets":[],"routines":[],'
          '"scheduleWindows":[],"completionEvents":[],"members":[]}';
      await expectLater(
        service.importBackupText(future),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.reason,
            'reason',
            contains('newer'),
          ),
        ),
      );
      expect(await repo.listPets(), hasLength(1)); // unchanged
    });

    test('referentially broken backup is refused atomically', () async {
      await seedTypicalData();
      final broken =
          '{"manifest":{"backupVersion":1,"appSchemaVersion":5,'
          '"createdAtUtc":"2026-09-01T00:00:00Z"},'
          '"pets":[{"id":1,"name":"Ghost","species":"dog"}],'
          '"routines":[{"id":1,"petId":404,"name":"Orphan"}],'
          '"scheduleWindows":[],"completionEvents":[],"members":[]}';
      await expectLater(
        service.importBackupText(broken),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.reason,
            'reason',
            contains('inconsistent'),
          ),
        ),
      );
      expect((await repo.listPets()).single.name, 'Biscuit'); // unchanged
    });

    test(
      'pickAndValidateBackup returns raw on success, null on cancel',
      () async {
        await seedTypicalData();
        final snapshot = await service.buildBackup();
        files.openPayload = _encodeForImport(snapshot);
        final raw = await service.pickAndValidateBackup();
        expect(raw, isNotNull);
        expect(await repo.listPets(), hasLength(1)); // NOT applied yet

        files.openPayload = null;
        expect(await service.pickAndValidateBackup(), isNull);
      },
    );
  });

  group('csv export', () {
    test('range filter + header + resolved names', () async {
      await seedTypicalData();
      files.saveResult = true;
      final fileName = await service.exportCsvRange(
        fromUtc: DateTime.utc(2026, 9, 1),
        toUtc: DateTime.utc(2026, 9, 12),
      );
      expect(fileName, 'tail-tally-history-20260901-to-20260912.csv');
      final csv = files.saved.last.content;
      final lines = csv.trimRight().split('\n');
      expect(lines.length, 2);
      expect(
        lines[1],
        '2026-09-11T07:05:00.000Z,Biscuit,Morning walk,done,You,1,sunny',
      );
    });

    test('empty range exports header only', () async {
      await seedTypicalData();
      await service.exportCsvRange(
        fromUtc: DateTime.utc(2020),
        toUtc: DateTime.utc(2021),
      );
      expect(files.saved.last.content, endsWith('\n'));
      expect(
        files.saved.last.content.trim(),
        'completed_at_utc,pet,routine,kind,completed_by,routine_id,note',
      );
    });
  });

  group('retention', () {
    test('keep90Days prunes only old events and persists preference', () async {
      final pet = await repo.addPet(const NewPet(name: 'A', species: 'dog'));
      final routine = await repo.addRoutine(
        NewRoutine(petId: pet.id, name: 'R'),
      );
      final old = await repo.recordCompletion(
        NewCompletionEvent(
          routineId: routine.id,
          completedAtUtc: fakeNow.subtract(const Duration(days: 200)),
          kind: CompletionKind.done,
        ),
      );
      final recent = await repo.recordCompletion(
        NewCompletionEvent(
          routineId: routine.id,
          completedAtUtc: fakeNow.subtract(const Duration(days: 5)),
          kind: CompletionKind.done,
        ),
      );

      final result = await service.applyRetention(
        RetentionPreference.keep90Days,
      );
      expect(result.prunedCount, 1);
      final remaining = await repo.listCompletions();
      expect(remaining.map((c) => c.id), [recent.id]);
      expect(remaining.single.id, isNot(old.id));
      expect(await service.loadRetention(), RetentionPreference.keep90Days);
    });

    test('keepAll prunes nothing', () async {
      await seedTypicalData();
      final before = await repo.listCompletions();
      final result = await service.applyRetention(RetentionPreference.keepAll);
      expect(result.prunedCount, 0);
      expect(await repo.listCompletions(), hasLength(before.length));
    });
  });

  group('delete all data', () {
    test('verified erasure empties every table including settings', () async {
      await seedTypicalData();
      final result = await service.deleteAllData();
      expect(result.verified, isTrue);
      expect(await repo.listPets(), isEmpty);
      expect(await repo.listRoutines(), isEmpty);
      expect(await repo.listScheduleWindows(), isEmpty);
      expect(await repo.listCompletions(), isEmpty);
      expect(await repo.listMembers(), isEmpty);
      expect(await repo.readReminderSettingsJson(), isNull);
      expect(await repo.readRetentionSettingsJson(), isNull);
    });

    test('fresh store can be repopulated after erasure', () async {
      await seedTypicalData();
      await service.deleteAllData();
      final pet = await repo.addPet(const NewPet(name: 'New', species: 'cat'));
      expect(pet.id, greaterThan(0));
      expect(await repo.listPets(), hasLength(1));
    });
  });
}

/// Re-encode a snapshot the way the export path does, so import sees the
/// exact on-disk format (pretty JSON).
String _encodeForImport(BackupSnapshot snapshot) => encodeBackup(snapshot);
