import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity.dart';

class AIService {
  static const String baseUrl =
      "https://us-central1-decide-for-us-792bc.cloudfunctions.net/getIdeas";

  static Future<List<Activity>> getIdeas({
    String? group,
    String? budget,
    String? energy,
    bool? isDateNight,
    double? lat,
    double? lng,
    int? radius,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "group": group,
          "budget": budget,
          "energy": energy,
          "isDateNight": isDateNight,
          "lat": lat,
          "lng": lng,
          "radius": radius,
        }),
      );

      // 🔥 LOG EVERYTHING
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Bad response");
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception("Invalid format");
      }

      // 🔥 IMPORTANT: DO NOT FALL BACK SILENTLY
      return decoded.map((e) => Activity.fromJson(e)).toList();
    } catch (e) {
      print("AIService ERROR: $e");

      // 🚨 RETURN EMPTY — NOT GENERIC FAKE DATA
      return [];
    }
  }
}
