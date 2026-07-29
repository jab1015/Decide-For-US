import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity.dart';
import '../theme/app_theme.dart';
import '../widgets/decision_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Activity> favorites = [];

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = (prefs.getStringList('favorites') ?? []).map((item) {
      return Activity.fromJson(jsonDecode(item));
    }).toList();
    if (mounted) setState(() => favorites = loaded);
  }

  void removeFavorite(String id) {
    setState(() => favorites.removeWhere((activity) => activity.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved adventures')),
      body: favorites.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        color: AppColors.peach,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 38,
                        color: AppColors.coral,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Nothing saved—yet.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Every great story starts with one decision.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Find an adventure'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final activity = favorites[index];
                return DecisionCard(
                  activity: activity,
                  index: index,
                  isFavoritesView: true,
                  onDeleted: () => removeFavorite(activity.id),
                );
              },
            ),
    );
  }
}
