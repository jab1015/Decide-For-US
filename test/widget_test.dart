import 'package:flutter_test/flutter_test.dart';

import 'package:decide_for_us/app.dart';
import 'package:decide_for_us/services/forced_update_service.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      DecideApp(
        forcedUpdateCheck: () async => const ForcedUpdateResult(
          isRequired: false,
          currentVersion: '1.0.28',
          minimumVersion: '1.0.28',
          storeUrl: '',
          message: '',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('DECIDE FOR US'), findsOneWidget);
    expect(find.text('Your next good story\nstarts here.'), findsOneWidget);
  });
}
