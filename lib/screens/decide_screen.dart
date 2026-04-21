import 'dart:async';
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
  late ConfettiController confetti;

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _resultsKey = GlobalKey();

  List<Activity> results = [];

  bool isLoading = false;
  bool isDateNight = false;

  String? selectedGroup;
  String? selectedBudget;
  String? selectedEnergy;

  Map<String, double>? userCoords;

  double rotation = 0;
  int spinCount = 0;

  int selectedRadius = 25;

  @override
  void initState() {
    super.initState();
    confetti = ConfettiController(duration: const Duration(seconds: 2));
    loadLocation();
    loadUsage();
  }

  Future<void> loadUsage() async {
    final prefs = await SharedPreferences.getInstance();
    spinCount = prefs.getInt("spinCount") ?? 0;
  }

  Future<void> loadLocation() async {
    userCoords = await LocationService.getLatLng();
  }

  Future<void> openPaywall() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );

    if (result == true) {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        spinCount = prefs.getInt("spinCount") ?? 0;
        selectedGroup = null;
        selectedBudget = null;
        selectedEnergy = null;
        isDateNight = false;
      });
    }
  }

  // 🔥 FINAL iOS-SAFE SCROLL
  Future<void> _scrollToResults() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_scrollController.hasClients) return;

    final context = _resultsKey.currentContext;
    if (context == null) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final position = box.localToGlobal(Offset.zero).dy;

    final offset = _scrollController.offset + position - 100;

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> spin() async {
    if (isLoading) return;

    if (spinCount >= 3) {
      await openPaywall();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    spinCount++;
    await prefs.setInt("spinCount", spinCount);

    setState(() {
      isLoading = true;
      results.clear();
      rotation += 10;
    });

    await player.play(AssetSource('sounds/spin.mp3'));

    final apiFuture = AIService.getIdeas(
      group: selectedGroup,
      budget: selectedBudget,
      energy: selectedEnergy,
      isDateNight: isDateNight,
      lat: userCoords?['lat'],
      lng: userCoords?['lng'],
      radius: selectedRadius,
    );

    final result = await Future.wait([
      apiFuture,
      Future.delayed(const Duration(seconds: 6)),
    ]);

    final data = result[0] as List<Activity>;

    await player.play(AssetSource('sounds/win.mp3'));

    setState(() {
      results = data;
      isLoading = false;
      selectedGroup = null;
      selectedBudget = null;
      selectedEnergy = null;
    });

    confetti.play();

    await _scrollToResults();
  }

  Widget chip(String label, String? selected, Function(String) onTap) {
    final isSelected = selected == label;

    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6A5AE0) : Colors.white,
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget spinner() {
    return GestureDetector(
      onTap: spin,
      child: AnimatedRotation(
        turns: rotation,
        duration: const Duration(seconds: 6),
        child: Container(
          width: 200,
          height: 200,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A5AE0), Color(0xFF4FC3F7)],
            ),
            shape: BoxShape.circle,
          ),
          child: const Text(
            "SPIN",
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget distanceSelector() {
    final options = ["10 mi", "25 mi", "50 mi", "Explore"];

    return Column(
      children: [
        const Text("How far are you willing to go?",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: options.map((o) {
            final isSelected = (o == "10 mi" && selectedRadius == 10) ||
                (o == "25 mi" && selectedRadius == 25) ||
                (o == "50 mi" && selectedRadius == 50) ||
                (o == "Explore" && selectedRadius == 100);

            return chip(o, isSelected ? o : null, (v) {
              setState(() {
                if (v == "10 mi") selectedRadius = 10;
                if (v == "25 mi") selectedRadius = 25;
                if (v == "50 mi") selectedRadius = 50;
                if (v == "Explore") selectedRadius = 100;
              });
            });
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Decide For Us"),
        centerTitle: true,
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
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("💖 Date Night"),
                    Switch(
                      value: isDateNight,
                      onChanged: (v) => setState(() => isDateNight = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                distanceSelector(),
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
                Center(child: spinner()),
                const SizedBox(height: 30),
                if (results.isNotEmpty) Container(key: _resultsKey),
                ...results.asMap().entries.map(
                      (entry) => DecisionCard(
                        activity: entry.value,
                        index: entry.key,
                      ),
                    ),
                const SizedBox(height: 40),
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
