import '../models/activity.dart';
import 'dart:math';

class DecisionService {
  static final _activities = [

    Activity(
      title: "Romantic Dinner Night 🍷",
      description: "Dress up and go somewhere new for dinner.",
      group: "Couple",
      budget: "\$\$",
    ),

    Activity(
      title: "Game Night 🎲",
      description: "Play games and compete for fun.",
      group: "Friends",
      budget: "Free",
    ),

    Activity(
      title: "Family Movie Night 🍿",
      description: "Pick a movie everyone agrees on.",
      group: "Family",
      budget: "\$",
    ),

    Activity(
      title: "Solo Reset Walk 🌿",
      description: "Take a peaceful walk and clear your head.",
      group: "Solo",
      budget: "Free",
    ),

    Activity(
      title: "Dessert Crawl 🍰",
      description: "Hit multiple dessert spots in one night.",
      group: "Couple",
      budget: "\$",
    ),

  ];

  static List<Activity> getFiltered({
    String? group,
    String? budget,
  }) {
    List<Activity> results = _activities;

    if (group != null) {
      results = results.where((a) => a.group == group).toList();
    }

    if (budget != null) {
      results = results.where((a) => a.budget == budget).toList();
    }

    if (results.isEmpty) {
      results = _activities;
    }

    results.shuffle(Random());
    return results.take(2).toList();
  }
}