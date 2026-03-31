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

  double rotation = 0;

  List<String> history = [];

  final ScrollController _scrollController = ScrollController();
  final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  final player = AudioPlayer();

  bool get isSubscribed => SubscriptionService.isSubscribed;

  @override
  void initState() {
    super.initState();
    loadUsage();
    loadStreak();
    loadHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _confetti.dispose();
    player.dispose();
    super.dispose();
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

  Future<void> _scrollToResults() async {
    if (!_scrollController.hasClients) return;

    await Future.delayed(const Duration(milliseconds: 100));

    if (!_scrollController.hasClients) return;

    final target = _scrollController.position.maxScrollExtent;

    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
  }

  Future<void> spin() async {
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
      selectedGroup = null;
      selectedBudget = null;
      selectedEnergy = null;
      isLoading = true;
      results = [];
    });

    rotation += Random().nextDouble() * 10 + 20;

    final futureIdeas = AIService.getIdeas(
      group: group,
      budget: budget,
      energy: energy,
      isDateNight: isDateNight,
      history: history,
    );

    await Future.delayed(const Duration(seconds: 9));

    try {
      final aiResults = await futureIdeas;

      history.addAll(aiResults.map((e) => e.title));
      if (history.length > 200) {
        history = history.sublist(history.length - 200);
      }
      await saveHistory();

      setState(() {
        results = aiResults.take(2).toList();
        isLoading = false;
      });

      await player.play(AssetSource('sounds/win.mp3'));
      _confetti.play();

      await _scrollToResults();
    } catch (e) {
      setState(() {
        results = [
          Activity(
            title: "Error loading ideas",
            description: "Please try again.",
            group: "Error",
            budget: "Error",
          )
        ];
        isLoading = false;
      });

      await _scrollToResults();
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
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.deepPurple : Colors.black,
          ),
        ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Decide For Us",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text("🔥 $streak Day Streak"),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Date Night 💎"),
                  const SizedBox(width: 10),
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
                alignment: WrapAlignment.center,
                spacing: 10,
                children: ["Couple", "Friends", "Family", "Solo"]
                    .map((e) => chip(
                          e,
                          selectedGroup,
                          (v) => setState(() => selectedGroup = v),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 20),

              section("Budget"),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                children: ["Free", "\$", "\$\$"]
                    .map((e) => chip(
                          e,
                          selectedBudget,
                          (v) => setState(() => selectedBudget = v),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 20),

              section("Energy"),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                children: ["Low", "Medium", "High"]
                    .map((e) => chip(
                          e,
                          selectedEnergy,
                          (v) => setState(() => selectedEnergy = v),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 30),

              Center(
                child: GestureDetector(
                  onTap: spin,
                  child: AnimatedRotation(
                    turns: rotation,
                    duration: const Duration(seconds: 9),
                    curve: Curves.easeOut,
                    child: Container(
                      height: 160,
                      width: 160,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Colors.blue],
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "SPIN 🎡",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (isLoading) const CircularProgressIndicator(),

              const SizedBox(height: 20),

              if (!isLoading && results.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text(
                    "Tap SPIN to get ideas",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

              ...results.take(2).map((r) => DecisionCard(activity: r)),
            ],
          ),
        ),
      ),
    );
  }
}