/// Privacy / data-ownership service (issue #5).
///
/// Orchestrates backup export/import, CSV history export, retention
/// pruning, and the delete-all-data action over [LocalDataRepository] and
/// [FileGateway]. Everything user-visible is explicit: nothing is written
/// to disk or deleted without a direct request, and imports validate
/// schema compatibility + referential integrity *before* touching the
/// store (the swap itself is one store transaction, so a rejected import
/// leaves the current database untouched).
library;

import '../domain/backup.dart';
import '../domain/csv_export.dart';
import '../domain/entities.dart';
import '../domain/retention.dart';
import '../platform/file_sharing.dart';

/// Result of a successful import, for confirmation UIs.
class ImportSummary {
  const ImportSummary({
    required this.pets,
    required this.routines,
    required this.completions,
    required this.exportedAtUtc,
  });

  final int pets;
  final int routines;
  final int completions;
  final DateTime exportedAtUtc;
}

/// Outcome of the delete-all-data action plus verification pass.
class ErasureResult {
  const ErasureResult({required this.verified});

  /// True when a post-deletion read confirms the store is empty.
  final bool verified;
}

class DataPrivacyService {
  DataPrivacyService({
    required this._repo,
    required this._files,
    required this._appSchemaVersion,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LocalDataRepository _repo;
  final FileGateway _files;
  final int _appSchemaVersion;
  final DateTime Function() _clock;

  DateTime _nowUtc() => _clock().toUtc();

  // ------------------------------------------------------------- backups

  /// Build a versioned snapshot of everything the app owns.
  Future<BackupSnapshot> buildBackup({String? deviceLabel}) async {
    final members = await _repo.listMembers();
    final pets = await _repo.listPets();
    final routines = await _repo.listRoutines();
    final windows = await _repo.listScheduleWindows();
    final completions = await _repo.listCompletions();
    final settings = await _repo.readReminderSettingsJson();
    final retention = await _repo.readRetentionSettingsJson();
    return BackupSnapshot(
      manifest: BackupManifest(
        backupVersion: BackupManifest.currentBackupVersion,
        appSchemaVersion: _appSchemaVersion,
        createdAtUtc: _nowUtc(),
        deviceLabel: deviceLabel,
      ),
      members: [
        for (final m in members)
          BackupMember(
            id: m.id,
            displayName: m.displayName,
            isLocalDeviceOwner: m.isLocalDeviceOwner,
          ),
      ],
      pets: [
        for (final p in pets)
          BackupPet(
            id: p.id,
            name: p.name,
            species: p.species,
            photoRef: p.photoRef,
          ),
      ],
      routines: [
        for (final r in routines)
          BackupRoutine(
            id: r.id,
            petId: r.petId,
            name: r.name,
            defaultAssigneeId: r.defaultAssigneeId,
          ),
      ],
      windows: [
        for (final w in windows)
          BackupScheduleWindow(
            id: w.id,
            routineId: w.routineId,
            startHour: w.startHour,
            startMinute: w.startMinute,
            endHour: w.endHour,
            endMinute: w.endMinute,
            daysOfWeek: w.daysOfWeek,
            crossesMidnight: w.crossesMidnight,
          ),
      ],
      completions: [
        for (final c in completions)
          BackupCompletion(
            routineId: c.routineId,
            completedAtUtc: c.completedAtUtc,
            kind: c.kind.name,
            completedByMemberId: c.completedByMemberId,
            note: c.note,
          ),
      ],
      reminderSettingsJson: settings,
      retentionSettingsJson: retention,
    );
  }

  /// Export a backup through the file gateway. Returns the filename when
  /// the user chose a destination, null on cancel.
  Future<String?> exportBackup({String? deviceLabel}) async {
    final snapshot = await buildBackup(deviceLabel: deviceLabel);
    final fileName = backupFileName(snapshot.manifest.createdAtUtc);
    final ok = await _files.saveTextFile(
      fileName: fileName,
      content: encodeBackup(snapshot),
      mimeType: 'application/json',
    );
    return ok ? fileName : null;
  }

  /// Ask the user for a backup file and fully validate it (parse +
  /// schema compatibility + referential integrity) *without* applying
  /// anything. Returns the raw JSON text to hand to [importBackupText]
  /// once the user confirms, or null when the picker was cancelled.
  /// Throws [BackupFormatException] with a user-facing reason when the
  /// payload is unreadable or incompatible.
  Future<String?> pickAndValidateBackup() async {
    final raw = await _files.openTextFile();
    if (raw == null) return null;
    final snapshot = decodeBackup(raw);
    final compat = BackupManifest.checkCompatibility(
      snapshot.manifest,
      appSchemaVersion: _appSchemaVersion,
    );
    if (compat != null) {
      throw BackupFormatException(compat);
    }
    final integrity = validateSnapshot(snapshot);
    if (integrity != null) {
      throw BackupFormatException('backup is inconsistent: $integrity');
    }
    return raw;
  }

  /// Re-validate and apply backup [raw], replacing all local data.
  Future<ImportSummary> importBackupText(String raw) async {
    final snapshot = decodeBackup(raw);
    final compat = BackupManifest.checkCompatibility(
      snapshot.manifest,
      appSchemaVersion: _appSchemaVersion,
    );
    if (compat != null) {
      throw BackupFormatException(compat);
    }
    final integrity = validateSnapshot(snapshot);
    if (integrity != null) {
      throw BackupFormatException('backup is inconsistent: $integrity');
    }
    await _repo.restoreSnapshot(snapshot);
    return ImportSummary(
      pets: snapshot.pets.length,
      routines: snapshot.routines.length,
      completions: snapshot.completions.length,
      exportedAtUtc: snapshot.manifest.createdAtUtc,
    );
  }

  // ---------------------------------------------------------- CSV export

  /// Export completions in [fromUtc]..[toUtc) as CSV. Returns the filename
  /// when saved, null when the user cancelled.
  Future<String?> exportCsvRange({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final events = await _repo.listCompletions(fromUtc: fromUtc, toUtc: toUtc);
    final routines = await _repo.listRoutines();
    final pets = await _repo.listPets();
    final members = await _repo.listMembers();
    final rows = buildCsvRows(
      events: events,
      routineById: {for (final r in routines) r.id: r},
      petNameById: {for (final p in pets) p.id: p.name},
      memberNameById: {for (final m in members) m.id: m.displayName},
    );
    final fileName = csvFileName(fromUtc, toUtc);
    final ok = await _files.saveTextFile(
      fileName: fileName,
      content: encodeCsv(rows),
      mimeType: 'text/csv',
    );
    return ok ? fileName : null;
  }

  // ------------------------------------------------------------ retention

  /// Read the persisted retention preference (keepAll when unset).
  Future<RetentionPreference> loadRetention() async {
    final raw = await _repo.readRetentionSettingsJson();
    return decodeRetentionSettings(raw);
  }

  /// Persist a retention preference (does not prune by itself).
  Future<void> saveRetention(RetentionPreference preference) =>
      _repo.writeRetentionSettingsJson(encodeRetentionSettings(preference));

  /// Delete completion events older than [preference] allows and persist
  /// the preference itself.
  Future<RetentionPruneResult> applyRetention(
    RetentionPreference preference,
  ) async {
    await saveRetention(preference);
    if (preference == RetentionPreference.keepAll) {
      return RetentionPruneResult(preference: preference, prunedCount: 0);
    }
    final all = await _repo.listCompletions();
    final prunable = selectPrunable(
      events: all,
      preference: preference,
      now: _nowUtc(),
    );
    for (final e in prunable) {
      await _repo.deleteCompletion(e.id);
    }
    return RetentionPruneResult(
      preference: preference,
      prunedCount: prunable.length,
      cutoffUtc: _nowUtc().subtract(preference.window!),
    );
  }

  // --------------------------------------------------------- delete-all

  /// Erase every user-owned row from the local store, then verify.
  Future<ErasureResult> deleteAllData() async {
    await _repo.deleteAllLocalData();
    final pets = await _repo.listPets();
    final routines = await _repo.listRoutines();
    final windows = await _repo.listScheduleWindows();
    final completions = await _repo.listCompletions();
    final members = await _repo.listMembers();
    final settings = await _repo.readReminderSettingsJson();
    final retention = await _repo.readRetentionSettingsJson();
    final empty =
        pets.isEmpty &&
        routines.isEmpty &&
        windows.isEmpty &&
        completions.isEmpty &&
        members.isEmpty &&
        settings == null &&
        retention == null;
    return ErasureResult(verified: empty);
  }
}
