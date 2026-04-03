// TEMPORARY STUB (Firestore disabled but app-compatible)

class FavoritesService {
  static final Set<String> _favorites = {};

  static Future<void> toggle(dynamic activity) async {
    final id = activity.toString();

    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
  }

  static Future<bool> isFavorite(dynamic activity) async {
    final id = activity.toString();
    return _favorites.contains(id);
  }

  static Future<List<dynamic>> getFavorites() async {
    return _favorites.toList();
  }

  // Optional compatibility methods
  static Future<void> savePlan(Map<String, dynamic> plan) async {}

  static Future<void> removePlan(String id) async {}

  static Future<List<Map<String, dynamic>>> getSavedPlans() async {
    return [];
  }

  static Future<bool> isSaved(String id) async {
    return false;
  }
}