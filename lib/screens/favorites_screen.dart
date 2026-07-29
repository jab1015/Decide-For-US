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
    final list = prefs.getStringList('favorites') ?? [];

    final loaded = list.map((item) {
      final data = jsonDecode(item);
      return Activity(
        id: data['id'],
        category: data['category'] ?? 'activity',
        title: data['title'],
        description: data['description'],
        address: data['address'],
        lat: data['lat'],
        lng: data['lng'],
        photoUrl: data['photoUrl'],
      );
    }).toList();

    setState(() {
      favorites = loaded;
    });
  }

  void removeFavorite(String id) {
    setState(() {
      favorites.removeWhere((a) => a.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorites")),
      body: favorites.isEmpty
          ? const Center(child: Text("No favorites yet"))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                return DecisionCard(
                  activity: favorites[index],
                  index: index,
                  isFavoritesView: true,
                  onDeleted: () =>
                      removeFavorite(favorites[index].id), // 🔥 instant removal
                );
              },
            ),
    );
  }
}
