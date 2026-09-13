/// Privacy & data screen (issue #5): explicit, local-only data controls —
/// JSON backup export/import, CSV history export over a selectable date
/// range, retention preferences, and a confirmed delete-all-data action
/// with a verification path. No cloud, no account: every action here is a
/// user-initiated read or write of files on this device.
library;

import 'package:flutter/material.dart';

import '../domain/backup.dart';
import '../domain/retention.dart';
import 'data_privacy_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key, required this.service});

  final DataPrivacyService service;

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

/// Compact busy spinner (the full-size progress indicator is too heavy for
/// a list-row trailing slot).
class _TinySpinner extends StatelessWidget {
  const _TinySpinner();

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator(strokeWidth: 2);
  }
}

/// Visible + spoken busy cue shown in a row's trailing slot while an
/// operation runs (issue #6: previously an invisible spacer).
class _BusyIndicator extends StatelessWidget {
  const _BusyIndicator();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Working…',
      child: const SizedBox(width: 20, height: 20, child: _TinySpinner()),
    );
  }
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _busy = false;
  String? _status;
  RetentionPreference _retention = RetentionPreference.keepAll;

  Future<T?> _guard<T>(Future<T> Function() action) async {
    setState(() => _busy = true);
    try {
      final result = await action();
      if (mounted) setState(() => _busy = false);
      return result;
    } on BackupFormatException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = 'Import failed: ${e.reason}';
        });
      }
      return null;
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = 'Something went wrong: $e';
        });
      }
      return null;
    }
  }

  void _say(String message) {
    if (mounted) setState(() => _status = message);
  }

  @override
  void initState() {
    super.initState();
    _loadRetention();
  }

  Future<void> _loadRetention() async {
    final preference = await widget.service.loadRetention();
    if (mounted) setState(() => _retention = preference);
  }

  Future<void> _exportBackup() async {
    final fileName = await _guard(
      () => widget.service.exportBackup(deviceLabel: 'This device'),
    );
    _say(
      fileName == null
          ? 'Backup export cancelled — nothing left this device.'
          : 'Backup written to $fileName',
    );
  }

  Future<void> _importBackup() async {
    setState(() => _busy = true);
    final String? raw;
    try {
      raw = await widget.service.pickAndValidateBackup();
    } on BackupFormatException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _status =
              'Import failed: ${e.reason} Your current data is '
              'unchanged.';
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (raw == null) {
      _say('Import cancelled — no file was selected.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace all local data?'),
        content: const Text(
          'The selected backup replaces everything currently on this '
          'device: pets, routines, schedules, history, and settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('import-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Replace data'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      _say('Import cancelled — your current data is unchanged.');
      return;
    }
    final backupText = raw;
    final applied = await _guard(
      () => widget.service.importBackupText(backupText),
    );
    _say(
      applied == null
          ? 'Import failed before changing anything.'
          : 'Import complete — ${applied.pets} pet(s), '
                '${applied.routines} routine(s), '
                '${applied.completions} history event(s) restored.',
    );
  }

  Future<void> _exportCsv() async {
    final now = DateTime.now().toUtc();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.utc(2020),
      lastDate: now.add(const Duration(days: 1)),
      helpText: 'Export completions between…',
    );
    if (range == null) {
      _say('CSV export cancelled.');
      return;
    }
    final from = DateTime.utc(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final to = DateTime.utc(
      range.end.year,
      range.end.month,
      range.end.day,
    ).add(const Duration(days: 1)); // inclusive-of-last-day, exclusive bound
    final fileName = await _guard(
      () => widget.service.exportCsvRange(fromUtc: from, toUtc: to),
    );
    _say(
      fileName == null
          ? 'CSV export cancelled — nothing left this device.'
          : 'History exported to $fileName',
    );
  }

  Future<void> _applyRetention(RetentionPreference preference) async {
    final result = await _guard(
      () => widget.service.applyRetention(preference),
    );
    if (result == null) return;
    setState(() => _retention = preference);
    _say(
      result.prunedCount == 0
          ? 'Retention set: ${preference.label}.'
          : 'Retention set: ${preference.label} — '
                '${result.prunedCount} old event(s) removed.',
    );
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all Tail Tally data?'),
        content: const Text(
          'This permanently removes every pet, routine, schedule, history '
          'event, and setting from this device. It cannot be undone from '
          'inside the app — only a backup file you saved earlier can '
          'restore this data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep my data'),
          ),
          FilledButton(
            key: const Key('delete-all-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      _say('Delete cancelled — nothing was removed.');
      return;
    }
    final result = await _guard(() => widget.service.deleteAllData());
    if (result == null) return;
    _say(
      result.verified
          ? 'All local data deleted and verified empty.'
          : 'Delete reported a problem — open again to check what remains.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Everything in Tail Tally lives on this device. These controls '
            'are the only ways data leaves it, and each one asks you first.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export backup (JSON)'),
            subtitle: const Text(
              'Save a versioned copy of pets, routines, and history.',
            ),
            trailing: _busy
                // Visible + spoken busy cue (was an invisible spacer).
                ? const _BusyIndicator()
                : const Icon(Icons.chevron_right),
            onTap: _busy ? null : _exportBackup,
          ),
          const Divider(),
          ListTile(
            key: const Key('export-csv'),
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Export history (CSV)'),
            subtitle: const Text(
              'Completion history for a date range you choose.',
            ),
            trailing: _busy
                ? const _BusyIndicator()
                : const Icon(Icons.chevron_right),
            onTap: _busy ? null : _exportCsv,
          ),
          const Divider(),
          ListTile(
            key: const Key('import-backup'),
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Restore from backup'),
            subtitle: const Text(
              'Replaces local data after a compatibility check.',
            ),
            trailing: _busy
                ? const _BusyIndicator()
                : const Icon(Icons.chevron_right),
            onTap: _busy ? null : _importBackup,
          ),
          const Divider(),
          ListTile(
            title: const Text('History retention'),
            subtitle: Text(_retention.label),
            trailing: DropdownButton<RetentionPreference>(
              key: const Key('retention-preference'),
              value: _retention,
              onChanged: _busy
                  ? null
                  : (preference) {
                      if (preference != null) _applyRetention(preference);
                    },
              items: [
                for (final p in RetentionPreference.values)
                  DropdownMenuItem(value: p, child: Text(p.label)),
              ],
            ),
          ),
          const Divider(),
          TextButton.icon(
            key: const Key('delete-all-data'),
            onPressed: _busy ? null : _deleteAll,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Delete all data on this device'),
          ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              // Live region so import/export/retention outcomes are spoken
              // aloud the moment they change.
              child: Semantics(
                liveRegion: true,
                label: _status!,
                child: Text(
                  _status!,
                  key: const Key('privacy-status'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Backups and CSV files are written where you choose them and '
            'are yours to store however you like. Tail Tally has no '
            'servers: no account, no sync, no telemetry.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
