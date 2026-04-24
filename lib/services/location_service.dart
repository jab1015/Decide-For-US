import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Map<String, double>?> getLatLng() async {
    try {
      // 🔥 Check if GPS is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("❌ GPS is OFF");
        return null;
      }

      // 🔥 Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        print("❌ Permission denied");
        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        print("❌ Permission permanently denied");
        return null;
      }

      // 🔥 Force fresh GPS (NOT cached)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 10),
      );

      print("📍 REAL LOCATION:");
      print("LAT: ${position.latitude}");
      print("LNG: ${position.longitude}");

      // 🚨 Detect emulator default (San Francisco)
      if (position.latitude == 37.7749 && position.longitude == -122.4194) {
        print("⚠️ USING EMULATOR DEFAULT LOCATION (San Francisco)");
      }

      return {
        "lat": position.latitude,
        "lng": position.longitude,
      };
    } catch (e) {
      print("❌ Location error: $e");
      return null;
    }
  }
}
