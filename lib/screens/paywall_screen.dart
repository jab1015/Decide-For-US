import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart'; // 🔥 REQUIRED FOR kIsWeb

import '../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool isLoading = false;

  Future<void> resetUsage(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("usageCount", 0);
    await prefs.setString("lastReset", DateTime.now().toIso8601String());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Usage reset")),
    );
  }

  /// 🔥 FULL SUBSCRIBE METHOD (WEB SAFE + REVENUECAT FIXED)
  Future<void> subscribe() async {
    // 🚫 BLOCK WEB (REQUIRED)
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Purchases not supported on web"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null ||
          offerings.current!.availablePackages.isEmpty) {
        throw Exception("No packages found in RevenueCat");
      }

      final package = offerings.current!.availablePackages.first;

      final result = await Purchases.purchasePackage(package);

      final customerInfo = result.customerInfo;

      // 🔥 UPDATE SUBSCRIPTION STATE
      SubscriptionService.updateStatus(customerInfo);

      if (SubscriptionService.isSubscribed) {
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception("No active entitlement");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Purchase failed: $e")),
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  /// 🔥 RESTORE
  Future<void> restore() async {
    if (kIsWeb) return;

    try {
      final info = await Purchases.restorePurchases();

      SubscriptionService.updateStatus(info);

      if (SubscriptionService.isSubscribed) {
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No active subscription")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Restore failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            children: [
              const Text(
                "Unlock Premium 💎",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Unlimited spins\nExclusive Date Night ideas\nSmarter AI suggestions",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 40),

              /// 🔥 SUBSCRIBE BUTTON
              GestureDetector(
                onTap: isLoading ? null : subscribe,
                child: Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      isLoading ? "Processing..." : "Subscribe Now",
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// 🔥 RESTORE BUTTON
              TextButton(
                onPressed: restore,
                child: const Text(
                  "Restore Purchases",
                  style: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 10),

              /// 🔥 BACK
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Maybe Later",
                  style: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 10),

              /// 🔥 TEST RESET
              TextButton(
                onPressed: () => resetUsage(context),
                child: const Text(
                  "Reset Usage",
                  style: TextStyle(color: Colors.white60),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}