import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  Future<void> _resetUsage(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // 🔥 SINGLE SOURCE OF TRUTH
    await prefs.setInt('spinCount', 0);

    debugPrint("✅ spinCount RESET TO 0");

    // ✅ Give slight delay to ensure persistence (important on iOS)
    await Future.delayed(const Duration(milliseconds: 150));

    if (context.mounted) {
      Navigator.pop(context, true); // 🔥 RETURN SIGNAL
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6A5AE0),
              Color(0xFF4FC3F7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Unlock Premium",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Unlimited spins\nBetter experiences\nSmarter suggestions",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const SizedBox(height: 40),

              Container(
                width: 260,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "SUBSCRIBE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              TextButton(
                onPressed: () {},
                child: const Text(
                  "Restore Purchases",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Maybe Later",
                  style: TextStyle(color: Colors.white70),
                ),
              ),

              // 🔥 FIXED RESET
              TextButton(
                onPressed: () => _resetUsage(context),
                child: const Text(
                  "Reset Usage",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
