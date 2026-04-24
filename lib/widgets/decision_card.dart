import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/activity.dart';

class DecisionCard extends StatefulWidget {
  final Activity activity;
  final int index;
  final bool isFavoritesView;
  final VoidCallback? onDeleted;

  const DecisionCard({
    super.key,
    required this.activity,
    required this.index,
    this.isFavoritesView = false,
    this.onDeleted,
  });

  @override
  State<DecisionCard> createState() => _DecisionCardState();
}

class _DecisionCardState extends State<DecisionCard> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites') ?? [];

    setState(() {
      isFavorite = list.any((item) {
        final decoded = jsonDecode(item);
        return decoded['id'] == widget.activity.id;
      });
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites') ?? [];

    if (isFavorite) {
      list.removeWhere((item) {
        final decoded = jsonDecode(item);
        return decoded['id'] == widget.activity.id;
      });
    } else {
      final newItem = jsonEncode({
        'id': widget.activity.id,
        'title': widget.activity.title,
        'description': widget.activity.description,
        'address': widget.activity.address,
        'lat': widget.activity.lat,
        'lng': widget.activity.lng,
        'photoUrl': widget.activity.photoUrl,
      });

      list.add(newItem);
    }

    await prefs.setStringList('favorites', list);

    setState(() {
      isFavorite = !isFavorite;
    });
  }

  Future<void> _deleteFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites') ?? [];

    list.removeWhere((item) {
      final decoded = jsonDecode(item);
      return decoded['id'] == widget.activity.id;
    });

    await prefs.setStringList('favorites', list);

    widget.onDeleted?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Removed from favorites")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradients = [
      const LinearGradient(
        colors: [Color(0xFF00C9A7), Color(0xFF7ED957)],
      ),
      const LinearGradient(
        colors: [Color(0xFFFF7043), Color(0xFFFFA726)],
      ),
      const LinearGradient(
        colors: [Color(0xFF5C6BC0), Color(0xFF26C6DA)],
      ),
      const LinearGradient(
        colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
      ),
    ];

    final gradient = gradients[widget.index % gradients.length];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 IMAGE + TITLE OVERLAY
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: widget.activity.photoUrl != null &&
                          widget.activity.photoUrl!.isNotEmpty
                      ? Image.network(
                          widget.activity.photoUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Container(color: Colors.grey),
                ),

                // dark overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withOpacity(0.35),
                    ),
                  ),
                ),

                // title
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: IgnorePointer(
                    child: Text(
                      widget.activity.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // ❤️ / 🗑 button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: IconButton(
                      icon: Icon(
                        widget.isFavoritesView
                            ? Icons.delete
                            : (isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border),
                        color:
                            widget.isFavoritesView ? Colors.black : Colors.red,
                      ),
                      onPressed: widget.isFavoritesView
                          ? _deleteFavorite
                          : _toggleFavorite,
                    ),
                  ),
                ),
              ],
            ),

            // 📦 DESCRIPTION + ADDRESS (30% transparent panel)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // description
                  Text(
                    widget.activity.description,
                    style: const TextStyle(color: Colors.black87),
                  ),

                  const SizedBox(height: 10),

                  // 📍 address (NEW — clean + subtle)
                  if (widget.activity.address != null &&
                      widget.activity.address!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.black54),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.activity.address!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
