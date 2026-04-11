import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity.dart';
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
    final favs = prefs.getStringList('favorites') ?? [];

    favorites =
        favs.map((f) => Activity.fromJson(jsonDecode(f))).toList();

    setState(() {});
  }

  Future<void> removeFavorite(Activity activity) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList('favorites') ?? [];

    favs.removeWhere((f) =>
        jsonDecode(f)['title'] == activity.title);

    await prefs.setStringList('favorites', favs);

    loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorites")),
      body: ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final activity = favorites[index];

          return Stack(
            children: [
              DecisionCard(
                activity: activity,
                showFavorite: false, // 🔥 HARD OFF
              ),
              Positioned(
                right: 10,
                top: 10,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => removeFavorite(activity),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}