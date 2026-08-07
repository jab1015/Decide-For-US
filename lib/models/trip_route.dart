import 'planning_location.dart';

class TripRoute {
  const TripRoute({
    required this.origin,
    required this.destination,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.encodedPolyline,
    this.corridorPoints = const [],
  });

  factory TripRoute.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['corridorPoints'];
    return TripRoute(
      origin: PlanningLocation.fromJson(
        Map<String, dynamic>.from(json['origin'] as Map),
      ),
      destination: PlanningLocation.fromJson(
        Map<String, dynamic>.from(json['destination'] as Map),
      ),
      distanceMeters: (json['distanceMeters'] as num).round(),
      durationSeconds: (json['durationSeconds'] as num).round(),
      encodedPolyline: json['encodedPolyline']?.toString() ?? '',
      corridorPoints: rawPoints is List
          ? rawPoints
              .whereType<Map>()
              .map(
                (value) => PlanningLocation.fromJson(
                  Map<String, dynamic>.from(value),
                ),
              )
              .toList(growable: false)
          : const [],
    );
  }

  final PlanningLocation origin;
  final PlanningLocation destination;
  final int distanceMeters;
  final int durationSeconds;
  final String encodedPolyline;
  final List<PlanningLocation> corridorPoints;

  double get distanceMiles => distanceMeters / 1609.344;

  Duration get duration => Duration(seconds: durationSeconds);

  String get distanceLabel => '${distanceMiles.round()} miles';

  String get durationLabel {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours hr';
    return '$hours hr $minutes min';
  }

  Map<String, dynamic> toJson() => {
        'origin': origin.toJson(),
        'destination': destination.toJson(),
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
        'encodedPolyline': encodedPolyline,
        'corridorPoints': corridorPoints.map((point) => point.toJson()).toList(),
      };
}
