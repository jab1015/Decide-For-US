import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  Future<void> resetUsage(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt("spinCount", 0);
    await prefs.setInt(
        "firstUse", DateTime.now().millisecondsSinceEpoch);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Usage reset to 0")),
    );

    Navigator.pop(context, true); // send signal back
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A5AE0), Color(0xFF4FC3F7)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Text(
                "Unlock Premium",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              const Text(
                "Unlimited spins\nBetter experiences\nSmarter suggestions",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                ),
                child: const Text(
                  "SUBSCRIBE",
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {},
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {},
                child: const Text("Restore Purchases",
                    style: TextStyle(color: Colors.white)),
              ),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Maybe Later",
                    style: TextStyle(color: Colors.white)),
              ),

              TextButton(
                onPressed: () => resetUsage(context),
                child: const Text("Reset Usage",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}