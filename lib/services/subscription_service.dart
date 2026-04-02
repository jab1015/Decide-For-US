import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  /// 🔥 DEBUG SWITCH (TURN THIS OFF FOR TESTING PAYWALL)
  static const bool debugForceSubscribed = false;

  static bool _isSubscribed = false;

  static bool get isSubscribed {
    /// 🔥 If debug is ON, always subscribed
    if (debugForceSubscribed) return true;

    return _isSubscribed;
  }

  /// 🔥 INIT — called when app starts
  static Future<void> init() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await Purchases.logIn(user.uid);
    }

    try {
      final info = await Purchases.getCustomerInfo();

      _isSubscribed =
          info.entitlements.active.containsKey('premium');

      print("SUB STATUS (INIT): $_isSubscribed");
    } catch (e) {
      print("Subscription init error: $e");
      _isSubscribed = false;
    }
  }

  /// 🔥 CALL AFTER PURCHASE OR RESTORE
  static void updateStatus(CustomerInfo info) {
    _isSubscribed =
        info.entitlements.active.containsKey('premium');

    print("SUB STATUS (UPDATE): $_isSubscribed");
  }
}