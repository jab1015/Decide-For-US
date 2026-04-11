import 'dart:math';

class DistanceHelper {
  static double calculateMiles(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 3958.8;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;
}