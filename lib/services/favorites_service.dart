import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';

class FavoritesService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get userId {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return user.uid;
  }

  static CollectionReference get _savedPlans =>
      _firestore.collection("saved_plans");

  /// 🔥 LOCAL STORAGE KEY
  static const String localKey = "local_favorites";

  /// 🔥 SAVE TO LOCAL
  static Future<void> _saveLocal(List<Activity> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => jsonEncode({
          "title": e.title,
          "description": e.description,
          "group": e.group,
          "budget": e.budget,
        })).toList();

    await prefs.setStringList(localKey, jsonList);
  }

  /// 🔥 LOAD LOCAL
  static Future<List<Activity>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(localKey) ?? [];

    return data.map((e) {
      final json = jsonDecode(e);
      return Activity(
        title: json['title'],
        description: json['description'],
        group: json['group'],
        budget: json['budget'],
      );
    }).toList();
  }

  /// 🔥 GET FAVORITES (FIREBASE → FALLBACK LOCAL)
  static Future<List<Activity>> getFavorites() async {
    try {
      final snapshot = await _savedPlans
          .where("userId", isEqualTo: userId)
          .get();

      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return Activity(
          title: data['title'],
          description: data['description'],
          group: data['group'],
          budget: data['budget'],
        );
      }).toList();

      /// 🔥 SAVE LOCAL COPY
      await _saveLocal(list);

      return list;
    } catch (e) {
      print("⚠️ FIREBASE FAILED, USING LOCAL");
      return await _loadLocal();
    }
  }

  /// 🔥 TOGGLE FAVORITE
  static Future<void> toggle(Activity activity) async {
    final existing = await _savedPlans
        .where("userId", isEqualTo: userId)
        .where("title", isEqualTo: activity.title)
        .get();

    List<Activity> currentLocal = await _loadLocal();

    if (existing.docs.isNotEmpty) {
      /// REMOVE
      for (var doc in existing.docs) {
        await doc.reference.delete();
      }

      currentLocal.removeWhere((e) => e.title == activity.title);
    } else {
      /// ADD
      await _savedPlans.add({
        "userId": userId,
        "title": activity.title,
        "description": activity.description,
        "group": activity.group,
        "budget": activity.budget,
        "createdAt": FieldValue.serverTimestamp(),
      });

      currentLocal.add(activity);
    }

    /// 🔥 UPDATE LOCAL
    await _saveLocal(currentLocal);
  }

  /// 🔥 CHECK FAVORITE
  static Future<bool> isFavorite(Activity activity) async {
    final snapshot = await _savedPlans
        .where("userId", isEqualTo: userId)
        .where("title", isEqualTo: activity.title)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}