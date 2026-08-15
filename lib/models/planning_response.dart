import 'activity.dart';
import 'planning_mode.dart';
import 'planning_option.dart';
import 'planning_stop.dart';

class PlanningResponse {
  const PlanningResponse({
    required this.mode,
    required this.options,
    required this.createdAt,
  });

  final PlanningMode mode;
  final List<PlanningOption> options;
  final DateTime createdAt;

  List<Activity> get activities => [
    for (final option in options) ...option.activities,
  ];

  factory PlanningResponse.fromActivities({
    required PlanningMode mode,
    required List<Activity> activities,
    DateTime? createdAt,
  }) {
    final options = <PlanningOption>[];
    for (var index = 0; index < activities.length; index += 2) {
      final end = index + 2 < activities.length
          ? index + 2
          : activities.length;
      final optionActivities = activities.sublist(index, end);
      final optionNumber = options.length + 1;
      options.add(
        PlanningOption(
          id: 'option-$optionNumber',
          title: 'Option $optionNumber',
          stops: [
            for (var stopIndex = 0;
                stopIndex < optionActivities.length;
                stopIndex++)
              PlanningStop(
                sequence: stopIndex,
                activity: optionActivities[stopIndex],
              ),
          ],
        ),
      );
    }
    return PlanningResponse(
      mode: mode,
      options: options,
      createdAt: createdAt ?? DateTime.now().toUtc(),
    );
  }

  factory PlanningResponse.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'];
    return PlanningResponse(
      mode: PlanningMode.fromWireName(json['mode']?.toString()),
      options: optionsJson is List
          ? optionsJson
                .whereType<Map>()
                .map(
                  (option) => PlanningOption.fromJson(
                    Map<String, dynamic>.from(option),
                  ),
                )
                .toList()
          : const [],
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.wireName,
    'options': options.map((option) => option.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };
}
