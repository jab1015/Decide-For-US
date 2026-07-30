import 'activity.dart';

class PlanningStop {
  const PlanningStop({
    required this.sequence,
    required this.activity,
    this.startsAt,
    this.durationMinutes,
    this.travelMinutesFromPrevious,
    this.estimatedCostCents,
  });

  final int sequence;
  final Activity activity;
  final DateTime? startsAt;
  final int? durationMinutes;
  final int? travelMinutesFromPrevious;
  final int? estimatedCostCents;

  factory PlanningStop.fromJson(Map<String, dynamic> json) {
    final activityJson = json['activity'];
    return PlanningStop(
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      activity: Activity.fromJson(
        activityJson is Map
            ? Map<String, dynamic>.from(activityJson)
            : const <String, dynamic>{},
      ),
      startsAt: DateTime.tryParse(json['startsAt']?.toString() ?? ''),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      travelMinutesFromPrevious: (json['travelMinutesFromPrevious'] as num?)
          ?.toInt(),
      estimatedCostCents: (json['estimatedCostCents'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'sequence': sequence,
    'activity': activity.toJson(),
    'startsAt': startsAt?.toIso8601String(),
    'durationMinutes': durationMinutes,
    'travelMinutesFromPrevious': travelMinutesFromPrevious,
    'estimatedCostCents': estimatedCostCents,
  };
}
