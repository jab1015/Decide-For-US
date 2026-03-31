import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/activity.dart';

class AIService {

  static Future<String> getUserLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return "United States";
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    /// 🔥 Convert GPS → readable area (simple version)
    final lat = position.latitude.toStringAsFixed(3);
    final lng = position.longitude.toStringAsFixed(3);

    return "Near $lat,$lng";
  }

  static Future<List<Activity>> getIdeas({
    String? group,
    String? budget,
    String? energy,
    bool? isDateNight,
    List<String>? history,
  }) async {

    final location = await getUserLocation();

    final url = Uri.parse(
      "https://us-central1-decide-for-us-792bc.cloudfunctions.net/getIdeas",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "group": group,
        "budget": budget,
        "energy": energy,
        "isDateNight": isDateNight,
        "history": history ?? [],
        "location": location,
      }),
    );

    final decoded = jsonDecode(response.body);

    final List<dynamic> data =
        decoded is List ? decoded : [decoded];

    return data.map<Activity>((e) {
      return Activity(
        title: e['title'] ?? '',
        description: e['description'] ?? '',
        group: e['group'] ?? '',
        budget: e['budget'] ?? '',
      );
    }).toList();
  }
}