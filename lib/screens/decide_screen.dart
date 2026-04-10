import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity.dart';
import '../widgets/decision_card.dart';
import '../services/ai_service.dart';
import '../services/location_service.dart';
import '../services/decision_service.dart';
import '../services/streak_service.dart';
import '../services/subscription_service.dart';

import 'paywall_screen.dart';
import 'favorites_screen.dart';

class DecideScreen extends StatefulWidget {
  const DecideScreen({super.key});

  @override
  State<DecideScreen> createState() => _DecideScreenState();
}

class _DecideScreenState extends State<DecideScreen> {
  final AudioPlayer player = AudioPlayer();

  bool isLoading = false;
  List<Activity> results = [];

  String? selectedGroup;
  String? selectedBudget;
  String? selectedEnergy;
  bool isDateNight = false;

  int usageCount = 0;
  int streak = 1;

  double rotation = 0;

  String? userLocation;
  bool locationRequested = false;

  @override
  void initState() {
    super.initState();
    loadUsage();
    loadStreak();
  }

  Future<void> loadStreak() async {
    final s = await StreakService.updateStreak();
    if (mounted) setState(() => streak = s);
  }

  Future<void> loadUsage() async {
    final prefs = await SharedPreferences.getInstance();
    usageCount = prefs.getInt("usageCount") ?? 0;
    if (mounted) setState(() {});
  }

  Future<void> saveUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("usageCount", usageCount);
  }

  Future<void> requestLocationIfNeeded() async {
    if (locationRequested) return;
    locationRequested = true;

    try {
      userLocation = await LocationService.getCityState();
    } catch (_) {
      userLocation = null;
    }
  }

  void goToPaywall() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DecideScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  void spin() async {
    if (isLoading) return;

    if (!SubscriptionService.isSubscribed && usageCount >= 3) {
      goToPaywall();
      return;
    }

    usageCount++;
    await saveUsage();

    HapticFeedback.mediumImpact();
    unawaited(player.play(AssetSource('sounds/spin.mp3')));

    final group = selectedGroup;
    final budget = selectedBudget;
    final energy = selectedEnergy;
    final dateNight = isDateNight;

    setState(() {
      isLoading = true;
      results.clear();
      rotation += 8;

      selectedGroup = null;
      selectedBudget = null;
      selectedEnergy = null;
      isDateNight = false;
    });

    unawaited(requestLocationIfNeeded());

    try {
      final Future<List<Activity>> f1 = AIService.getIdeas(
        group: group,
        budget: budget,
        energy: energy,
        isDateNight: dateNight,
        location: userLocation,
      );

      final Future<List<Activity>> f2 = AIService.getIdeas(
        group: group,
        budget: budget,
        energy: energy,
        isDateNight: dateNight,
        location: userLocation,
      );

      final aiFuture = Future.wait<List<Activity>>([f1, f2]);

      List<List<Activity>>? aiResults;

      try {
        aiResults = await aiFuture.timeout(const Duration(seconds: 2));
      } catch (_) {}

      await Future.delayed(const Duration(seconds: 8));

      if (aiResults == null) {
        try {
          aiResults = await aiFuture;
        } catch (_) {}
      }

      List<Activity> finalResults;

      if (aiResults != null && aiResults.isNotEmpty) {
        final combined = [...aiResults[0], ...aiResults[1]];
        final map = <String, Activity>{};
        for (var item in combined) {
          map[item.title] = item;
        }
        finalResults = map.values.take(2).toList();
      } else {
        finalResults = DecisionService.getFiltered().take(2).toList();
      }

      if (!mounted) return;

      setState(() {
        results = finalResults;
        isLoading = false;
      });

      unawaited(player.play(AssetSource('sounds/win.mp3')));
    } catch (_) {
      final fallback = DecisionService.getFiltered();

      await Future.delayed(const Duration(seconds: 8));

      setState(() {
        results = fallback.take(2).toList();
        isLoading = false;
      });
    }
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
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget section(String title, List<String> options, String? selected,
      Function(String) onTap) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          children: options.map((o) => chip(o, selected, onTap)).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget dateNightToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("💖 Date Night"),
        const SizedBox(width: 10),
        Switch(
          value: isDateNight,
          onChanged: (val) => setState(() => isDateNight = val),
        )
      ],
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
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Decide For Us",
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text("🔥 $streak Day Streak"),

                const SizedBox(height: 20),
                dateNightToggle(),

                const SizedBox(height: 20),

                section("Who’s involved?",
                    ["Couple", "Friends", "Family", "Solo"],
                    selectedGroup, (v) => setState(() => selectedGroup = v)),

                section("Budget",
                    ["Free", "\$", "\$\$"],
                    selectedBudget, (v) => setState(() => selectedBudget = v)),

                section("Energy",
                    ["Low", "Medium", "High"],
                    selectedEnergy, (v) => setState(() => selectedEnergy = v)),

                const SizedBox(height: 20),

                AnimatedRotation(
                  turns: rotation,
                  duration: const Duration(seconds: 8),
                  child: GestureDetector(
                    onTap: spin,
                    child: Container(
                      height: 170,
                      width: 170,
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
                  const CircularProgressIndicator(),

                const SizedBox(height: 20),

                ...results.map((r) => DecisionCard(activity: r)),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}