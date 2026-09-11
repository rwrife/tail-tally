import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../data/database_connection.dart';
import '../data/drift_repository.dart';
import '../domain/entities.dart';
import '../domain/schedule.dart';
import '../domain/task_workflow.dart';
import '../domain/timeline.dart';
import '../platform/notifications.dart';
import 'reminder_service.dart';
import 'reminder_settings_screen.dart';

/// Root widget for Tail Tally's local-first mobile experience.
class TailTallyApp extends StatefulWidget {
  const TailTallyApp({super.key, this.repository, this.notificationGateway});

  /// Injected for tests and future tooling; production opens the on-device
  /// database lazily at this composition root.
  final DriftLocalDataRepository? repository;

  /// Injected in tests; production uses the real plugin gateway and falls
  /// back to a no-op gateway when the platform has no notification support.
  final NotificationGateway? notificationGateway;

  @override
  State<TailTallyApp> createState() => _TailTallyAppState();
}

class _TailTallyAppState extends State<TailTallyApp> {
  DriftLocalDataRepository? _repo;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository;
    _repo?.ensureOpen();
  }

  @override
  Widget build(BuildContext context) {
    final repo = _repo ??= DriftLocalDataRepository(openAppDatabase())
      ..ensureOpen();
    final gateway =
        widget.notificationGateway ??
        (Platform.isAndroid || Platform.isIOS
            ? PluginNotificationGateway()
            : NoopNotificationGateway());
    return MaterialApp(
      title: 'Tail Tally',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff41644a)),
        useMaterial3: true,
      ),
      home: TimelineHome(repository: repo, notificationGateway: gateway),
    );
  }
}

/// The primary daily workflow screen: today's routine windows grouped by
/// status, one-tap completion with an optional note, bounded undo, and the
/// shared-handoff marker on completed tasks.
class TimelineHome extends StatefulWidget {
  const TimelineHome({
    super.key,
    required this.repository,
    this.notificationGateway,
  });

  final LocalDataRepository repository;

  /// When provided, completions resync reminders and the app bar gains a
  /// reminders/settings entry.
  final NotificationGateway? notificationGateway;

  @override
  State<TimelineHome> createState() => _TimelineHomeState();
}

class _TimelineHomeState extends State<TimelineHome> {
  late final DailyTimelineBuilder _builder = DailyTimelineBuilder(
    widget.repository,
  );
  late final TaskWorkflow _workflow = TaskWorkflow(widget.repository);
  ReminderService? _reminderService;
  final UndoLedger _undoLedger = UndoLedger();

  Set<int>? _selectedPetIds; // null = all pets
  List<Pet> _pets = const [];
  Map<TimelineGroup, List<TimelineEntry>> _groups = const {};
  String? _error;

  @override
  void initState() {
    super.initState();
    final gateway = widget.notificationGateway;
    if (gateway != null) {
      _reminderService = ReminderService(
        repo: widget.repository,
        gateway: gateway,
      );
      gateway.initialize().then((_) => _syncReminders());
    }
    _refresh();
  }

  Future<void> _syncReminders() async {
    try {
      await _reminderService?.resync();
    } catch (_) {
      // Reminder failures must never break the timeline workflow.
    }
  }

  Future<void> _refresh() async {
    try {
      final pets = await widget.repository.listPets();
      final groups = await _builder.buildGrouped(petIds: _selectedPetIds);
      if (!mounted) return;
      setState(() {
        _pets = pets;
        _groups = groups;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load today’s routines: $e');
    }
  }

  Future<void> _complete(TimelineEntry entry) async {
    final controller = TextEditingController();
    final result = await showDialog<_NoteDialogResult>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark “${entry.routine.name}” done?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: 'Optional note (treat used, who helped…)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const _NoteDialogResult.cancelled()),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('note-save'),
            onPressed: () => Navigator.pop(
              context,
              _NoteDialogResult.saved(controller.text.trim()),
            ),
            child: const Text('Mark done'),
          ),
        ],
      ),
    );
    // Dialog dismissed without choosing (back button, tap outside) is a
    // cancel: never record a completion the user did not confirm.
    if (result == null || result.cancelled || !mounted) return;

    final members = await widget.repository.listMembers();
    final localOwner = members.where((m) => m.isLocalDeviceOwner).firstOrNull;
    final outcome = await _workflow.complete(
      entry.instance,
      note: (result.note == null || result.note!.isEmpty) ? null : result.note,
      memberId: localOwner?.id,
    );
    if (!mounted) return;
    switch (outcome) {
      case Completed(:final event):
        _undoLedger.record(event.id);
        await _refresh();
        await _syncReminders();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.routine.name} marked done'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                if (!_undoLedger.canUndo(event.id)) return;
                await _workflow.undo(event.id);
                _undoLedger.forget(event.id);
                await _refresh();
                await _syncReminders();
              },
            ),
          ),
        );
      case AlreadyCompleted():
        await _refresh();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Already logged for this window — no duplicate added',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _selectedPetIds == null
        ? 'Today'
        : _pets
              .where((p) => _selectedPetIds!.contains(p.id))
              .map((p) => p.name)
              .join(', ');
    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? 'Today' : title),
        actions: [
          if (_reminderService != null)
            IconButton(
              key: const Key('open-reminder-settings'),
              tooltip: 'Reminder settings',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ReminderSettingsScreen(service: _reminderService!),
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!),
                ),
              )
            : _pets.isEmpty
            ? const _WelcomePane()
            : RefreshIndicator(
                onRefresh: _refresh,
                child: Column(
                  children: [
                    _PetFilterBar(
                      pets: _pets,
                      selectedPetIds: _selectedPetIds,
                      onChanged: (ids) => setState(() {
                        _selectedPetIds = ids;
                        _refresh();
                      }),
                    ),
                    Expanded(child: _buildTimelineList()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTimelineList() {
    final visibleGroups = TimelineGroup.displayOrder
        .where((g) => (_groups[g] ?? const []).isNotEmpty)
        .toList();
    if (visibleGroups.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 48),
          Center(
            child: Text(
              'Nothing scheduled for these pets today.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    final children = <Widget>[];
    for (final group in visibleGroups) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            groupLabel(group),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      );
      for (final entry in _groups[group]!) {
        children.add(
          _TimelineCard(entry: entry, onComplete: () => _complete(entry)),
        );
      }
    }
    return ListView(children: children);
  }
}

String groupLabel(TimelineGroup group) => switch (group) {
  TimelineGroup.overdue => 'Overdue',
  TimelineGroup.due => 'Due now',
  TimelineGroup.scheduled => 'Coming up',
  TimelineGroup.completed => 'Done today',
};

class _NoteDialogResult {
  const _NoteDialogResult.saved(this.note) : cancelled = false;
  const _NoteDialogResult.cancelled() : note = null, cancelled = true;
  final String? note;
  final bool cancelled;
}

class _PetFilterBar extends StatelessWidget {
  const _PetFilterBar({
    required this.pets,
    required this.selectedPetIds,
    required this.onChanged,
  });

  final List<Pet> pets;
  final Set<int>? selectedPetIds;
  final ValueChanged<Set<int>?> onChanged;

  @override
  Widget build(BuildContext context) {
    final all = selectedPetIds == null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All pets'),
            selected: all,
            onSelected: (_) => onChanged(null),
          ),
          for (final pet in pets)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                label: Text('${pet.name} (${pet.species})'),
                selected: !all && selectedPetIds!.contains(pet.id),
                onSelected: (selected) {
                  final current = {...?selectedPetIds};
                  if (selected) {
                    current.add(pet.id);
                    onChanged(current);
                  } else if (current.length == 1) {
                    onChanged(null); // never allow empty selection
                  } else {
                    current.remove(pet.id);
                    onChanged(current);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.entry, required this.onComplete});

  final TimelineEntry entry;
  final VoidCallback onComplete;

  String get _timeLabel {
    String fmt(DateTime d) =>
        '${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
    final cross = entry.instance.endDay.isAfter(entry.instance.startDay)
        ? ' +1'
        : '';
    return '${fmt(entry.instance.start)}–${fmt(entry.instance.end)}$cross';
  }

  @override
  Widget build(BuildContext context) {
    final completed = entry.status == TaskStatus.completed;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text('${entry.pet.name} — ${entry.routine.name}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_timeLabel),
            if (completed)
              Text(
                entry.completedByName == null
                    ? 'Done${entry.completion?.note != null ? ' • ${entry.completion!.note}' : ''}'
                    : 'Done by ${entry.completedByName}${entry.completion?.note != null ? ' • ${entry.completion!.note}' : ''}',
                key: Key('handoff-${entry.completion?.id}'),
              ),
          ],
        ),
        trailing: completed
            ? const Icon(Icons.check_circle, color: Colors.green)
            : FilledButton.icon(
                key: Key(
                  'complete-${entry.instance.window.id}-${entry.instance.start.millisecondsSinceEpoch}',
                ),
                onPressed: onComplete,
                icon: const Icon(Icons.check),
                label: const Text('Done'),
              ),
      ),
    );
  }
}

class _WelcomePane extends StatelessWidget {
  const _WelcomePane();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Shared pet-care routines, kept on this device.\n\n'
          'Add your first pet to start a timeline.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
