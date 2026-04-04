import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity.dart';

class AIService {
  static Future<List<Activity>> getIdeas({
    String? group,
    String? budget,
    String? energy,
    bool? isDateNight,
    List<String>? history,
  }) async {
    final url = Uri.parse(
      "https://us-central1-decide-for-us-792bc.cloudfunctions.net/getIdeas",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "group": group,
          "budget": budget,
          "energy": energy,
          "isDateNight": isDateNight,
          "history": history ?? [],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("API failed");
      }

      final decoded = jsonDecode(response.body);

      /// 🔥 HANDLE BOTH LIST + SINGLE OBJECT (just in case)
      final List<dynamic> data =
          decoded is List ? decoded : [decoded];

      final ideas = data.map<Activity>((e) {
        return Activity(
          title: e['title'] ?? '',
          description: e['description'] ?? '',
          group: e['group'] ?? '',
          budget: e['budget'] ?? '',
        );
      }).toList();

      /// 🔥 RETURN ALL RESULTS (NO LIMITING)
      return ideas;

    } catch (e) {
      return [
        Activity(
          title: "Error",
          description: "Unable to load ideas.",
          group: "Error",
          budget: "Error",
        )
      ];
    }
  }
}