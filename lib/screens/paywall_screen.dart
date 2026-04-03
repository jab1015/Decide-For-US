import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/subscription_service.dart';
import 'decide_screen.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  Future<void> _resetUsage(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("usageCount", 0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Usage reset for testing")),
    );
  }

  void _goBack(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DecideScreen()),
      (route) => false,
    );
  }

  Future<void> _purchase(BuildContext context) async {
    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.availablePackages.first;

      if (package != null) {
        final result = await Purchases.purchasePackage(package);

        /// 🔥 UPDATE SUBSCRIPTION STATE
        SubscriptionService.updateStatus(result.customerInfo);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Subscription successful!")),
        );

        _goBack(context);
      }
    } catch (e) {
      print("Purchase error: $e");
    }
  }

  Future<void> _restore(BuildContext context) async {
    try {
      final info = await Purchases.restorePurchases();

      /// 🔥 UPDATE SUBSCRIPTION STATE
      SubscriptionService.updateStatus(info);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Purchases restored")),
      );

      _goBack(context);
    } catch (e) {
      print("Restore error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Unlock Unlimited Decisions ✨",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Better ideas. Smarter decisions.\nDate Night mode included 💎",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// SUBSCRIBE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _purchase(context),
                      child: const Text("Subscribe Now"),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// RESTORE
                  TextButton(
                    onPressed: () => _restore(context),
                    child: const Text("Restore Purchases"),
                  ),

                  const SizedBox(height: 20),

                  /// NOT NOW
                  TextButton(
                    onPressed: () => _goBack(context),
                    child: const Text("Not Right Now"),
                  ),

                  const SizedBox(height: 10),

                  /// TEST RESET
                  TextButton(
                    onPressed: () => _resetUsage(context),
                    child: const Text("Reset Usage (Testers)"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}