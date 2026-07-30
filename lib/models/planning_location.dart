class PlanningLocation {
  const PlanningLocation({
    required this.lat,
    required this.lng,
    this.label,
  });

  final double lat;
  final double lng;
  final String? label;

  factory PlanningLocation.fromJson(Map<String, dynamic> json) {
    return PlanningLocation(
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      label: json['label']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'label': label,
  };
}
