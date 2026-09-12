import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/domain/backup.dart';

void main() {
  BackupSnapshot sampleSnapshot() => BackupSnapshot(
    manifest: BackupManifest(
      backupVersion: BackupManifest.currentBackupVersion,
      appSchemaVersion: 5,
      createdAtUtc: DateTime.utc(2026, 9, 12, 8, 30),
      deviceLabel: 'test-phone',
    ),
    members: const [
      BackupMember(id: 1, displayName: 'Alex', isLocalDeviceOwner: true),
      BackupMember(id: 2, displayName: 'Blair'),
    ],
    pets: const [
      BackupPet(id: 1, name: 'Biscuit', species: 'dog', photoRef: 'p/1.jpg'),
      BackupPet(id: 2, name: 'Miso', species: 'cat'),
    ],
    routines: const [
      BackupRoutine(
        id: 1,
        petId: 1,
        name: 'Morning walk',
        defaultAssigneeId: 1,
      ),
      BackupRoutine(id: 2, petId: 2, name: 'Litter scoop'),
    ],
    windows: const [
      BackupScheduleWindow(
        id: 1,
        routineId: 1,
        startHour: 7,
        startMinute: 0,
        endHour: 8,
        endMinute: 30,
        daysOfWeek: {1, 3, 5},
      ),
    ],
    completions: [
      BackupCompletion(
        routineId: 1,
        completedAtUtc: DateTime.utc(2026, 9, 11, 12, 15),
        kind: 'done',
        completedByMemberId: 1,
        note: 'long route',
      ),
    ],
    reminderSettingsJson: '{"schemaVersion":1,"notificationsEnabled":false}',
    retentionSettingsJson: '{"schemaVersion":1,"preference":"keep90Days"}',
  );

  group('backup encode/decode round trip', () {
    test('snapshot survives encode -> decode with ids and UTC instants', () {
      final original = sampleSnapshot();
      final decoded = decodeBackup(encodeBackup(original));

      expect(decoded.manifest.backupVersion, original.manifest.backupVersion);
      expect(decoded.manifest.createdAtUtc, original.manifest.createdAtUtc);
      expect(decoded.manifest.deviceLabel, 'test-phone');
      expect(decoded.members.length, 2);
      expect(decoded.pets.singleWhere((p) => p.id == 2).photoRef, isNull);
      expect(
        decoded.routines.singleWhere((r) => r.id == 1).defaultAssigneeId,
        1,
      );
      expect(decoded.windows.single.daysOfWeek, {1, 3, 5});
      expect(
        decoded.completions.single.completedAtUtc,
        DateTime.utc(2026, 9, 11, 12, 15),
      );
      expect(decoded.completions.single.note, 'long route');
      expect(decoded.reminderSettingsJson, original.reminderSettingsJson);
      expect(decoded.retentionSettingsJson, original.retentionSettingsJson);
    });

    test('non-object roots and bad JSON throw user-facing errors', () {
      expect(
        () => decodeBackup('not json'),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.reason,
            'reason',
            contains('not valid JSON'),
          ),
        ),
      );
      expect(
        () => decodeBackup('[1,2,3]'),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.reason,
            'reason',
            contains('JSON object'),
          ),
        ),
      );
      expect(
        () => decodeBackup('{}'),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.reason,
            'reason',
            contains('manifest'),
          ),
        ),
      );
    });
  });

  group('schema compatibility checks', () {
    test('v1 backup is readable by schema v4 and v5', () {
      final manifest = BackupManifest(
        backupVersion: 1,
        appSchemaVersion: 4,
        createdAtUtc: DateTime.utc(2026),
      );
      expect(
        BackupManifest.checkCompatibility(manifest, appSchemaVersion: 5),
        isNull,
      );
      expect(
        BackupManifest.checkCompatibility(manifest, appSchemaVersion: 4),
        isNull,
      );
    });

    test('unknown backup version is refused', () {
      final manifest = BackupManifest(
        backupVersion: 99,
        appSchemaVersion: 5,
        createdAtUtc: DateTime.utc(2026),
      );
      expect(
        BackupManifest.checkCompatibility(manifest, appSchemaVersion: 5),
        contains('unknown'),
      );
    });

    test('backup from a newer app schema is refused with guidance', () {
      final manifest = BackupManifest(
        backupVersion: 1,
        appSchemaVersion: 9,
        createdAtUtc: DateTime.utc(2026),
      );
      expect(
        BackupManifest.checkCompatibility(manifest, appSchemaVersion: 5),
        contains('newer'),
      );
    });

    test('app older than the backup format minimum is refused', () {
      final manifest = BackupManifest(
        backupVersion: 1,
        appSchemaVersion: 5,
        createdAtUtc: DateTime.utc(2026),
      );
      expect(
        BackupManifest.checkCompatibility(manifest, appSchemaVersion: 3),
        contains('schema v4'),
      );
    });
  });

  group('referential integrity validation', () {
    test('valid snapshot passes', () {
      expect(validateSnapshot(sampleSnapshot()), isNull);
    });

    test('routine referencing missing pet is caught', () {
      final snapshot = sampleSnapshot();
      final broken = BackupSnapshot(
        manifest: snapshot.manifest,
        pets: snapshot.pets,
        routines: const [
          BackupRoutine(id: 7, petId: 404, name: 'Ghost routine'),
        ],
      );
      expect(validateSnapshot(broken), contains('pet 404'));
    });

    test('completion referencing missing routine is caught', () {
      final snapshot = sampleSnapshot();
      final broken = BackupSnapshot(
        manifest: snapshot.manifest,
        members: snapshot.members,
        pets: snapshot.pets,
        routines: snapshot.routines,
        completions: [
          BackupCompletion(
            routineId: 42,
            completedAtUtc: DateTime.utc(2026, 9, 2),
            kind: 'done',
          ),
        ],
      );
      expect(validateSnapshot(broken), contains('routine 42'));
    });

    test('completion referencing missing member is caught', () {
      final broken = BackupSnapshot(
        manifest: sampleSnapshot().manifest,
        pets: const [BackupPet(id: 1, name: 'A', species: 'dog')],
        routines: const [BackupRoutine(id: 1, petId: 1, name: 'R')],
        completions: [
          BackupCompletion(
            routineId: 1,
            completedAtUtc: DateTime.utc(2026, 9, 1),
            kind: 'done',
            completedByMemberId: 77,
          ),
        ],
      );
      expect(validateSnapshot(broken), contains('household member 77'));
    });

    test('duplicate ids are caught', () {
      final broken = BackupSnapshot(
        manifest: sampleSnapshot().manifest,
        pets: const [
          BackupPet(id: 1, name: 'A', species: 'dog'),
          BackupPet(id: 1, name: 'B', species: 'cat'),
        ],
      );
      expect(validateSnapshot(broken), contains('duplicate pet ids'));
    });
  });
}
