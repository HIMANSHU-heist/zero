import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:behave_guard_upi/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const BehaveGuardApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
