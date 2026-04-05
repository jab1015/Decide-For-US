import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity.dart';

class AIService {
  /// 🔥 YOUR DEPLOYED CLOUD RUN URL (NO /getIdeas)
  static const String baseUrl =
      "https://getideas-33mweuhvmq-uc.a.run.app/";

  static Future<List<Activity>> getIdeas({
    String? group,
    String? budget,
    String? energy,
    bool? isDateNight,
    List<String>? history,
  }) async {
    try {
      print("🚀 CALLING BACKEND...");
      print("Filters → group:$group budget:$budget energy:$energy");

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "group": group,
          "budget": budget,
          "energy": energy,
          "isDateNight": isDateNight,
          "history": history ?? [],
          "location": "Jacksonville, FL" // 🔥 TEMP (we'll auto-detect later)
        }),
      );

      print("📡 STATUS: ${response.statusCode}");
      print("📦 RAW RESPONSE:");
      print(response.body);

      if (response.statusCode != 200) {
        throw Exception("Backend error: ${response.body}");
      }

      final decoded = jsonDecode(response.body);

      final List<dynamic> data =
          decoded is List ? decoded : [decoded];

      final results = data.map<Activity>((e) {
        return Activity(
          title: e['title'] ?? "No Title",
          description: e['description'] ?? "",
          group: e['group'] ?? group ?? "",
          budget: e['budget'] ?? budget ?? "",
        );
      }).toList();

      if (results.isEmpty) {
        throw Exception("No results returned");
      }

      return results;

    } catch (e) {
      print("❌ AI SERVICE ERROR: $e");

      return [
        Activity(
          title: "Something went wrong",
          description: "Try again in a moment.",
          group: "Error",
          budget: "Error",
        )
      ];
    }
  }
}