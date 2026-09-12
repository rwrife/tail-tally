import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/domain/entities.dart';
import 'package:tail_tally/domain/retention.dart';

void main() {
  CompletionEvent eventAt(DateTime utc) => CompletionEvent(
    id: utc.millisecondsSinceEpoch,
    routineId: 1,
    completedAtUtc: utc,
    kind: CompletionKind.done,
  );

  group('selectPrunable', () {
    final now = DateTime.utc(2026, 9, 12, 12);

    test('keepAll never prunes', () {
      final events = [eventAt(DateTime.utc(2000))];
      expect(
        selectPrunable(
          events: events,
          preference: RetentionPreference.keepAll,
          now: now,
        ),
        isEmpty,
      );
    });

    test('90-day window keeps recent and drops older', () {
      final recent = eventAt(now.subtract(const Duration(days: 10)));
      final old = eventAt(now.subtract(const Duration(days: 120)));
      final prunable = selectPrunable(
        events: [recent, old],
        preference: RetentionPreference.keep90Days,
        now: now,
      );
      expect(prunable, [old]);
    });

    test('boundary: exactly at cutoff is kept (isBefore is strict)', () {
      final atCutoff = eventAt(now.subtract(const Duration(days: 90)));
      final justOlder = eventAt(
        now.subtract(const Duration(days: 90, minutes: 1)),
      );
      final prunable = selectPrunable(
        events: [atCutoff, justOlder],
        preference: RetentionPreference.keep90Days,
        now: now,
      );
      expect(prunable, [justOlder]);
    });

    test('180 and 365 windows differ as expected', () {
      final e120 = eventAt(now.subtract(const Duration(days: 120)));
      final e200 = eventAt(now.subtract(const Duration(days: 200)));
      final e400 = eventAt(now.subtract(const Duration(days: 400)));
      final events = [e120, e200, e400];
      expect(
        selectPrunable(
          events: events,
          preference: RetentionPreference.keep180Days,
          now: now,
        ).map((e) => e.id),
        {e200.id, e400.id},
      );
      expect(
        selectPrunable(
          events: events,
          preference: RetentionPreference.keep365Days,
          now: now,
        ).map((e) => e.id),
        {e400.id},
      );
    });
  });

  group('preference blob codec', () {
    test('encode/decode round trip', () {
      for (final p in RetentionPreference.values) {
        expect(decodeRetentionSettings(encodeRetentionSettings(p)), p);
      }
    });

    test('missing or corrupt payloads fall back to keepAll', () {
      expect(decodeRetentionSettings(null), RetentionPreference.keepAll);
      expect(decodeRetentionSettings('not json'), RetentionPreference.keepAll);
      expect(
        decodeRetentionSettings('{"preference":"nonsense"}'),
        RetentionPreference.keepAll,
      );
    });
  });

  group('labels and windows', () {
    test('keepAll has no window, others do', () {
      expect(RetentionPreference.keepAll.window, isNull);
      expect(RetentionPreference.keep90Days.window, const Duration(days: 90));
      expect(RetentionPreference.keepAll.label, 'Keep all history');
    });
  });
}
