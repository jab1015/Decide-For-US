import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';

class FavoritesService {
  static const _key = "favorites";

  static Future<List<Activity>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);

    if (data == null) return [];

    final decoded = jsonDecode(data) as List;
    return decoded.map((e) => Activity.fromJson(e)).toList();
  }

  static Future<void> saveFavorites(List<Activity> list) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static Future<void> toggleFavorite(Activity activity) async {
    final favorites = await getFavorites();

    final exists = favorites.any((a) => a.title == activity.title);

    if (exists) {
      favorites.removeWhere((a) => a.title == activity.title);
    } else {
      favorites.add(activity);
    }

    await saveFavorites(favorites);
  }

  static Future<bool> isFavorite(Activity activity) async {
    final favorites = await getFavorites();
    return favorites.any((a) => a.title == activity.title);
  }
}