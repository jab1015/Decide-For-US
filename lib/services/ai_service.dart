import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity.dart';

class AIService {
  static Future<List<Activity>> getIdeas({
    String? group,
    String? budget,
    String? energy,
    bool? isDateNight,
    String? location,
    List<String>? history,
    double? lat,
    double? lng,
    int? radius,
  }) async {
    try {
      final url = Uri.parse(
        "https://us-central1-decide-for-us-792bc.cloudfunctions.net/getIdeas",
      );

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "group": group,
              "budget": budget,
              "energy": energy,
              "isDateNight": isDateNight,
              "location": location,
              "history": history ?? [],
              "lat": lat,
              "lng": lng,
              "radius": radius ?? 50,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print("🌐 STATUS: ${response.statusCode}");
      print("🌐 BODY: ${response.body}");

      if (response.statusCode != 200) {
        return [
          Activity(
            title: "Server error",
            description: "Please try again.",
            address: "",
            lat: 0, // ✅ REQUIRED
            lng: 0, // ✅ REQUIRED
          )
        ];
      }

      final List data = jsonDecode(response.body);

      return data.map((e) => Activity.fromJson(e)).toList();
    } catch (e) {
      print("❌ API ERROR: $e");

      return [
        Activity(
          title: "Connection issue",
          description: "Check your internet or try again.",
          address: "",
          lat: 0, // ✅ REQUIRED
          lng: 0, // ✅ REQUIRED
        )
      ];
    }
  }
}