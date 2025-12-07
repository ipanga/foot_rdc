// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:foot_rdc/main_old.dart';
import 'package:foot_rdc/features/presentation/pages/home_page.dart';

void main() {
  testWidgets('MyApp shows HomePage', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    expect(find.byType(HomePage), findsOneWidget);
  });
}
