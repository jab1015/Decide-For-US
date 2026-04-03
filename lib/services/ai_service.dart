import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class AIService {
  static Future<Map<String, dynamic>> getDecision() async {
    try {
      // Request permission
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception("Location permission denied");
      }

      // Get location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final url = Uri.parse("YOUR_API_ENDPOINT_HERE");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "lat": position.latitude,
          "lng": position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("API failed");
      }
    } catch (e) {
      return {
        "option1": "Dinner and a movie",
        "option2": "Go for a walk"
      };
    }
  }
}