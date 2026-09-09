import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'database.dart';

/// Opens the app's on-device database.
///
/// The file lives in the platform-specific application documents directory
/// and never leaves the device unless the user explicitly exports it.
TailTallyDatabase openAppDatabase({String name = 'tail_tally'}) {
  return TailTallyDatabase(driftDatabase(name: name));
}

/// Database opened over an arbitrary executor — used by tests and by any
/// future tooling that needs to point the same schema at another file or
/// at an in-memory store.
TailTallyDatabase openDatabaseWithExecutor(QueryExecutor e) {
  return TailTallyDatabase(e);
}
