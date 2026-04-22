import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/activity.dart';

class AIService {
  static const String baseUrl = "https://getideas-33mweuhvmq-uc.a.run.app";

  static Future<List<Activity>> getIdeas({
    String? group,
    String? budget,
    String? energy,
    bool isDateNight = false,
    double? lat,
    double? lng,
    int radius = 25,
  }) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      if (group != null) "group": group,
      if (budget != null) "budget": budget,
      if (energy != null) "energy": energy,
      "isDateNight": isDateNight.toString(),
      if (lat != null) "lat": lat.toString(),
      if (lng != null) "lng": lng.toString(),
      "radius": radius.toString(),
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch ideas");
    }

    final List data = jsonDecode(response.body);

    // 🔥 FIX: use fromJson so id is included
    return data.map((item) => Activity.fromJson(item)).toList();
  }
}
