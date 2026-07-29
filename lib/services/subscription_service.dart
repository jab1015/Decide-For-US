import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  static const String entitlementId = 'premium';
  static bool _isConfigured = false;
  static bool _isSubscribed = false;

  static bool get isSubscribed => _isSubscribed;

  static Future<void> init() async {
    if (kIsWeb || _isConfigured) return;

    final apiKey = Platform.isIOS
        ? 'appl_PUSUzSUTwTnqCKYmRlKutkZUeLv'
        : 'goog_lnWIfTDSTBOqFJIxpYcUjFRWRql';

    await Purchases.configure(PurchasesConfiguration(apiKey));
    _isConfigured = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await Purchases.logIn(user.uid);
    }

    await refresh();
    Purchases.addCustomerInfoUpdateListener(updateStatus);
  }

  static Future<void> refresh() async {
    if (!_isConfigured) return;
    updateStatus(await Purchases.getCustomerInfo());
  }

  static Future<Offerings> getOfferings() async {
    if (!_isConfigured) {
      throw StateError('Purchases are not available on this platform.');
    }
    return Purchases.getOfferings();
  }

  static Future<bool> purchase(Package package) async {
    final result = await Purchases.purchase(PurchaseParams.package(package));
    updateStatus(result.customerInfo);
    return _isSubscribed;
  }

  static Future<bool> restore() async {
    updateStatus(await Purchases.restorePurchases());
    return _isSubscribed;
  }

  static void updateStatus(CustomerInfo info) {
    _isSubscribed = info.entitlements.active.containsKey(entitlementId);
  }
}
