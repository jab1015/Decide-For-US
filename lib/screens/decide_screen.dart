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

  Map<String, double>? userCoords;

  double rotation = 0;
  int spinCount = 0;

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

  Future<void> spin() async {
    if (isLoading) return;

    final prefs = await SharedPreferences.getInstance();
    spinCount++;
    await prefs.setInt("spinCount", spinCount);

    setState(() {
      isLoading = true;
      results.clear();
      rotation += 10;
    });

    await player.play(AssetSource('sounds/spin.mp3'));

    List<Activity> data = [];

    try {
      data = await AIService.getIdeas(
        isDateNight: isDateNight,
        lat: userCoords?['lat'],
        lng: userCoords?['lng'],
      );
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 8));

    await player.play(AssetSource('sounds/win.mp3'));

    setState(() {
      results = data;
      isLoading = false;
    });

    if (results.isNotEmpty) {
      confetti.play();
    }

    _forceScrollToResults();
  }

  void _forceScrollToResults() async {
    // Try multiple times to ensure layout is ready (iOS fix)
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 120));

      final context = _resultsKey.currentContext;

      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          alignment: 0.1,
        );
        return;
      }
    }
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
                const SizedBox(height: 20),

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

                // 👇 THIS is the anchor for scroll
                Column(
                  key: _resultsKey,
                  children: [
                    ...results.map(
                      (r) => DecisionCard(
                        activity: r,
                        index: results.indexOf(r),
                      ),
                    ),
                  ],
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
