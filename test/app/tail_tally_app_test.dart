import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tail_tally/app/tail_tally_app.dart';

void main() {
  testWidgets('startup screen explains the local-first purpose', (
    tester,
  ) async {
    await tester.pumpWidget(const TailTallyApp());

    expect(find.text('Tail Tally'), findsOneWidget);
    expect(
      find.text('Shared pet-care routines, kept on this device.'),
      findsOneWidget,
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
