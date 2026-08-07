import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/planning_option.dart';
import '../models/trip_plan_draft.dart';
import '../models/trip_route.dart';

class TripPlanStorage {
  const TripPlanStorage();

  static const _key = 'saved_trip_plans';

  Future<void> save({
    required TripPlanDraft draft,
    required TripRoute route,
    required PlanningOption itinerary,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList(_key) ?? <String>[];
    final payload = jsonEncode({
      'id': itinerary.id,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      ...draft.toJson(),
      'route': route.toJson(),
      'itinerary': itinerary.toJson(),
    });
    saved.removeWhere((item) {
      try {
        return jsonDecode(item)['id'] == itinerary.id;
      } catch (_) {
        return false;
      }
    });
    saved.insert(0, payload);
    await preferences.setStringList(_key, saved.take(20).toList());
  }

  Future<List<Map<String, dynamic>>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_key) ?? const <String>[])
        .map((item) {
          try {
            return Map<String, dynamic>.from(jsonDecode(item) as Map);
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> delete(String id) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList(_key) ?? <String>[];
    saved.removeWhere((item) {
      try {
        return jsonDecode(item)['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await preferences.setStringList(_key, saved);
  }
}
