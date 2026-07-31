import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:decide_for_us/app.dart';
import 'package:decide_for_us/screens/trip_planner_screen.dart';
import 'package:decide_for_us/theme/app_theme.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const DecideApp());
    expect(find.text('DECIDE FOR US'), findsOneWidget);
    expect(find.text('Your next good story\nstarts here.'), findsOneWidget);
    expect(find.text('Trip Planner+'), findsOneWidget);
  });

  testWidgets('Trip Planner presents the core setup inputs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const TripPlannerScreen(),
      ),
    );

    expect(find.text('TRIP PLANNER+'), findsOneWidget);
    expect(find.text('Starting point'), findsOneWidget);
    expect(find.text('Destination'), findsOneWidget);
    expect(find.text('Travelers'), findsOneWidget);
    expect(find.text('Total trip budget'), findsOneWidget);
    expect(find.text('REVIEW MY TRIP'), findsOneWidget);
  });
}
