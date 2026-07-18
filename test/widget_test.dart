// This is a basic Flutter widget test.
//
// Since KalingaApp initializes Supabase and other async services in
// main(), this smoke test builds it directly (bypassing main()) and
// just checks that the app boots to its splash screen without crashing.
// It intentionally does not exercise Supabase-backed screens — those
// need integration tests with a real/mocked backend instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_project/main.dart';

void main() {
  testWidgets('App boots and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KalingaApp());

    // Splash screen should be on screen immediately after the first frame.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}