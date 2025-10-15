// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finsage/main.dart'; // Adjust the path if your main.dart is elsewhere

void main() {
  testWidgets('App renders correctly on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Because the app starts with a StreamBuilder checking auth state,
    // the initial widget is HomePage, which has the title "FinSage".
    // We can verify that this text is present.
    expect(find.text('FinSage'), findsOneWidget);
  });
}
