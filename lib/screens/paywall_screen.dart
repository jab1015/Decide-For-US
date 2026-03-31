import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

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
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [

                  /// 🔥 TITLE
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

                  /// 🔥 SUBTEXT
                  const Text(
                    "Better ideas. Smarter decisions.\nDate Night mode included 💎",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// 🔥 FEATURE CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: const [
                        FeatureRow("Unlimited Decisions"),
                        FeatureRow("Premium AI Ideas"),
                        FeatureRow("Date Night Mode 💎"),
                        FeatureRow("No Repeats Ever"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// 🔥 SUBSCRIBE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          final offerings =
                              await Purchases.getOfferings();

                          final package =
                              offerings.current?.availablePackages.first;

                          if (package != null) {
                            await Purchases.purchasePackage(package);
                          }
                        } catch (e) {
                          print("Purchase error: $e");
                        }
                      },
                      child: const Text(
                        "Subscribe Now",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// 🔥 RESTORE
                  TextButton(
                    onPressed: () async {
                      try {
                        await Purchases.restorePurchases();
                      } catch (e) {
                        print("Restore error: $e");
                      }
                    },
                    child: const Text(
                      "Restore Purchases",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔥 NOT RIGHT NOW (NEW)
                  TextButton(
                    onPressed: () => _goBack(context),
                    child: const Text(
                      "Not Right Now",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// 🔥 TEST BUTTON
                  TextButton(
                    onPressed: () => _resetUsage(context),
                    child: const Text(
                      "Reset Usage (Testers)",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
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

/// 🔥 FEATURE ROW
class FeatureRow extends StatelessWidget {
  final String text;

  const FeatureRow(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}