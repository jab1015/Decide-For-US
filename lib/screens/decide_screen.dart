import 'dart:async';
import 'dart:convert';
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

class _DecideScreenState extends State<DecideScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final player = AudioPlayer();
  late ConfettiController confetti;
  final ScrollController _scrollController = ScrollController();

  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  List<Activity> results = [];

  bool isLoading = false;
  bool isDateNight = false;

  int spinCount = 0;

  String? selectedGroup;
  String? selectedBudget;
  String? selectedEnergy;

  int selectedRadius = 25;
  String selectedRadiusLabel = "25 mi";

  Map<String, double>? userCoords;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _spinAnimation = Tween<double>(begin: 0, end: 0).animate(_spinController);

    confetti = ConfettiController(duration: const Duration(seconds: 2));

    _init();
  }

  Future<void> _init() async {
    await loadLocation();
    await loadSpinCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _spinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadSpinCount();
    }
  }

  Future<void> loadSpinCount() async {
    final prefs = await SharedPreferences.getInstance();
    spinCount = prefs.getInt('spinCount') ?? 0;
    setState(() {});
  }

  Future<void> saveSpinCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('spinCount', spinCount);
  }

  Future<void> loadLocation() async {
    userCoords = await LocationService.getLatLng();
  }

  void resetFilters() {
    selectedGroup = null;
    selectedBudget = null;
    selectedEnergy = null;
    selectedRadius = 25;
    selectedRadiusLabel = "25 mi";
    isDateNight = false;
  }

  void startSpinAnimation() {
    final totalTurns = 10 + Random().nextInt(4);

    _spinAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: totalTurns * 2 * pi * 0.85,
        ).chain(CurveTween(curve: Curves.linear)),
        weight: 75,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: totalTurns * 2 * pi * 0.85,
          end: totalTurns * 2 * pi,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 25,
      ),
    ]).animate(_spinController);

    _spinController.forward(from: 0);
  }

  Future<void> spin() async {
    if (isLoading) return;

    await loadSpinCount();

    if (spinCount >= 3) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );

      if (result == true) {
        await loadSpinCount();
        setState(() {
          results.clear();
          resetFilters();
        });
      }
      return;
    }

    if (userCoords == null) {
      await loadLocation();
      if (userCoords == null) return;
    }

    spinCount++;
    await saveSpinCount();

    setState(() {
      isLoading = true;
      results.clear();
    });

    startSpinAnimation();
    await player.play(AssetSource('sounds/spin.mp3'));

    final start = DateTime.now();

    List<Activity> data = [];

    try {
      data = await AIService.getIdeas(
        group: selectedGroup,
        budget: selectedBudget,
        energy: selectedEnergy,
        isDateNight: isDateNight,
        lat: userCoords!['lat'],
        lng: userCoords!['lng'],
        radius: selectedRadius,
      );
    } catch (e) {
      print("ERROR: $e");
    }

    final elapsed = DateTime.now().difference(start).inMilliseconds;

    if (elapsed < 8000) {
      await Future.delayed(Duration(milliseconds: 8000 - elapsed));
    }

    if (data.length > 2) data = data.take(2).toList();
    if (data.length == 1) data.add(data.first);

    await player.play(AssetSource('sounds/win.mp3'));

    setState(() {
      results = data;
      isLoading = false;
      resetFilters();
    });

    if (results.isNotEmpty) {
      confetti.play();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Widget sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget chip(String label, String? selected, Function(String) onTap) {
    final isSelected = selected == label;

    return GestureDetector(
      onTap: () => setState(() => onTap(label)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // 🔥 FIXED CENTERED ROW
  Widget row(List<String> items, String? selected, Function(String) onTap) {
    return SizedBox(
      height: 40,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: items.map((e) => chip(e, selected, onTap)).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget spinner() {
    return AnimatedBuilder(
      animation: _spinController,
      builder: (_, child) {
        return Transform.rotate(
          angle: _spinAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: 200,
        height: 200,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.deepPurple,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("💖 Date Night"),
                const SizedBox(width: 8),
                Switch(
                  value: isDateNight,
                  onChanged: (v) => setState(() => isDateNight = v),
                ),
              ],
            ),
            const SizedBox(height: 25),
            sectionLabel("Distance"),
            row(["10 mi", "25 mi", "50 mi", "Explore"], selectedRadiusLabel,
                (v) => selectedRadiusLabel = v),
            const SizedBox(height: 20),
            sectionLabel("Who’s involved?"),
            row(["Couple", "Friends", "Family", "Solo"], selectedGroup,
                (v) => selectedGroup = v),
            const SizedBox(height: 20),
            sectionLabel("Budget"),
            row(["Free", "\$", "\$\$"], selectedBudget,
                (v) => selectedBudget = v),
            const SizedBox(height: 20),
            sectionLabel("Energy"),
            row(["Low", "Medium", "High"], selectedEnergy,
                (v) => selectedEnergy = v),
            const SizedBox(height: 30),
            GestureDetector(onTap: spin, child: spinner()),
            const SizedBox(height: 30),
            ...results.asMap().entries.map(
                  (e) => DecisionCard(activity: e.value, index: e.key),
                ),
          ],
        ),
      ),
    );
  }
}
