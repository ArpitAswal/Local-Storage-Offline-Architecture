// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_storage/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  setUp(() async {
    // FLOW: Step 1 - Mock SharedPreferences initial values.
    SharedPreferences.setMockInitialValues({});

    // FLOW: Step 2 - Mock Hive with a temporary system directory.
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
  });

  testWidgets('App loads home screen smoke test', (WidgetTester tester) async {
    // FLOW: Step 3 - Build our app and trigger a frame.
    await tester.pumpWidget(const LocalStorageApp());
    await tester.pumpAndSettle();

    // FLOW: Step 4 - Verify that our home screen loads successfully.
    expect(find.text('Local Storage Lab'), findsOneWidget);
    expect(find.text('Part 1: Key-Value & NoSQL Storage'), findsOneWidget);
  });
}
