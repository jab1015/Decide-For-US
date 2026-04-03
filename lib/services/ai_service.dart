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
      final List data = jsonDecode(response.body);

      return data
          .map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("Failed to load ideas");
    }
  }
}