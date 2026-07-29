import 'package:flutter_test/flutter_test.dart';

import 'package:decide_for_us/app.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const DecideApp());
    expect(find.text('DECIDE FOR US'), findsOneWidget);
    expect(find.text('Your next good story\nstarts here.'), findsOneWidget);
  });
}
