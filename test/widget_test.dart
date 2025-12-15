
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:diacare/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    // For testing, we need to initialize Hive in a temporary directory
    // so we don't interfere with the real app data.
    final tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);

    // Open the boxes that the app uses.
    await Hive.openBox('userProfile');
    await Hive.openBox('glucose');
    await Hive.openBox('medications');
    await Hive.openBox('meals');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('HomeScreen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app bar title is correct.
    expect(find.text('DiaCare'), findsOneWidget);

    // Verify that the initial text is shown.
    expect(find.text('Latest readings'), findsOneWidget);
    expect(find.text('No readings yet.'), findsOneWidget);

    // Verify the floating action buttons are present.
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.alarm), findsOneWidget);
  });
}
