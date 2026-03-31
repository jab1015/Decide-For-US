import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/favorites_service.dart';

class DecisionCard extends StatefulWidget {
  final Activity activity;

  const DecisionCard({super.key, required this.activity});

  @override
  State<DecisionCard> createState() => _DecisionCardState();
}

class _DecisionCardState extends State<DecisionCard> {
  bool isFavorite = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkFavorite();
  }

  Future<void> checkFavorite() async {
    final fav = await FavoritesService.isFavorite(widget.activity);
    setState(() {
      isFavorite = fav;
      isLoading = false;
    });
  }

  Future<void> toggleFavorite() async {
    print("❤️ TOGGLE CLICKED: ${widget.activity.title}");

    await FavoritesService.toggle(widget.activity);

    final fav = await FavoritesService.isFavorite(widget.activity);

    print("✅ FAVORITE STATUS NOW: $fav");

    setState(() {
      isFavorite = fav;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE + HEART
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.activity.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: toggleFavorite,
                    ),
            ],
          ),

          const SizedBox(height: 8),

          /// DESCRIPTION
          Text(widget.activity.description),

          const SizedBox(height: 10),

          /// META
          Row(
            children: [
              Text("👥 ${widget.activity.group}"),
              const SizedBox(width: 10),
              Text("💰 ${widget.activity.budget}"),
            ],
          ),
        ],
      ),
    );
  }
}