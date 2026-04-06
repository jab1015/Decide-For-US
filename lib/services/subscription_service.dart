import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  /// 🔥 ENABLE TEST MODE
  static const bool debugForceSubscribed = true;

  static bool _isSubscribed = false;

  static bool get isSubscribed {
    if (debugForceSubscribed) return true;
    return _isSubscribed;
  }

  static Future<void> init() async {
    try {
      String apiKey;

      if (Platform.isIOS) {
        apiKey = "appl_PUSUzSUTwTnqCKYmRlKutkZUeLv";
      } else {
        apiKey = "goog_lnWIfTDSTBOqFJIxpYcUjFRWRql";
      }

      await Purchases.configure(PurchasesConfiguration(apiKey));

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await Purchases.logIn(user.uid);
      }

      final info = await Purchases.getCustomerInfo();
      _isSubscribed =
          info.entitlements.active.containsKey('premium');
    } catch (e) {
      _isSubscribed = false;
    }
  }

  static void updateStatus(CustomerInfo info) {
    _isSubscribed =
        info.entitlements.active.containsKey('premium');
  }
}