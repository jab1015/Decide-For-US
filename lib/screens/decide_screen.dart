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

  void _scrollToResultsIOSSafe() {
    print("🔥🔥🔥 SCROLL TRIGGERED 🔥🔥🔥");

    Future.delayed(const Duration(milliseconds: 50), () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) {
          print("❌ NO SCROLL CLIENTS");
          return;
        }

        final maxScroll = _scrollController.position.maxScrollExtent;

        print("📏 MAX SCROLL: $maxScroll");

        if (maxScroll > 0) {
          print("✅ SCROLLING NOW");

          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
          );
        } else {
          print("⚠️ MAX SCROLL IS ZERO — RETRYING");

          Future.delayed(const Duration(milliseconds: 150), () {
            if (_scrollController.hasClients) {
              final retryScroll = _scrollController.position.maxScrollExtent;

              print("🔁 RETRY MAX SCROLL: $retryScroll");

              _scrollController.animateTo(
                retryScroll,
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
              );
            }
          });
        }
      });
    });
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
        group: selectedGroup,
        budget: selectedBudget,
        energy: selectedEnergy,
        isDateNight: isDateNight,
        lat: userCoords?['lat'],
        lng: userCoords?['lng'],
        radius: selectedRadius,
      );
    } catch (e) {
      print("❌ ERROR FETCHING IDEAS: $e");
    }

    await Future.delayed(const Duration(seconds: 8));

    if (data.isEmpty) {
      data = [
        Activity(
          id: "fallback",
          title: "Try Again Nearby",
          description: "We couldn’t load ideas right now. Try again.",
          address: "",
          lat: 0,
          lng: 0,
        )
      ];
    }

    await player.play(AssetSource('sounds/win.mp3'));

    setState(() {
      results = data;
      isLoading = false;

      selectedGroup = null;
      selectedBudget = null;
      selectedEnergy = null;
    });

    print("✅ RESULTS SET");
    print("📊 Results count: ${results.length}");

    if (results.isNotEmpty) {
      confetti.play();
    }

    _scrollToResultsIOSSafe();
  }

  @override
  Widget build(BuildContext context) {
    print("🧱 BUILD RUN - results length: ${results.length}");

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
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
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
