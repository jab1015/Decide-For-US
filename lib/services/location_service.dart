import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static bool _hasRequestedPermission = false;

  /// 🔥 MAIN METHOD (used by your app)
  static Future<String?> getCityState() async {
    try {
      // Request permission only once and only when explicitly called
      if (!_hasRequestedPermission) {
        _hasRequestedPermission = true;

        LocationPermission permission =
            await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final city = place.locality ?? '';
        final state = place.administrativeArea ?? '';

        if (city.isNotEmpty && state.isNotEmpty) {
          return "$city, $state";
        }

        return city.isNotEmpty ? city : state;
      }
    } catch (_) {}

    return null;
  }
}