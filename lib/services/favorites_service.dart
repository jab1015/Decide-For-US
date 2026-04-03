// TEMPORARY STUB (Firestore disabled)

class FavoritesService {
  static Future<void> savePlan(Map<String, dynamic> plan) async {
    // no-op
  }

  static Future<void> removePlan(String id) async {
    // no-op
  }

  static Future<List<Map<String, dynamic>>> getSavedPlans() async {
    return [];
  }

  static Future<bool> isSaved(String id) async {
    return false;
  }
}