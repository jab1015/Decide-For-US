class PlanningConstraints {
  const PlanningConstraints({
    this.group,
    this.budget,
    this.energy,
    this.radiusMiles = 25,
    this.travelerCount = 1,
    this.maxTravelMinutesBetweenStops,
    this.interests = const [],
    this.exclusions = const [],
  });

  final String? group;
  final String? budget;
  final String? energy;
  final int radiusMiles;
  final int travelerCount;
  final int? maxTravelMinutesBetweenStops;
  final List<String> interests;
  final List<String> exclusions;

  factory PlanningConstraints.fromJson(Map<String, dynamic> json) {
    return PlanningConstraints(
      group: json['group']?.toString(),
      budget: json['budget']?.toString(),
      energy: json['energy']?.toString(),
      radiusMiles: (json['radiusMiles'] as num?)?.toInt() ?? 25,
      travelerCount: (json['travelerCount'] as num?)?.toInt() ?? 1,
      maxTravelMinutesBetweenStops:
          (json['maxTravelMinutesBetweenStops'] as num?)?.toInt(),
      interests: _stringList(json['interests']),
      exclusions: _stringList(json['exclusions']),
    );
  }

  Map<String, dynamic> toJson() => {
    'group': group,
    'budget': budget,
    'energy': energy,
    'radiusMiles': radiusMiles,
    'travelerCount': travelerCount,
    'maxTravelMinutesBetweenStops': maxTravelMinutesBetweenStops,
    'interests': interests,
    'exclusions': exclusions,
  };

  static List<String> _stringList(dynamic value) {
    return value is List
        ? value.whereType<Object>().map((item) => item.toString()).toList()
        : const [];
  }
}
