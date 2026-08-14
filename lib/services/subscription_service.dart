import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  static const bool testerPremiumAccess = bool.fromEnvironment(
    'TESTER_PREMIUM_ACCESS',
    defaultValue: false,
  );
  static const String entitlementId = 'premium';
  static const String premiumAccessUrl =
      'https://us-central1-decide-for-us-792bc.cloudfunctions.net/getPremiumAccess';
  static bool _isInitialized = false;
  static bool _isConfigured = false;
  static bool _isSubscribed = false;

  static bool get isSubscribed => testerPremiumAccess || _isSubscribed;

  static Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (testerPremiumAccess) {
      _isSubscribed = true;
      return;
    }

    if (kIsWeb) {
      _isSubscribed = await _serverPremiumAccess();
      return;
    }

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
    if (testerPremiumAccess) {
      _isSubscribed = true;
      return;
    }
    if (_isConfigured) {
      updateStatus(await Purchases.getCustomerInfo());
    }
    if (!_isSubscribed) {
      _isSubscribed = await _serverPremiumAccess();
    }
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

  static Future<bool> _serverPremiumAccess() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return false;
      final response = await http.post(
        Uri.parse(premiumAccessUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          if (testerPremiumAccess) 'X-Decide-Tester-Build': '1',
        },
      );
      if (response.statusCode != 200) return false;
      final decoded = jsonDecode(response.body);
      return decoded is Map && decoded['allowed'] == true;
    } catch (_) {
      return false;
    }
  }
}
