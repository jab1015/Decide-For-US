import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';

class FavoritesService {
  static const String key = "favorites";

  static Future<List<Activity>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(key) ?? [];

    return data.map((e) {
      final jsonMap = json.decode(e);
      return Activity.fromJson(jsonMap);
    }).toList();
  }

  static Future<void> addFavorite(Activity activity) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(key) ?? [];

    final updated = [
      ...current,
      json.encode(activity.toJson()),
    ];

    await prefs.setStringList(key, updated);
  }

  static Future<void> removeFavorite(Activity activity) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(key) ?? [];

    final updated = current.where((item) {
      final jsonMap = json.decode(item);
      return jsonMap['title'] != activity.title;
    }).toList();

    await prefs.setStringList(key, updated);
  }
}
