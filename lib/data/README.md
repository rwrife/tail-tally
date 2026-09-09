# Data boundary

Owns local persistence implementations, Drift tables and migrations, and
backup/export serialization. It implements contracts from `domain`; it does
not own user-interface or operating-system permission behavior.

Tail Tally's core data path is local-only. Any future external integration must
remain optional and must not be required to use the app.

## Timestamp storage contract

- **Completion events** are absolute instants. They are normalized with
  `toUtc()` before insert and stored by Drift as epoch milliseconds, so the
  history timeline is stable across timezone travel and DST shifts.
- **Schedule windows** are device-local wall-clock values (hour/minute pairs
  plus ISO weekday set). They intentionally carry no timezone so a "07:30
  feed" stays 07:30 wherever the device currently is.
- Anything imported or exported that carries an offset must be converted with
  `toUtc()` before it reaches `DriftLocalDataRepository`.

See `lib/domain/entities.dart` for the normative version of this contract.