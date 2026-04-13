import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/activity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DecisionCard extends StatefulWidget {
  final Activity activity;
  final bool showFavorite;

  const DecisionCard({
    super.key,
    required this.activity,
    this.showFavorite = true,
  });

  @override
  State<DecisionCard> createState() => _DecisionCardState();
}

class _DecisionCardState extends State<DecisionCard> {
  bool isFavorite = false;

  // 🔥 GLOBAL ROTATION INDEX (changes per rebuild)
  static int globalSeed = DateTime.now().millisecondsSinceEpoch;

  // 🎨 COLOR SETS
  final List<List<Color>> gradients = [
    [Colors.green, Colors.greenAccent],
    [Colors.orange, Colors.deepOrangeAccent],
    [Colors.blue, Colors.lightBlueAccent],
    [Colors.pink, Colors.pinkAccent],
    [Colors.purple, Colors.deepPurpleAccent],
  ];

  @override
  void initState() {
    super.initState();
    checkFavorite();
  }

  Future<void> checkFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList("favorites") ?? [];

    setState(() {
      isFavorite =
          favs.any((f) => jsonDecode(f)['title'] == widget.activity.title);
    });
  }

  Future<void> toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList("favorites") ?? [];

    final activityJson = jsonEncode({
      "title": widget.activity.title,
      "description": widget.activity.description,
      "address": widget.activity.address,
      "lat": widget.activity.lat,
      "lng": widget.activity.lng,
    });

    if (isFavorite) {
      favs.removeWhere((f) => jsonDecode(f)['title'] == widget.activity.title);
    } else {
      favs.add(activityJson);
    }

    await prefs.setStringList("favorites", favs);

    setState(() {
      isFavorite = !isFavorite;
    });
  }

  // 🔥 NEW COLOR LOGIC
  List<Color> getGradient() {
    final base = (widget.activity.title.hashCode + globalSeed).abs();

    final index = base % gradients.length;

    return gradients[index];
  }

  @override
  Widget build(BuildContext context) {
    final colors = getGradient();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  colors[0].withOpacity(0.35),
                  colors[1].withOpacity(0.35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.activity.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (widget.showFavorite)
                        GestureDetector(
                          onTap: toggleFavorite,
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getVibe(widget.activity.description),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.activity.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.activity.address,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getVibe(String description) {
    final d = description.toLowerCase();

    if (d.contains("walk") || d.contains("scenic")) {
      return "🌅 Scenic & Relaxed";
    }
    if (d.contains("cozy") || d.contains("quiet")) {
      return "✨ Cozy & Intimate";
    }
    if (d.contains("fun") || d.contains("explore")) {
      return "🎉 Fun & Playful";
    }
    if (d.contains("dinner")) {
      return "🍽 Classic Date Night";
    }

    return "💫 Something Different";
  }
}
