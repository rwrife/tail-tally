/// Reminder settings UI (issue #4): master switch, lead time, quiet hours,
/// and the just-in-time permission flow with a clear fallback when the OS
/// permission is denied.
library;

import 'package:flutter/material.dart';

import '../domain/reminders.dart';
import '../platform/notifications.dart';
import 'reminder_service.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key, required this.service});

  final ReminderService service;

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  late ReminderSettings _settings = const ReminderSettings();
  NotificationPermission _permission = NotificationPermission.undetermined;
  bool _canPromptAgain = true;
  bool _loaded = false;
  bool _busy = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await widget.service.loadSettings();
    final permission = await widget.service.gateway.checkPermission();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _permission = permission;
      _loaded = true;
    });
  }

  Future<void> _save(ReminderSettings next, {String? message}) async {
    setState(() => _busy = true);
    await widget.service.saveSettings(next);
    final outcome = await widget.service.resync();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _settings = next;
      _permission = outcome.permission;
      _statusMessage =
          message ??
          switch (outcome.permission) {
            NotificationPermission.granted when next.notificationsEnabled =>
              outcome.suppressedCount > 0
                  ? '${outcome.scheduledCount} reminder(s) scheduled; '
                        '${outcome.suppressedCount} suppressed by quiet hours.'
                  : '${outcome.scheduledCount} reminder(s) scheduled.',
            NotificationPermission.granted => 'Reminders are off.',
            _ => 'Reminders are off — notifications are not allowed.',
          };
    });
  }

  Future<void> _enableWithPermission() async {
    setState(() => _busy = true);
    final outcome = await widget.service.requestPermissionsAndSync();
    if (!mounted) return;
    if (outcome.permission == NotificationPermission.granted) {
      final next = ReminderSettings(
        notificationsEnabled: true,
        leadTime: _settings.leadTime,
        quietHours: _settings.quietHours,
      );
      await _save(
        next,
        message:
            'Reminders on — ${outcome.scheduledCount} scheduled in the '
            'next week.',
      );
      return;
    }
    setState(() {
      _busy = false;
      _permission = outcome.permission;
      _canPromptAgain = outcome.canPromptAgain;
      _statusMessage =
          'Notifications are not allowed, so reminders stay off. '
          'Your timeline and history keep working exactly the same — '
          'open system settings to allow notifications any time.';
    });
  }

  Future<void> _pickQuietHours({required bool isStart}) async {
    final current = isStart
        ? TimeOfDay(
            hour: _settings.quietHours.startMinutes ~/ 60,
            minute: _settings.quietHours.startMinutes % 60,
          )
        : TimeOfDay(
            hour: _settings.quietHours.endMinutes ~/ 60,
            minute: _settings.quietHours.endMinutes % 60,
          );
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: isStart ? 'Quiet hours start' : 'Quiet hours end',
    );
    if (picked == null || !mounted) return;
    final next = QuietWindow(
      startMinutes: isStart
          ? picked.hour * 60 + picked.minute
          : _settings.quietHours.startMinutes,
      endMinutes: isStart
          ? _settings.quietHours.endMinutes
          : picked.hour * 60 + picked.minute,
    );
    await _save(
      ReminderSettings(
        notificationsEnabled: _settings.notificationsEnabled,
        leadTime: _settings.leadTime,
        quietHours: next,
      ),
    );
  }

  String _fmtMinutes(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  key: const Key('reminders-enabled'),
                  title: const Text('Routine reminders'),
                  subtitle: const Text(
                    'Notify me shortly before a routine window opens.',
                  ),
                  value: _settings.notificationsEnabled,
                  onChanged: _busy
                      ? null
                      : (enabled) {
                          if (enabled &&
                              _permission != NotificationPermission.granted) {
                            // Just-in-time prompt instead of flipping the
                            // switch on for a permission we do not have.
                            _enableWithPermission();
                          } else {
                            _save(
                              ReminderSettings(
                                notificationsEnabled: enabled,
                                leadTime: _settings.leadTime,
                                quietHours: _settings.quietHours,
                              ),
                            );
                          }
                        },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Remind me'),
                  trailing: DropdownButton<ReminderLeadTime>(
                    key: const Key('lead-time'),
                    value: _settings.leadTime,
                    items: [
                      for (final v in ReminderLeadTime.values)
                        DropdownMenuItem(value: v, child: Text(v.label)),
                    ],
                    onChanged: _busy
                        ? null
                        : (lead) {
                            if (lead == null) return;
                            _save(
                              ReminderSettings(
                                notificationsEnabled:
                                    _settings.notificationsEnabled,
                                leadTime: lead,
                                quietHours: _settings.quietHours,
                              ),
                            );
                          },
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Quiet hours start'),
                  subtitle: Text(
                    _settings.quietHours.isDisabled
                        ? 'Off'
                        : _fmtMinutes(_settings.quietHours.startMinutes),
                  ),
                  onTap: _busy ? null : () => _pickQuietHours(isStart: true),
                ),
                ListTile(
                  title: const Text('Quiet hours end'),
                  subtitle: Text(
                    _settings.quietHours.isDisabled
                        ? 'Off'
                        : _fmtMinutes(_settings.quietHours.endMinutes),
                  ),
                  onTap: _busy ? null : () => _pickQuietHours(isStart: false),
                ),
                TextButton.icon(
                  key: const Key('quiet-hours-off'),
                  onPressed: _busy
                      ? null
                      : () => _save(
                          ReminderSettings(
                            notificationsEnabled:
                                _settings.notificationsEnabled,
                            leadTime: _settings.leadTime,
                            quietHours: QuietWindow.disabled,
                          ),
                          message: 'Quiet hours off.',
                        ),
                  icon: const Icon(Icons.clear),
                  label: const Text('Turn quiet hours off'),
                ),
                const Divider(),
                if (_permission != NotificationPermission.granted)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        key: const Key('permission-fallback'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.notifications_off_outlined),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Notification permission not granted',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _canPromptAgain
                                ? 'Tail Tally only asks for notifications when you turn reminders on, and reminders are never required to use the app.'
                                : 'The system will not ask again. Change this in system settings.',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton.icon(
                                key: const Key('request-permission'),
                                onPressed: _busy || !_canPromptAgain
                                    ? null
                                    : _enableWithPermission,
                                icon: const Icon(Icons.notifications),
                                label: const Text('Allow notifications'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => widget.service
                                          .saveSettings(
                                            ReminderSettings(
                                              notificationsEnabled: false,
                                              leadTime: _settings.leadTime,
                                              quietHours: _settings.quietHours,
                                            ),
                                          )
                                          .then((_) async {
                                            final done = await widget
                                                .service
                                                .gateway
                                                .checkPermission();
                                            if (!mounted) return;
                                            setState(() {
                                              _settings = ReminderSettings(
                                                notificationsEnabled: false,
                                                leadTime: _settings.leadTime,
                                                quietHours:
                                                    _settings.quietHours,
                                              );
                                              _permission = done;
                                              _statusMessage =
                                                  'Reminders stay off.';
                                            });
                                          }),
                                icon: const Icon(Icons.close),
                                label: const Text('Keep reminders off'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _statusMessage!,
                      key: const Key('reminder-status'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Reminders are generated on this device from your routine '
                  'windows. No account, no server: if you never turn them '
                  'on, Tail Tally never asks.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
    );
  }
}
