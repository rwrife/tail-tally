/// Completion-history retention preferences (issue #5).
///
/// Retention policy is *local wall-clock-free*: the cutoff is computed
/// against UTC instants because completion events are UTC (see the
/// timestamp contract in `lib/domain/entities.dart`). Pure Dart — the UI
/// and services layer decide when to apply it.
library;

import 'dart:convert';

import 'entities.dart';

enum RetentionPreference {
  /// Keep every completion event forever (default).
  keepAll,

  /// Prune events older than 365 days.
  keep365Days,

  /// Prune events older than 180 days.
  keep180Days,

  /// Prune events older than 90 days.
  keep90Days,
}

extension RetentionPreferenceLabel on RetentionPreference {
  String get label => switch (this) {
    RetentionPreference.keepAll => 'Keep all history',
    RetentionPreference.keep365Days => 'Keep the last year',
    RetentionPreference.keep180Days => 'Keep the last 6 months',
    RetentionPreference.keep90Days => 'Keep the last 3 months',
  };

  /// Null for [RetentionPreference.keepAll].
  Duration? get window => switch (this) {
    RetentionPreference.keepAll => null,
    RetentionPreference.keep365Days => const Duration(days: 365),
    RetentionPreference.keep180Days => const Duration(days: 180),
    RetentionPreference.keep90Days => const Duration(days: 90),
  };
}

/// Events strictly older than [now] minus the preference window.
/// `keepAll` prunes nothing.
List<CompletionEvent> selectPrunable({
  required List<CompletionEvent> events,
  required RetentionPreference preference,
  required DateTime now,
}) {
  final window = preference.window;
  if (window == null) return const [];
  final cutoff = now.toUtc().subtract(window);
  return events
      .where((e) => e.completedAtUtc.toUtc().isBefore(cutoff))
      .toList();
}

/// Result of a retention prune pass, for UI feedback.
class RetentionPruneResult {
  const RetentionPruneResult({
    required this.preference,
    required this.prunedCount,
    this.cutoffUtc,
  });

  final RetentionPreference preference;
  final int prunedCount;
  final DateTime? cutoffUtc;
}

/// Versioned JSON blob for the retention singleton table.
String encodeRetentionSettings(RetentionPreference preference) =>
    jsonEncode({'schemaVersion': 1, 'preference': preference.name});

/// Tolerant decode: unknown or missing payloads fall back to keepAll.
RetentionPreference decodeRetentionSettings(String? raw) {
  if (raw == null) return RetentionPreference.keepAll;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      return RetentionPreference.keepAll;
    }
    final name = decoded['preference'];
    return RetentionPreference.values.firstWhere(
      (p) => p.name == name,
      orElse: () => RetentionPreference.keepAll,
    );
  } on FormatException {
    return RetentionPreference.keepAll;
  }
}
