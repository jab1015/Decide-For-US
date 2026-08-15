import 'activity.dart';
import 'planning_location.dart';

class TripDiscoveryZone {
  const TripDiscoveryZone({
    required this.index,
    required this.location,
    required this.candidates,
  });

  factory TripDiscoveryZone.fromJson(Map<String, dynamic> json) {
    final rawCandidates = json['candidates'];
    return TripDiscoveryZone(
      index: (json['index'] as num?)?.round() ?? 0,
      location: PlanningLocation(
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        label: 'Discovery zone ${((json['index'] as num?)?.round() ?? 0) + 1}',
      ),
      candidates: rawCandidates is List
          ? rawCandidates
              .whereType<Map>()
              .map(
                (value) => Activity.fromJson(
                  Map<String, dynamic>.from(value),
                ),
              )
              .toList(growable: false)
          : const [],
    );
  }

  final int index;
  final PlanningLocation location;
  final List<Activity> candidates;
}
