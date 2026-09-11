/// Platform bridge for local notifications (issue #4).
///
/// Everything that touches the notification plugin or permission system
/// lives here, behind the [NotificationGateway] abstraction so the
/// scheduling service in `lib/domain/` and the UI stay testable without
/// platform channels.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:tail_tally/domain/reminders.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Permission state relevant to reminder scheduling.
enum NotificationPermission { granted, denied, undetermined }

/// Outcome of a [NotificationGateway.requestPermission] call.
class PermissionRequestOutcome {
  const PermissionRequestOutcome(this.permission, {this.canPromptAgain = true});

  final NotificationPermission permission;

  /// False once the OS will no longer show the system prompt (user denied
  /// twice on iOS, "don't ask again" on Android); the UI should route the
  /// user to system settings instead of re-prompting.
  final bool canPromptAgain;
}

/// Contract implemented by [PluginNotificationGateway].
abstract class NotificationGateway {
  Future<void> initialize();
  Future<NotificationPermission> checkPermission();
  Future<PermissionRequestOutcome> requestPermission();
  Future<void> schedule(PlannedReminder reminder);
  Future<void> cancel(int notificationId);
  Future<void> cancelAll();
}

/// In-memory gateway used in tests and as a no-op fallback on unsupported
/// platforms (Linux desktop dev, web previews) so the app keeps running
/// without reminders instead of crashing.
class NoopNotificationGateway implements NotificationGateway {
  final List<PlannedReminder> scheduled = [];
  final List<int> cancelled = [];
  bool allCancelled = false;
  NotificationPermission permission = NotificationPermission.granted;

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationPermission> checkPermission() async => permission;

  @override
  Future<PermissionRequestOutcome> requestPermission() async =>
      PermissionRequestOutcome(permission);

  @override
  Future<void> schedule(PlannedReminder reminder) async =>
      scheduled.add(reminder);

  @override
  Future<void> cancel(int notificationId) async =>
      cancelled.add(notificationId);

  @override
  Future<void> cancelAll() async => allCancelled = true;
}

/// Real gateway backed by flutter_local_notifications.
class PluginNotificationGateway implements NotificationGateway {
  PluginNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _channelId = 'tail_tally_routines';
  static const _channelName = 'Routine reminders';
  static const _channelDescription =
      'Reminders when a pet-care routine window is about to open.';

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(_resolveLocation(info.identifier));
    } catch (_) {
      // Device location lookup failed (unsupported platform or odd
      // identifier): fall back to UTC. Wall-clock times still fire
      // against the device clock on Android/iOS; tests never exercise
      // this path.
      tz.setLocalLocation(tz.UTC);
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  /// Accepts identifier shapes across flutter_timezone versions
  /// (e.g. "America/Los_Angeles" or "UTC"; some Android builds return
  /// an ID with a subtag we have to strip).
  static tz.Location _resolveLocation(String identifier) {
    try {
      return tz.getLocation(identifier);
    } catch (_) {
      final base = identifier.split('/').first;
      try {
        return tz.getLocation(base);
      } catch (_) {
        return tz.UTC;
      }
    }
  }

  @override
  Future<NotificationPermission> checkPermission() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final enabled = await android?.areNotificationsEnabled() ?? false;
        return enabled
            ? NotificationPermission.granted
            : NotificationPermission.denied;
      case TargetPlatform.iOS:
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final status = await ios?.checkPermissions();
        final granted =
            status != null &&
            (status.isEnabled ||
                status.isAlertEnabled ||
                status.isProvisionalEnabled);
        return granted
            ? NotificationPermission.granted
            : NotificationPermission.denied;
      default:
        return NotificationPermission.granted;
    }
  }

  @override
  Future<PermissionRequestOutcome> requestPermission() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted =
            await android?.requestNotificationsPermission() ?? false;
        return PermissionRequestOutcome(
          granted
              ? NotificationPermission.granted
              : NotificationPermission.denied,
        );
      case TargetPlatform.iOS:
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted =
            await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
        return PermissionRequestOutcome(
          granted
              ? NotificationPermission.granted
              : NotificationPermission.denied,
        );
      default:
        return const PermissionRequestOutcome(NotificationPermission.granted);
    }
  }

  @override
  Future<void> schedule(PlannedReminder reminder) async {
    assert(reminder.isSchedulable, 'schedule() called on suppressed reminder');
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      id: reminder.notificationId,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.local),
      notificationDetails: details,
      // Reminders don't need second-exact delivery; inexact + allow-while-idle
      // fires within minutes even in doze, avoids the Play-restricted
      // exact-alarm permission, and keeps the permission surface minimal.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int notificationId) => _plugin.cancel(id: notificationId);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}
