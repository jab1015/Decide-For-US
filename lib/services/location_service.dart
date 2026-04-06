import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static Future<String> getCityState() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return "Jacksonville, FL"; // fallback
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return "Jacksonville, FL";
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    /// 🔥 Reverse geocode using OpenStreetMap (FREE)
    final url =
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}";

    final response = await http.get(Uri.parse(url));

    final data = jsonDecode(response.body);

    final address = data["address"];

    final city = address["city"] ??
        address["town"] ??
        address["village"] ??
        "Unknown";

    final state = address["state"] ?? "";

    return "$city, $state";
  }
}