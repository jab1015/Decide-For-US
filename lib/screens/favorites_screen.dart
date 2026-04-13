import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/favorites_service.dart';
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
    final data = await FavoritesService.getFavorites();
    setState(() {
      favorites = data;
    });
  }

  Future<void> removeFavorite(Activity activity) async {
    await FavoritesService.removeFavorite(activity);
    await loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorites"),
        centerTitle: true,
      ),
      body: favorites.isEmpty
          ? const Center(child: Text("No favorites yet"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final activity = favorites[index];

                return Column(
                  children: [
                    DecisionCard(
                      activity: activity,
                      index: index, // ✅ REQUIRED
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => removeFavorite(activity),
                        child: const Text(
                          "Remove",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
    );
  }
}
