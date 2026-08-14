import 'package:decide_for_us/services/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tester build flag controls the Premium override', () {
    const testerBuild = bool.fromEnvironment(
      'TESTER_PREMIUM_ACCESS',
      defaultValue: false,
    );

    expect(SubscriptionService.testerPremiumAccess, testerBuild);
    expect(SubscriptionService.isSubscribed, testerBuild);
  });
}
