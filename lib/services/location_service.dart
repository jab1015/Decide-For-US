import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Map<String, double>?> getLatLng() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 10),
      );

      return {'lat': position.latitude, 'lng': position.longitude};
    } catch (_) {
      return null;
    }
  }
}
