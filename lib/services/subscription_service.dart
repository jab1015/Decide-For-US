import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  static bool _isSubscribed = false;

  static bool get isSubscribed => _isSubscribed;

  static Future<void> init() async {
    try {
      // 🚫 BLOCK WEB
      if (kIsWeb) {
        _isSubscribed = false;
        return;
      }

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
      _isSubscribed = info.entitlements.active.containsKey('premium');

      Purchases.addCustomerInfoUpdateListener((info) {
        _isSubscribed =
            info.entitlements.active.containsKey('premium');
      });

    } catch (e) {
      _isSubscribed = false;
    }
  }

  static void updateStatus(CustomerInfo info) {
    _isSubscribed =
        info.entitlements.active.containsKey('premium');
  }
}