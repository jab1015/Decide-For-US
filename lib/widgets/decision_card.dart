import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/activity.dart';
import '../services/location_service.dart';

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
  double? distance;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    calculateDistance();
    checkFavorite();
  }

  Future<void> calculateDistance() async {
    final coords = await LocationService.getLatLng();

    if (coords != null &&
        widget.activity.lat != 0 &&
        widget.activity.lng != 0) {
      final d = LocationService.calculateDistance(
        coords['lat']!,
        coords['lng']!,
        widget.activity.lat,
        widget.activity.lng,
      );

      setState(() => distance = d);
    }
  }

  Future<void> checkFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList("favorites") ?? [];

    setState(() {
      isFavorite = favs.contains(widget.activity.title);
    });
  }

  Future<void> toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList("favorites") ?? [];

    final item = jsonEncode({
      "title": widget.activity.title,
      "description": widget.activity.description,
      "address": widget.activity.address,
      "lat": widget.activity.lat,
      "lng": widget.activity.lng,
    });

    if (isFavorite) {
      favs.removeWhere((e) => e.contains(widget.activity.title));
    } else {
      favs.add(item);
    }

    await prefs.setStringList("favorites", favs);

    setState(() => isFavorite = !isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.activity.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(height: 6),

              Text(widget.activity.description),

              const SizedBox(height: 10),

              Text(
                distance != null
                    ? "${widget.activity.address} • ${distance!.toStringAsFixed(1)} miles away"
                    : widget.activity.address,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black54),
              ),
            ],
          ),

          if (widget.showFavorite)
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: toggleFavorite,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}