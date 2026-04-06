import 'package:flutter/material.dart';
import '../models/activity.dart';

class DecisionCard extends StatelessWidget {
  final Activity activity;

  const DecisionCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(activity.description),

          const SizedBox(height: 10),

          /// 🔥 ADDRESS (THIS WILL NOW WORK)
          if (activity.address.isNotEmpty)
            Text(
              "📍 ${activity.address}",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

          const SizedBox(height: 10),

          Text("👥 ${activity.group}   💰 ${activity.budget}"),
        ],
      ),
    );
  }
}