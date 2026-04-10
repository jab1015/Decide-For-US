import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const _cacheKey = "cached_location";

  /// 🚀 MAIN METHOD (FAST)
  static Future<String> getCityState() async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ RETURN CACHED VALUE INSTANTLY
    final cached = prefs.getString(_cacheKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // ❗ OTHERWISE FETCH + CACHE
    return await _fetchAndCacheLocation();
  }

  /// 🔄 OPTIONAL REFRESH
  static Future<String> refreshLocation() async {
    return await _fetchAndCacheLocation();
  }

  /// 🔧 FETCH LOCATION (NO NEW PACKAGES)
  static Future<String> _fetchAndCacheLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return "Jacksonville, FL";

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return "Jacksonville, FL";
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // ⚡ faster
      );

      // 🔥 FREE reverse geocode (same as your original)
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

      final result = "$city, $state";

      // ✅ CACHE IT
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, result);

      return result;
    } catch (e) {
      return "Jacksonville, FL";
    }
  }
}