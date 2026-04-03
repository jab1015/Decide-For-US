import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../models/activity.dart';

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
      favorites = data.map((e) {
        if (e is Activity) return e;
        return Activity(
          title: e.toString(),
          description: '',
          group: '',
          budget: '',
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? const Center(child: Text('No favorites yet'))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final activity = favorites[index];

                return ListTile(
                  title: Text(activity.title),
                  subtitle: Text(activity.description),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () async {
                      await FavoritesService.toggle(activity);
                      loadFavorites();
                    },
                  ),
                );
              },
            ),
    );
  }
}