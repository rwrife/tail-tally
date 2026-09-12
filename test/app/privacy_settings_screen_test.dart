import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/app/data_privacy_service.dart';
import 'package:tail_tally/app/privacy_settings_screen.dart';
import 'package:tail_tally/data/database.dart';
import 'package:tail_tally/data/drift_repository.dart';
import 'package:tail_tally/domain/backup.dart';
import 'package:tail_tally/domain/entities.dart';
import 'package:tail_tally/domain/retention.dart';
import 'package:tail_tally/platform/file_sharing.dart';

/// Gateway whose saves always succeed, for asserting success paths.
class AcceptingFileGateway implements FileGateway {
  String? lastContent;
  String? lastFileName;
  String? openPayload;

  @override
  Future<bool> saveTextFile({
    required String fileName,
    required String content,
    required String mimeType,
  }) async {
    lastFileName = fileName;
    lastContent = content;
    return true;
  }

  @override
  Future<String?> openTextFile() async => openPayload;
}

void main() {
  late TailTallyDatabase db;
  late DriftLocalDataRepository repo;
  late AcceptingFileGateway files;
  late DateTime fakeNow;
  late DataPrivacyService service;

  setUp(() async {
    db = TailTallyDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 9, 12, 12);
    repo = DriftLocalDataRepository(db, clock: () => fakeNow);
    await repo.ensureOpen();
    files = AcceptingFileGateway();
    service = DataPrivacyService(
      repo: repo,
      files: files,
      appSchemaVersion: TailTallyDatabase.currentSchemaVersion,
      clock: () => fakeNow,
    );
    final pet = await repo.addPet(
      const NewPet(name: 'Biscuit', species: 'dog'),
    );
    final routine = await repo.addRoutine(
      NewRoutine(petId: pet.id, name: 'Morning walk'),
    );
    await repo.recordCompletion(
      NewCompletionEvent(
        routineId: routine.id,
        completedAtUtc: DateTime.utc(2026, 9, 11, 7, 5),
        kind: CompletionKind.done,
        note: 'sunny',
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PrivacySettingsScreen(service: service)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('screen lists the local data controls', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Privacy & data'), findsOneWidget);
    expect(find.text('Export backup (JSON)'), findsOneWidget);
    expect(find.text('Export history (CSV)'), findsOneWidget);
    expect(find.text('Restore from backup'), findsOneWidget);
    expect(find.text('History retention'), findsOneWidget);
    expect(find.text('Delete all data on this device'), findsOneWidget);
    expect(
      find.textContaining('no account, no sync, no telemetry'),
      findsOneWidget,
    );
  });

  testWidgets('backup export reports the written filename', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Export backup (JSON)'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('tail-tally-backup-20260912-120000.json'),
      findsOneWidget,
    );
    expect(files.lastContent, contains('"backupVersion": 1'));
  });

  testWidgets('delete-all requires confirmation and verifies afterwards', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('delete-all-data')));
    await tester.pumpAndSettle();
    expect(find.text('Delete all Tail Tally data?'), findsOneWidget);

    // Cancel keeps data.
    await tester.tap(find.text('Keep my data'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Delete cancelled'), findsOneWidget);
    expect(await repo.listPets(), hasLength(1));

    // Confirm deletes and verifies.
    await tester.tap(find.byKey(const Key('delete-all-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-all-confirm')));
    await tester.pumpAndSettle();

    expect(
      find.text('All local data deleted and verified empty.'),
      findsOneWidget,
    );
    expect(await repo.listPets(), isEmpty);
    expect(await repo.listCompletions(), isEmpty);
  });

  testWidgets('import cancel leaves data untouched', (tester) async {
    await pumpScreen(tester);
    files.openPayload = null; // picker dismissed
    await tester.tap(find.byKey(const Key('import-backup')));
    await tester.pumpAndSettle();
    expect(
      find.text('Import cancelled — no file was selected.'),
      findsOneWidget,
    );
    expect(await repo.listPets(), hasLength(1));
  });

  testWidgets('incompatible import shows the reason and keeps data', (
    tester,
  ) async {
    await pumpScreen(tester);
    files.openPayload =
        '{"manifest":{"backupVersion":1,"appSchemaVersion":99,'
        '"createdAtUtc":"2026-09-01T00:00:00Z"},"pets":[]}';
    await tester.tap(find.byKey(const Key('import-backup')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Import failed'), findsOneWidget);
    expect(find.textContaining('newer'), findsOneWidget);
    expect(await repo.listPets(), hasLength(1));
  });

  testWidgets('valid import asks to replace, then applies', (tester) async {
    await pumpScreen(tester);
    final snapshot = await service.buildBackup();
    files.openPayload = encodeBackupForTest(snapshot);

    await tester.tap(find.byKey(const Key('import-backup')));
    await tester.pumpAndSettle();
    expect(find.text('Replace all local data?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('import-confirm')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Import complete'), findsOneWidget);
    expect(await repo.listPets(), hasLength(1));
    expect((await repo.listCompletions()).single.note, 'sunny');
  });

  testWidgets('retention dropdown persists the choice', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Keep all history'), findsWidgets);

    await tester.tap(find.byKey(const Key('retention-preference')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep the last 3 months').last);
    await tester.pumpAndSettle();

    expect(await service.loadRetention(), RetentionPreference.keep90Days);
    expect(
      find.textContaining('Retention set: Keep the last 3 months'),
      findsOneWidget,
    );
  });
}

/// Expose the domain encoder for test payloads.
String encodeBackupForTest(BackupSnapshot snapshot) => encodeBackup(snapshot);
