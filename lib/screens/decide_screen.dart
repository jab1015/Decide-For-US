import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/activity.dart';
import '../models/planning_request.dart';
import '../services/ai_service.dart';
import '../services/location_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/experience_card.dart';
import 'favorites_screen.dart';
import 'paywall_screen.dart';

class DecideScreen extends StatefulWidget {
  const DecideScreen({super.key});

  @override
  State<DecideScreen> createState() => _DecideScreenState();
}

class _DecideScreenState extends State<DecideScreen>
    with SingleTickerProviderStateMixin {
  final player = AudioPlayer();
  late ConfettiController confetti;
  final ScrollController _scrollController = ScrollController();

  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  List<Activity> results = [];

  bool isLoading = false;
  bool isDateNight = false;

  String? selectedGroup;
  String? selectedBudget;
  String? selectedEnergy;

  int selectedRadius = 25;
  String selectedRadiusLabel = "25 mi";

  Map<String, double>? userCoords;

  @override
  void initState() {
    super.initState();

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
  }

  @override
  void dispose() {
    _spinController.dispose();
    _scrollController.dispose();
    confetti.dispose();
    player.dispose();
    super.dispose();
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

    if (userCoords == null) {
      await loadLocation();
      if (userCoords == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'We need your location to find nearby experiences.',
              ),
              duration: Duration(seconds: 6),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      isLoading = true;
      results.clear();
    });

    startSpinAnimation();
    await player.play(AssetSource('sounds/spin.mp3'));

    final start = DateTime.now();

    List<Activity> data = [];
    String? errorMessage;

    try {
      data = await AIService.getIdeas(
        PlanningRequest(
          group: selectedGroup,
          budget: selectedBudget,
          energy: selectedEnergy,
          isDateNight: isDateNight,
          lat: userCoords!['lat']!,
          lng: userCoords!['lng']!,
          radiusMiles: selectedRadius,
        ),
      );
    } on AIServiceException catch (e) {
      if (e.statusCode == 403 && mounted) {
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const PaywallScreen()),
        );
      }
      errorMessage = e.toString();
    }

    final elapsed = DateTime.now().difference(start).inMilliseconds;

    if (elapsed < 8000) {
      await Future.delayed(Duration(milliseconds: 8000 - elapsed));
    }

    if (!mounted) return;

    if (data.length > 4) data = data.take(4).toList();
    if (data.isNotEmpty) {
      await player.play(AssetSource('sounds/win.mp3'));
    }

    setState(() {
      results = data;
      isLoading = false;
      resetFilters();
    });

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 7),
        ),
      );
    }

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

  Future<void> _setDateNight(bool value) async {
    if (!value) {
      setState(() => isDateNight = false);
      return;
    }
    if (!SubscriptionService.isSubscribed) {
      final unlocked = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      if (unlocked != true) return;
      await SubscriptionService.refresh();
    }
    if (mounted) setState(() => isDateNight = true);
  }

  void _setRadius(String label) {
    const values = {'10 mi': 10, '25 mi': 25, '50 mi': 50, 'Explore': 100};
    selectedRadiusLabel = label;
    selectedRadius = values[label] ?? 25;
  }

  String get _heroEyebrow {
    if (isDateNight) return '✦  DATE NIGHT, BEAUTIFULLY DECIDED  ✦';

    final hour = DateTime.now().hour;
    if (hour < 5) return '✦  NIGHT OWL MODE  ✦';
    if (hour < 12) return '✦  GOOD MORNING, ADVENTURE AWAITS  ✦';
    if (hour < 17) return '✦  MAKE THIS AFTERNOON YOURS  ✦';
    if (hour < 22) return '✦  YOUR EVENING STARTS HERE  ✦';
    return '✦  THE NIGHT IS STILL YOUNG  ✦';
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
          color: isSelected ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.ink,
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
        return Transform.rotate(angle: _spinAnimation.value, child: child);
      },
      child: SizedBox(
        width: 166,
        height: 166,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 166,
              height: 166,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lavender.withValues(alpha: 0.65),
              ),
            ),
            Container(
              width: 138,
              height: 138,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.34),
                    blurRadius: 36,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isLoading ? 'FINDING' : 'DECIDE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "DECIDE FOR US",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.coral,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _heroEyebrow,
              style: const TextStyle(
                color: AppColors.coral,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your next good story\nstarts here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 10),
            Text(
              'Tell us the mood. We’ll choose the adventure.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.dateNight,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: const Color(0xFFE6DDF6)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '♥',
                      style: TextStyle(color: AppColors.coral, fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date Night+',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Romance, without the planning.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(value: isDateNight, onChanged: _setDateNight),
                ],
              ),
            ),
            const SizedBox(height: 25),
            sectionLabel("Distance"),
            row(
              ["10 mi", "25 mi", "50 mi", "Explore"],
              selectedRadiusLabel,
              _setRadius,
            ),
            const SizedBox(height: 20),
            sectionLabel("Who’s involved?"),
            row(
              ["Couple", "Friends", "Family", "Solo"],
              selectedGroup,
              (v) => selectedGroup = v,
            ),
            const SizedBox(height: 20),
            sectionLabel("Budget"),
            row(
              ["Free", "\$", "\$\$"],
              selectedBudget,
              (v) => selectedBudget = v,
            ),
            const SizedBox(height: 20),
            sectionLabel("Energy"),
            row(
              ["Low", "Medium", "High"],
              selectedEnergy,
              (v) => selectedEnergy = v,
            ),
            const SizedBox(height: 22),
            GestureDetector(onTap: spin, child: spinner()),
            const SizedBox(height: 30),
            if (results.isNotEmpty) ...[
              const Text(
                '✦  YOUR ADVENTURE',
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A little plan with\nbig story potential.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
            ],
            if (results.length >= 4) ...[
              ExperienceCard(
                first: results[0],
                second: results[1],
                optionIndex: 0,
              ),
              ExperienceCard(
                first: results[2],
                second: results[3],
                optionIndex: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

