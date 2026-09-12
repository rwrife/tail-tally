import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/domain/csv_export.dart';
import 'package:tail_tally/domain/entities.dart';

void main() {
  group('csvField quoting', () {
    test('plain values pass through', () {
      expect(csvField('Biscuit'), 'Biscuit');
      expect(csvField(''), '');
    });

    test('commas, quotes, and newlines are quoted/escaped', () {
      expect(csvField('a,b'), '"a,b"');
      expect(csvField('say "hi"'), '"say ""hi"""');
      expect(csvField('line1\nline2'), '"line1\nline2"');
    });
  });

  group('encodeCsv', () {
    test('header plus one row per event with UTC ISO timestamps', () {
      final rows = [
        CsvExportRow(
          completedAtUtc: DateTime.utc(2026, 9, 11, 12, 15, 30),
          routineId: 1,
          petName: 'Biscuit',
          routineName: 'Morning walk',
          kind: CompletionKind.done,
          completedByName: 'Alex',
          note: 'long, wet route',
        ),
      ];
      final csv = encodeCsv(rows);
      final lines = csv.trimRight().split('\n');
      expect(lines.first, csvHeader);
      expect(lines.length, 2);
      expect(
        lines[1],
        '2026-09-11T12:15:30.000Z,Biscuit,Morning walk,done,Alex,1,'
        '"long, wet route"',
      );
    });

    test('empty history still emits the header', () {
      expect(encodeCsv(const []), '$csvHeader\n');
    });
  });

  group('buildCsvRows name resolution', () {
    test('resolves pet, routine, and member names', () {
      const routine = Routine(id: 1, petId: 7, name: 'Feed');
      final events = [
        CompletionEvent(
          id: 1,
          routineId: 1,
          completedAtUtc: DateTime.utc(2026, 9, 1),
          kind: CompletionKind.skipped,
          completedByMemberId: 3,
        ),
      ];
      final rows = buildCsvRows(
        events: events,
        routineById: const {1: routine},
        petNameById: const {7: 'Miso'},
        memberNameById: const {3: 'Blair'},
      );
      expect(rows.single.petName, 'Miso');
      expect(rows.single.routineName, 'Feed');
      expect(rows.single.completedByName, 'Blair');
      expect(rows.single.kind, CompletionKind.skipped);
    });

    test('missing routine falls back to id labels instead of dropping', () {
      final events = [
        CompletionEvent(
          id: 1,
          routineId: 99,
          completedAtUtc: DateTime.utc(2026, 9, 1),
          kind: CompletionKind.done,
        ),
      ];
      final rows = buildCsvRows(
        events: events,
        routineById: const {},
        petNameById: const {},
        memberNameById: const {},
      );
      expect(rows.single.petName, '#99');
      expect(rows.single.routineName, '#99');
      expect(rows.single.completedByName, isNull);
    });
  });

  group('file names', () {
    test('csv filename carries UTC date range', () {
      expect(
        csvFileName(DateTime.utc(2026, 9, 1), DateTime.utc(2026, 9, 8)),
        'tail-tally-history-20260901-to-20260908.csv',
      );
    });

    test('csv filename normalizes non-UTC instants', () {
      final name = csvFileName(
        DateTime.utc(2026, 9, 1, 23).toLocal(),
        DateTime.utc(2026, 9, 2).toLocal(),
      );
      expect(name, startsWith('tail-tally-history-2026090'));
    });

    test('backup filename is timestamped to the second', () {
      expect(
        backupFileName(DateTime.utc(2026, 9, 12, 7, 3, 9)),
        'tail-tally-backup-20260912-070309.json',
      );
    });
  });
}
