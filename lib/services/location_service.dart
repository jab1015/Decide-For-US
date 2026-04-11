import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {

  // 📍 GET LAT/LNG
  static Future<Map<String, double>?> getLatLng() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return {
        "lat": position.latitude,
        "lng": position.longitude,
      };
    } catch (e) {
      return null;
    }
  }

  // 📍 CITY, STATE
  static Future<String?> getCityState() async {
    try {
      final coords = await getLatLng();
      if (coords == null) return null;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        coords["lat"]!,
        coords["lng"]!,
      );

      final place = placemarks.first;

      return "${place.locality}, ${place.administrativeArea}";
    } catch (e) {
      return null;
    }
  }

  // 📏 DISTANCE CALCULATION (MILES)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 3958.8; // Earth radius in miles

    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a =
        pow(sin(dLat / 2), 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            pow(sin(dLon / 2), 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  static double _deg2rad(double deg) {
    return deg * (pi / 180);
  }
}