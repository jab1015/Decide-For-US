import 'planning_constraints.dart';
import 'planning_engine_request.dart';
import 'planning_location.dart';
import 'planning_mode.dart';

class TripPlanDraft {
  const TripPlanDraft({
    this.originLabel = 'Current location',
    this.destinationLabel = '',
    this.startsAt,
    this.endsAt,
    this.travelerCount = 2,
    this.budget = r'$500–$1,000',
    this.maxTravelMinutesBetweenStops = 120,
    this.interests = const [],
    this.exclusions = const [],
  });

  factory TripPlanDraft.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    List<String> parseStrings(Object? value) {
      if (value is! List) return const [];
      return value.map((item) => item.toString()).toList(growable: false);
    }

    return TripPlanDraft(
      originLabel: json['originLabel']?.toString() ?? 'Current location',
      destinationLabel: json['destinationLabel']?.toString() ?? '',
      startsAt: parseDate(json['startsAt']),
      endsAt: parseDate(json['endsAt']),
      travelerCount: (json['travelerCount'] as num?)?.round() ?? 2,
      budget: json['budget']?.toString() ?? r'$500–$1,000',
      maxTravelMinutesBetweenStops:
          (json['maxTravelMinutesBetweenStops'] as num?)?.round() ?? 120,
      interests: parseStrings(json['interests']),
      exclusions: parseStrings(json['exclusions']),
    );
  }

  final String originLabel;
  final String destinationLabel;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int travelerCount;
  final String budget;
  final int maxTravelMinutesBetweenStops;
  final List<String> interests;
  final List<String> exclusions;

  List<String> get validationErrors {
    final errors = <String>[];
    if (originLabel.trim().isEmpty) errors.add('Choose a starting point.');
    if (destinationLabel.trim().isEmpty) errors.add('Choose a destination.');
    if (startsAt == null || endsAt == null) {
      errors.add('Choose your trip dates.');
    } else if (endsAt!.isBefore(startsAt!)) {
      errors.add('The return date must be after the departure date.');
    }
    if (travelerCount < 1) errors.add('Add at least one traveler.');
    if (maxTravelMinutesBetweenStops < 30) {
      errors.add('Drive intervals must be at least 30 minutes.');
    }
    return errors;
  }

  bool get isValid => validationErrors.isEmpty;

  TripPlanDraft copyWith({
    String? originLabel,
    String? destinationLabel,
    DateTime? startsAt,
    DateTime? endsAt,
    int? travelerCount,
    String? budget,
    int? maxTravelMinutesBetweenStops,
    List<String>? interests,
    List<String>? exclusions,
  }) {
    return TripPlanDraft(
      originLabel: originLabel ?? this.originLabel,
      destinationLabel: destinationLabel ?? this.destinationLabel,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      travelerCount: travelerCount ?? this.travelerCount,
      budget: budget ?? this.budget,
      maxTravelMinutesBetweenStops:
          maxTravelMinutesBetweenStops ?? this.maxTravelMinutesBetweenStops,
      interests: interests ?? this.interests,
      exclusions: exclusions ?? this.exclusions,
    );
  }

  Map<String, dynamic> toJson() => {
    'originLabel': originLabel,
    'destinationLabel': destinationLabel,
    'startsAt': startsAt?.toIso8601String(),
    'endsAt': endsAt?.toIso8601String(),
    'travelerCount': travelerCount,
    'budget': budget,
    'maxTravelMinutesBetweenStops': maxTravelMinutesBetweenStops,
    'interests': interests,
    'exclusions': exclusions,
  };

  PlanningEngineRequest toPlanningRequest({
    required PlanningLocation origin,
    required PlanningLocation destination,
  }) {
    if (!isValid) {
      throw StateError(validationErrors.join(' '));
    }
    return PlanningEngineRequest(
      mode: PlanningMode.trip,
      origin: PlanningLocation(
        lat: origin.lat,
        lng: origin.lng,
        label: originLabel.trim(),
      ),
      destination: PlanningLocation(
        lat: destination.lat,
        lng: destination.lng,
        label: destinationLabel.trim(),
      ),
      startsAt: startsAt,
      endsAt: endsAt,
      constraints: PlanningConstraints(
        group: travelerCount == 1 ? 'Solo' : 'Travelers',
        budget: budget,
        energy: 'Medium',
        radiusMiles: 50,
        travelerCount: travelerCount,
        maxTravelMinutesBetweenStops: maxTravelMinutesBetweenStops,
        interests: interests,
        exclusions: exclusions,
      ),
    );
  }
}
