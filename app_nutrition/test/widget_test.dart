// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_nutrition/main.dart';

void main() {
  testWidgets('App boots to Welcome screen', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());
    // Allow async builders (like SessionGate) to progress without hanging on pumpAndSettle
    // Pump in small increments up to a reasonable timeout
    const maxTicks = 40; // ~4s @ 100ms
    for (int i = 0; i < maxTicks; i++) {
      // Break early if the welcome text is visible
      if (find.text('App Nutrition').evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Expect the welcome title to be visible
    expect(find.text('App Nutrition'), findsOneWidget);
    // And the restaurant icon present
    expect(find.byIcon(Icons.restaurant_menu), findsWidgets);
  });
}
