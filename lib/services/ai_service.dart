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
    List<String>? history,
    String? location,
  }) async {
    history ??= [];

    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "group": group,
              "budget": budget,
              "energy": energy,
              "isDateNight": isDateNight,
              "history": history,
              "location": location ?? "Unknown",
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception("Backend error");
      }

      final decoded = jsonDecode(response.body);

      final List<dynamic> data =
          decoded is List ? decoded : [decoded];

      return data
          .map<Activity>((e) => Activity.fromJson(e))
          .toList();
    } catch (e) {
      print("AI ERROR: $e");

      // 🔥 CLEAN FALLBACK (NO LOCATION SERVICE HERE)
      return [
        Activity(
          title: "Try a Local Coffee Spot ☕",
          description: "Find a cozy café nearby and relax.",
          group: group ?? "Any",
          budget: budget ?? "Any",
          address: location ?? "",
        ),
        Activity(
          title: "Go for a Scenic Walk 🌿",
          description: "Enjoy fresh air and explore your area.",
          group: group ?? "Any",
          budget: budget ?? "Free",
          address: location ?? "",
        ),
      ];
    }
  }
}