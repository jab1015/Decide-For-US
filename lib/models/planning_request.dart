class PlanningRequest {
  const PlanningRequest({
    required this.group,
    required this.budget,
    required this.energy,
    required this.isDateNight,
    required this.lat,
    required this.lng,
    required this.radiusMiles,
  });

  final String? group;
  final String? budget;
  final String? energy;
  final bool isDateNight;
  final double lat;
  final double lng;
  final int radiusMiles;

  Map<String, dynamic> toJson() => {
    'group': group,
    'budget': budget,
    'energy': energy,
    'isDateNight': isDateNight,
    'lat': lat,
    'lng': lng,
    'radius': radiusMiles,
  };
}
