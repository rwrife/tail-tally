import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/app/tail_tally_app.dart';
import 'package:tail_tally/data/database.dart';
import 'package:tail_tally/data/drift_repository.dart';

void main() {
  testWidgets('empty database shows the local-first welcome pane', (
    tester,
  ) async {
    final db = TailTallyDatabase(NativeDatabase.memory());
    final repo = DriftLocalDataRepository(db, clock: DateTime.now);
    await repo.ensureOpen();
    addTearDown(db.close);

    await tester.pumpWidget(TailTallyApp(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Tail Tally'), findsNothing); // app bar now says 'Today'
    expect(find.text('Today'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(
      find.textContaining('Shared pet-care routines, kept on this device.'),
      findsOneWidget,
    );
    expect(find.textContaining('Add your first pet'), findsOneWidget);
  });
}
