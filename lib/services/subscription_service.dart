import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  static const bool debugForceSubscribed = false;

  static bool _isSubscribed = false;

  static bool get isSubscribed {
    if (debugForceSubscribed) return true;
    return _isSubscribed;
  }

  /// 🔥 INIT — called when app starts
  static Future<void> init() async {
    try {
      /// ✅ PICK CORRECT KEY BASED ON PLATFORM
      String apiKey;

      if (Platform.isIOS) {
        apiKey = "appl_PUSUzSUTwTnqCKYmRlKutkZUeLvY";
      } else if (Platform.isAndroid) {
        apiKey = "goog_lnWIfTDSTBOqFJIxpYcUjFRWRql";
      } else {
        throw UnsupportedError("Unsupported platform");
      }

      /// ✅ CONFIGURE REVENUECAT
      await Purchases.configure(
        PurchasesConfiguration(apiKey),
      );

      /// ✅ LOGIN USER
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await Purchases.logIn(user.uid);
      }

      /// ✅ GET SUB STATUS
      final info = await Purchases.getCustomerInfo();

      _isSubscribed =
          info.entitlements.active.containsKey('premium');

      print("SUB STATUS (INIT): $_isSubscribed");
    } catch (e) {
      print("Subscription init error: $e");
      _isSubscribed = false;
    }
  }

  /// 🔥 AFTER PURCHASE / RESTORE
  static void updateStatus(CustomerInfo info) {
    _isSubscribed =
        info.entitlements.active.containsKey('premium');

    print("SUB STATUS (UPDATE): $_isSubscribed");
  }
}