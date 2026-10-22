import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrz_scanner/main.dart';

void main() {
  testWidgets('home screen renders the scan CTA', (tester) async {
    await tester.pumpWidget(const MrzScannerApp());
    await tester.pump();

    expect(find.text('MRZ Scanner'), findsWidgets);
    expect(find.text('Scan Document'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
