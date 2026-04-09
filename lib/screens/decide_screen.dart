import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity.dart';
import '../widgets/decision_card.dart';
import '../services/ai_service.dart';
import '../services/subscription_service.dart';
import '../services/streak_service.dart';
import 'paywall_screen.dart';
import 'favorites_screen.dart';
import '../services/location_service.dart';

class DecideScreen extends StatefulWidget {
  const DecideScreen({super.key});

  @override
  State<DecideScreen> createState() => _DecideScreenState();
}

class _DecideScreenState extends State<DecideScreen> {
  bool isLoading = false;
  List<Activity> results = [];

  String? selectedGroup;
  String? selectedBudget;
  String? selectedEnergy;

  bool isDateNight = false;

  int usageCount = 0;
  int streak = 1;

  List<String> history = [];

  final ScrollController _scrollController = ScrollController();
  final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  final player = AudioPlayer();

  double rotation = 0;

  bool get isSubscribed => SubscriptionService.isSubscribed;

  @override
  void initState() {
    super.initState();
    loadUsage();
    loadStreak();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString("history");
    if (stored != null) {
      history = List<String>.from(jsonDecode(stored));
    }
  }

  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("history", jsonEncode(history));
  }

  Future<void> loadUsage() async {
    final prefs = await SharedPreferences.getInstance();
    usageCount = prefs.getInt("usageCount") ?? 0;
  }

  Future<void> saveUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("usageCount", usageCount);
  }

  void loadStreak() async {
    final s = await StreakService.updateStreak();
    setState(() => streak = s);
  }

  Future<bool> canUseApp() async {
    if (usageCount >= 3 && !isSubscribed) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );

      await loadUsage();

      if (usageCount >= 3 && !isSubscribed) return false;
    }

    usageCount++;
    await saveUsage();
    return true;
  }

  void spin() async {
    if (isLoading) return;

    if (isDateNight && !isSubscribed) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }

    if (!await canUseApp()) return;

    await player.play(AssetSource('sounds/spin.mp3'));

    final group = selectedGroup;
    final budget = selectedBudget;
    final energy = selectedEnergy;

    setState(() {
      isLoading = true;
      results = [];

      selectedGroup = null;
      selectedBudget = null;
      selectedEnergy = null;

      rotation += Random().nextDouble() * 25 + 35;
    });

    try {
      // 🚀 START LOCATION + API IMMEDIATELY
      final locationFuture = LocationService.getCityState();

      final ideasFuture = locationFuture.then((location) {
        return AIService.getIdeas(
          group: group,
          budget: budget,
          energy: energy,
          isDateNight: isDateNight,
          history: history,
          location: location,
        );
      });

      // ⏱ FORCE 8 SECOND SPIN
      final spinDelay = Future.delayed(const Duration(seconds: 8));

      // ⏱ WAIT FOR BOTH
      final resultsData = await Future.wait([
        ideasFuture.timeout(const Duration(seconds: 10)),
        spinDelay,
      ]);

      final aiResults = resultsData[0] as List<Activity>;
      final limitedResults = aiResults.take(2).toList();

      setState(() {
        results = limitedResults;
        isLoading = false;
      });

      await player.play(AssetSource('sounds/win.mp3'));
      _confetti.play();

    } catch (e) {
      setState(() {
        results = [
          Activity(
            title: "Something went wrong",
            description: "Please try again.",
            group: "",
            budget: "",
          )
        ];
        isLoading = false;
      });
    }
  }

  Widget chip(String label, String? selected, Function(String) onTap) {
    final isSelected = selected == label;

    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                "Decide For Us",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Date Night 💎"),
                  Switch(
                    value: isDateNight,
                    onChanged: (val) {
                      if (!isSubscribed && val) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaywallScreen()),
                        );
                        return;
                      }
                      setState(() => isDateNight = val);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              section("Who’s involved?"),
              Wrap(
                spacing: 10,
                children: [
                  chip("Couple", selectedGroup, (v) => setState(() => selectedGroup = v)),
                  chip("Friends", selectedGroup, (v) => setState(() => selectedGroup = v)),
                  chip("Family", selectedGroup, (v) => setState(() => selectedGroup = v)),
                  chip("Solo", selectedGroup, (v) => setState(() => selectedGroup = v)),
                ],
              ),

              const SizedBox(height: 20),

              section("Budget"),
              Wrap(
                spacing: 10,
                children: [
                  chip("Free", selectedBudget, (v) => setState(() => selectedBudget = v)),
                  chip("\$", selectedBudget, (v) => setState(() => selectedBudget = v)),
                  chip("\$\$", selectedBudget, (v) => setState(() => selectedBudget = v)),
                ],
              ),

              const SizedBox(height: 20),

              section("Energy"),
              Wrap(
                spacing: 10,
                children: [
                  chip("Low", selectedEnergy, (v) => setState(() => selectedEnergy = v)),
                  chip("Medium", selectedEnergy, (v) => setState(() => selectedEnergy = v)),
                  chip("High", selectedEnergy, (v) => setState(() => selectedEnergy = v)),
                ],
              ),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: spin,
                child: AnimatedRotation(
                  turns: rotation,
                  duration: const Duration(seconds: 8),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple, Colors.blue],
                      ),
                    ),
                    child: const Center(
                      child: Text("SPIN 🎡",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (isLoading)
                Column(
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Finding the perfect plan near you..."),
                  ],
                ),

              const SizedBox(height: 20),

              ...results.map((r) => DecisionCard(activity: r)),
            ],
          ),
        ),
      ),
    );
  }
}