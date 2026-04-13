import 'package:flutter/material.dart';
import '../models/activity.dart';

class DecisionCard extends StatelessWidget {
  final Activity activity;
  final bool showFavorite;
  final int index;

  const DecisionCard({
    super.key,
    required this.activity,
    this.showFavorite = true,
    required this.index,
  });

  static final List<List<Color>> gradients = [
    [Colors.green, Colors.greenAccent],
    [Colors.orange, Colors.deepOrangeAccent],
    [Colors.blue, Colors.lightBlueAccent],
    [Colors.pink, Colors.pinkAccent],
    [Colors.purple, Colors.deepPurpleAccent],
  ];

  List<Color> getGradient() {
    return gradients[index % gradients.length];
  }

  // 🔥 FORCE DIFFERENT VISUAL CROPPING
  Alignment getImageAlignment() {
    final positions = [
      Alignment.center,
      Alignment.topCenter,
      Alignment.bottomCenter,
      Alignment.centerLeft,
      Alignment.centerRight,
    ];

    return positions[index % positions.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = getGradient();
    final alignment = getImageAlignment();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // 🔥 IMAGE WITH DIFFERENT CROP PER CARD
            if (activity.photoUrl != null)
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Image.network(
                  activity.photoUrl!,
                  fit: BoxFit.cover,
                  alignment: alignment, // 🔥 KEY DIFFERENCE
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      "https://images.unsplash.com/photo-1504674900247-0877df9cc836",
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),

            // 🔥 STRONG COLOR OVERLAY (DIFFERENT PER CARD)
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors[0].withOpacity(0.55),
                    colors[1].withOpacity(0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // 🔥 TEXT PANEL
            Container(
              margin: const EdgeInsets.only(top: 140),
              decoration: BoxDecoration(
                color: colors[0].withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.description,
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(activity.address)),
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
