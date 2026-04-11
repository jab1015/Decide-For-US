import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
    final favs = prefs.getStringList("favorites") ?? [];

    setState(() {
      favorites = favs.map((e) {
        final data = jsonDecode(e);
        return Activity(
          title: data['title'],
          description: data['description'],
          address: data['address'],
          lat: data['lat'],
          lng: data['lng'],
        );
      }).toList();
    });
  }

  Future<void> removeFavorite(Activity activity) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList("favorites") ?? [];

    favs.removeWhere((e) => e.contains(activity.title));

    await prefs.setStringList("favorites", favs);

    loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorites")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: favorites.map((item) {
          return Stack(
            children: [
              DecisionCard(
                activity: item,
                showFavorite: false,
              ),
              Positioned(
                right: 10,
                top: 10,
                child: GestureDetector(
                  onTap: () => removeFavorite(item),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}