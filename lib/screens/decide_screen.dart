import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/activity.dart';
import '../services/ai_service.dart';
import '../services/location_service.dart';
import '../widgets/decision_card.dart';
import 'favorites_screen.dart';

class DecideScreen extends StatefulWidget {
  const DecideScreen({super.key});

  @override
  State<DecideScreen> createState() => _DecideScreenState();
}

class _DecideScreenState extends State<DecideScreen> {
  final player = AudioPlayer();
  late ConfettiController confetti;
  final ScrollController _scrollController = ScrollController();

  List<Activity> results = [];

  bool isLoading = false;
  bool isDateNight = false;

  String? selectedGroup;
  String? selectedBudget;
  String? selectedEnergy;

  int selectedRadius = 25;
  String selectedRadiusLabel = "25 mi";

  Map<String, double>? userCoords;

  double rotation = 0;

  @override
  void initState() {
    super.initState();
    confetti = ConfettiController(duration: const Duration(seconds: 2));
    loadLocation();
  }

  Future<void> loadLocation() async {
    userCoords = await LocationService.getLatLng();
  }

  // 🔥 iOS-safe scroll fix
  Future<void> _waitAndScroll() async {
    int attempts = 0;

    while (attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 120));

      if (!_scrollController.hasClients) {
        attempts++;
        continue;
      }

      final maxScroll = _scrollController.position.maxScrollExtent;

      if (maxScroll > 0) {
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
        );
        return;
      }

      attempts++;
    }
  }

  Future<void> spin() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      results.clear();
      rotation += 10;
    });

    await player.play(AssetSource('sounds/spin.mp3'));

    List<Activity> data = [];

    try {
      data = await AIService.getIdeas(
        group: selectedGroup,
        budget: selectedBudget,
        energy: selectedEnergy,
        isDateNight: isDateNight,
        lat: userCoords?['lat'],
        lng: userCoords?['lng'],
        radius: selectedRadius,
      );
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 8));

    await player.play(AssetSource('sounds/win.mp3'));

    setState(() {
      results = data;
      isLoading = false;

      selectedGroup = null;
      selectedBudget = null;
      selectedEnergy = null;
    });

    if (results.isNotEmpty) {
      confetti.play();
    }

    _waitAndScroll();
  }

  // 🎨 Updated premium chip styling (softer purple)
  Widget buildChips(
      List<String> options, String? selected, Function(String) onTap) {
    return Wrap(
      spacing: 10,
      children: options.map((option) {
        final isSelected = selected == option;

        return ChoiceChip(
          label: Text(
            option,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => setState(() => onTap(option)),
          selectedColor: const Color(0xFF7B6CF6), // softer purple
          backgroundColor: Colors.grey.shade200,
          elevation: isSelected ? 4 : 0,
          pressElevation: 2,
          shadowColor: Colors.black26,
        );
      }).toList(),
    );
  }

  Widget buildRadiusChips() {
    final options = ["10 mi", "25 mi", "50 mi", "Explore"];

    return Wrap(
      spacing: 10,
      children: options.map((label) {
        final isSelected = selectedRadiusLabel == label;

        return ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              selectedRadiusLabel = label;

              if (label == "10 mi") selectedRadius = 10;
              if (label == "25 mi") selectedRadius = 25;
              if (label == "50 mi") selectedRadius = 50;
              if (label == "Explore") selectedRadius = 100;
            });
          },
          selectedColor: const Color(0xFF7B6CF6),
          backgroundColor: Colors.grey.shade200,
          elevation: isSelected ? 4 : 0,
          shadowColor: Colors.black26,
        );
      }).toList(),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // 💖 Date Night
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

                // 📍 Distance
                const Text("How far are you willing to go?"),
                const SizedBox(height: 10),
                buildRadiusChips(),

                const SizedBox(height: 20),

                // 👥 Group
                const Text("Who’s involved?"),
                const SizedBox(height: 10),
                buildChips(
                  ["Couple", "Friends", "Family", "Solo"],
                  selectedGroup,
                  (v) => selectedGroup = v,
                ),

                const SizedBox(height: 20),

                // 💰 Budget
                const Text("Budget"),
                const SizedBox(height: 10),
                buildChips(
                  ["Free", "\$", "\$\$"],
                  selectedBudget,
                  (v) => selectedBudget = v,
                ),

                const SizedBox(height: 20),

                // ⚡ Energy
                const Text("Energy"),
                const SizedBox(height: 10),
                buildChips(
                  ["Low", "Medium", "High"],
                  selectedEnergy,
                  (v) => selectedEnergy = v,
                ),

                const SizedBox(height: 30),

                // 🎯 Spin Button
                GestureDetector(
                  onTap: spin,
                  child: AnimatedRotation(
                    turns: rotation,
                    duration: const Duration(seconds: 8),
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
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 📦 Results
                ...results.map(
                  (r) => DecisionCard(
                    activity: r,
                    index: results.indexOf(r),
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
