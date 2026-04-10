import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/favorites_service.dart';

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
    final favs = await FavoritesService.getFavorites();
    setState(() => favorites = favs);
  }

  Future<void> removeFavorite(Activity activity) async {
    await FavoritesService.toggleFavorite(activity);
    loadFavorites();
  }

  Color baseColor(String title) {
    final colors = [
      const Color(0xFF7B61FF),
      const Color(0xFFFF6B6B),
      const Color(0xFF00C9A7),
      const Color(0xFFFFA726),
    ];
    return colors[title.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorites")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: favorites.map((item) {
          final color = baseColor(item.title);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(item.description),
                  ],
                ),

                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => removeFavorite(item),
                  ),
                )
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}