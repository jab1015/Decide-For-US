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
  bool isFav = false;

  @override
  void initState() {
    super.initState();
    loadFavorite();
  }

  void loadFavorite() async {
    final fav = await FavoritesService.isFavorite(widget.activity);
    setState(() => isFav = fav);
  }

  void toggleFavorite() async {
    await FavoritesService.toggleFavorite(widget.activity);
    setState(() => isFav = !isFav);
  }

  Color baseColor() {
    final colors = [
      const Color(0xFF7B61FF),
      const Color(0xFFFF6B6B),
      const Color(0xFF00C9A7),
      const Color(0xFFFFA726),
    ];
    return colors[widget.activity.title.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final color = baseColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color.withOpacity(0.9),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                a.description,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 14),

              if (a.address != null)
                Text(
                  a.address!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
            ],
          ),

          // ❤️ FIXED FAVORITE BUTTON
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: toggleFavorite,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: color,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}