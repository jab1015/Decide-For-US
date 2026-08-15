import 'activity.dart';
import 'planning_stop.dart';

class PlanningOption {
  const PlanningOption({
    required this.id,
    required this.title,
    required this.stops,
    this.summary,
    this.estimatedCostCents,
    this.totalTravelMinutes,
  });

  final String id;
  final String title;
  final String? summary;
  final List<PlanningStop> stops;
  final int? estimatedCostCents;
  final int? totalTravelMinutes;

  List<Activity> get activities => [
    for (final stop in stops) stop.activity,
  ];

  factory PlanningOption.fromJson(Map<String, dynamic> json) {
    final stopsJson = json['stops'];
    return PlanningOption(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString(),
      stops: stopsJson is List
          ? stopsJson
                .whereType<Map>()
                .map(
                  (stop) => PlanningStop.fromJson(
                    Map<String, dynamic>.from(stop),
                  ),
                )
                .toList()
          : const [],
      estimatedCostCents: (json['estimatedCostCents'] as num?)?.toInt(),
      totalTravelMinutes: (json['totalTravelMinutes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'stops': stops.map((stop) => stop.toJson()).toList(),
    'estimatedCostCents': estimatedCostCents,
    'totalTravelMinutes': totalTravelMinutes,
  };
}
