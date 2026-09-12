/// CSV export of the completion history (issue #5).
///
/// Pure string formatting over already-fetched [CompletionEvent]s so the
/// export is testable without databases or file IO. Resolved pet/routine/
/// member names are passed in by the caller; ids are always emitted so a
/// downstream spreadsheet consumer can join even with unnamed rows.
library;

import 'entities.dart';

class CsvExportRow {
  const CsvExportRow({
    required this.completedAtUtc,
    required this.routineId,
    required this.petName,
    required this.routineName,
    required this.kind,
    this.completedByName,
    this.note,
  });

  final DateTime completedAtUtc;
  final int routineId;
  final String petName;
  final String routineName;
  final CompletionKind kind;
  final String? completedByName;
  final String? note;
}

/// Column order (also the first line of [encodeCsv]).
const csvHeader =
    'completed_at_utc,pet,routine,kind,completed_by,routine_id,note';

/// Build export rows from raw events, resolving names via [routineById].
/// Routines missing from the map fall back to `#<id>` labels rather than
/// dropping history.
List<CsvExportRow> buildCsvRows({
  required List<CompletionEvent> events,
  required Map<int, Routine> routineById,
  required Map<int, String> petNameById,
  required Map<int, String> memberNameById,
}) {
  return [
    for (final event in events)
      () {
        final routine = routineById[event.routineId];
        final petName = routine == null
            ? '#${event.routineId}'
            : (petNameById[routine.petId] ?? '#${routine.petId}');
        return CsvExportRow(
          completedAtUtc: event.completedAtUtc,
          routineId: event.routineId,
          petName: petName,
          routineName: routine?.name ?? '#${event.routineId}',
          kind: event.kind,
          completedByName: event.completedByMemberId == null
              ? null
              : memberNameById[event.completedByMemberId],
          note: event.note,
        );
      }(),
  ];
}

/// RFC 4180 field quoting: quote when the value contains a comma, quote,
/// CR, or LF; embedded quotes double up.
String csvField(String value) {
  if (value.contains(RegExp('[",\r\n]'))) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// Encode rows as a CSV document ending with a trailing newline.
/// `completed_at_utc` is ISO-8601 with explicit UTC offset so consumers
/// never guess the timezone (timestamp contract, entities.dart).
String encodeCsv(List<CsvExportRow> rows) {
  final buffer = StringBuffer('$csvHeader\n');
  for (final row in rows) {
    buffer.writeln(
      [
        row.completedAtUtc.toUtc().toIso8601String(),
        csvField(row.petName),
        csvField(row.routineName),
        row.kind.name,
        csvField(row.completedByName ?? ''),
        row.routineId.toString(),
        csvField(row.note ?? ''),
      ].join(','),
    );
  }
  return buffer.toString();
}

/// Filename for an export covering [fromUtc]..[toUtc), e.g.
/// `tail-tally-history-20260901-to-20260908.csv` (dates are UTC).
String csvFileName(DateTime fromUtc, DateTime toUtc) {
  String fmt(DateTime d) {
    final u = d.toUtc();
    return '${u.year.toString().padLeft(4, "0")}'
        '${u.month.toString().padLeft(2, "0")}'
        '${u.day.toString().padLeft(2, "0")}';
  }

  return 'tail-tally-history-${fmt(fromUtc)}-to-${fmt(toUtc)}.csv';
}

/// Filename for a JSON backup created at [createdAtUtc].
String backupFileName(DateTime createdAtUtc) {
  final u = createdAtUtc.toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  return 'tail-tally-backup-${u.year}${two(u.month)}${two(u.day)}-'
      '${two(u.hour)}${two(u.minute)}${two(u.second)}.json';
}
