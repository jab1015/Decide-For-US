import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity.dart';

class AIService {
  static Future<List<Activity>> getIdeas({
    String? group,
    String? budget,
    String? energy,
    bool isDateNight = false,
    List<String> history = const [],
  }) async {
    final response = await http.post(
      Uri.parse('https://your-api-endpoint.com/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "group": group,
        "budget": budget,
        "energy": energy,
        "dateNight": isDateNight,
        "history": history,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return (data as List)
          .map((e) => Activity.fromJson(e))
          .toList();
    } else {
      throw Exception("Failed to load ideas");
    }
  }
}