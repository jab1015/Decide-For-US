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
              "location": location ?? "Jacksonville, FL",
            }),
          )
          .timeout(const Duration(seconds: 15));

      /// 🔥 DEBUG (keep this for now)
      print("AI STATUS: ${response.statusCode}");
      print("AI BODY: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Backend error: ${response.statusCode}");
      }

      final decoded = jsonDecode(response.body);

      final List<dynamic> data =
          decoded is List ? decoded : [decoded];

      return data
          .map<Activity>((e) => Activity.fromJson(e))
          .toList();

    } catch (e) {
      print("AI ERROR: $e");

      /// 🔥 FAILSAFE (prevents infinite loading)
      return [
        Activity(
          title: "Something went wrong",
          description: "Please try again.",
          group: "Error",
          budget: "Error",
          address: "",
        )
      ];
    }
  }
}