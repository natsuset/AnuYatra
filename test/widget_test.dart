// Basic Flutter widget test for Anuyātrā App
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:testing_flutter/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AnuyatraApp());

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
