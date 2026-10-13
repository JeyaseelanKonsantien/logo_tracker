import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logo_tracker/main.dart';

void main() {
  testWidgets('App workflow smoke test - Splash to Home navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const LogoTrackerApp());

    expect(find.byType(Image), findsOneWidget);

    await tester.pumpAndSettle(const Duration(milliseconds: 2500));

    expect(find.text('Start Tracking'), findsOneWidget);
    expect(find.text('Advanced Settings'), findsOneWidget);

    expect(find.text('0'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
  });
}
