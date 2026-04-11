import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity.dart';
import '../services/ai_service.dart';
import '../services/location_service.dart';
import '../widgets/decision_card.dart';
import 'favorites_screen.dart';
import 'paywall_screen.dart';

class DecideScreen extends StatefulWidget {
  const DecideScreen({super.key});

  @override
  State<DecideScreen> createState() => _DecideScreenState();
}

class _DecideScreenState extends State<DecideScreen> {
  final player = AudioPlayer();
  final confetti = ConfettiController(duration: const Duration(seconds: 2));

  List<Activity> results = [];

  bool isLoading = false;

  String? selectedGroup;
  String? selectedBudget;
  String? selectedEnergy;
  bool isDateNight = false;

  String? location;

  double rotation = 0;

  int spinCount = 0;

  @override
  void initState() {
    super.initState();
    loadLocation();
    loadSpinCount();
  }

  Future<void> loadSpinCount() async {
    final prefs = await SharedPreferences.getInstance();
    spinCount = prefs.getInt("spinCount") ?? 0;
  }

  Future<void> saveSpinCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("spinCount", spinCount);
  }

  Future<void> loadLocation() async {
    location = await LocationService.getCityState();
  }

  Future<void> spin() async {
    if (isLoading) return;

    // 💰 PAYWALL
    if (spinCount >= 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }

    spinCount++;
    await saveSpinCount();

    setState(() {
      isLoading = true;
      results.clear();
      rotation += 8;
    });

    await player.stop();
    await player.play(AssetSource('sounds/spin.mp3'));

    final apiCall = AIService.getIdeas(
      group: selectedGroup,
      budget: selectedBudget,
      energy: selectedEnergy,
      isDateNight: isDateNight,
      location: location,
      history: results.map((e) => e.title).toList(),
    );

    final result = await Future.wait([
      apiCall,
      Future.delayed(const Duration(seconds: 8)),
    ]);

    final data = result[0] as List<Activity>;

    setState(() {
      results = data;
      isLoading = false;

      selectedGroup = null;
      selectedBudget = null;
      selectedEnergy = null;
    });

    confetti.play();
  }

  Widget spinner() {
    return GestureDetector(
      onTap: spin,
      child: AnimatedRotation(
        turns: rotation,
        duration: const Duration(seconds: 1),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.blue],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                  )
                ],
              ),
            ),

            // 🔥 LOADER
            if (isLoading)
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // 🔥 TEXT ALWAYS VISIBLE
            const Text(
              "SPIN",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget chip(String label, String? selected, Function(String) onTap) {
    final isSelected = selected == label;

    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget section(String title, List<String> options, String? selected,
      Function(String) onTap) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: options.map((o) => chip(o, selected, onTap)).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Decide For Us"),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FavoritesScreen(),
                ),
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("💖 Date Night"),
                    Switch(
                      value: isDateNight,
                      onChanged: (v) =>
                          setState(() => isDateNight = v),
                    ),
                  ],
                ),

                section(
                  "Who’s involved?",
                  ["Couple", "Friends", "Family", "Solo"],
                  selectedGroup,
                  (v) => setState(() => selectedGroup = v),
                ),

                section(
                  "Budget",
                  ["Free", "\$", "\$\$"],
                  selectedBudget,
                  (v) => setState(() => selectedBudget = v),
                ),

                section(
                  "Energy",
                  ["Low", "Medium", "High"],
                  selectedEnergy,
                  (v) => setState(() => selectedEnergy = v),
                ),

                const SizedBox(height: 20),

                spinner(),

                const SizedBox(height: 30),

                ...results.map((e) => DecisionCard(activity: e)),

                const SizedBox(height: 60),
              ],
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(confettiController: confetti),
          ),
        ],
      ),
    );
  }
}