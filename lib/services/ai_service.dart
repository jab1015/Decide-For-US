import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity.dart';

class AIService {
  static const String baseUrl =
      "https://getideas-33mweuhvmq-uc.a.run.app/";

  static Future<List<Activity>> getIdeas({
    String? group,
    String? budget,
    String? energy,
    bool? isDateNight,
    List<String>? history,
    String? location, // 🔥 NEW
  }) async {
    history ??= [];

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
        "history": history,
        "location": location ?? "Jacksonville, FL", // 🔥
      }),
    );

    final decoded = jsonDecode(response.body);
    final List<dynamic> data =
        decoded is List ? decoded : [decoded];

    return data.map<Activity>((e) => Activity.fromJson(e)).toList();
  }
}