import 'planning_constraints.dart';
import 'planning_location.dart';
import 'planning_mode.dart';
import 'planning_request.dart';

class PlanningEngineRequest {
  const PlanningEngineRequest({
    required this.mode,
    required this.origin,
    required this.constraints,
    this.destination,
    this.startsAt,
    this.endsAt,
    this.dateOccasion,
    this.dateStyle,
    this.dateTiming,
  });

  final PlanningMode mode;
  final PlanningLocation origin;
  final PlanningLocation? destination;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final PlanningConstraints constraints;
  final String? dateOccasion;
  final String? dateStyle;
  final String? dateTiming;

  factory PlanningEngineRequest.fromRecommendation(PlanningRequest request) {
    return PlanningEngineRequest(
      mode: request.isDateNight
          ? PlanningMode.dateNight
          : PlanningMode.quickDecision,
      origin: PlanningLocation(lat: request.lat, lng: request.lng),
      constraints: PlanningConstraints(
        group: request.group,
        budget: request.budget,
        energy: request.energy,
        radiusMiles: request.radiusMiles,
        travelerCount: request.group == 'Couple' ? 2 : 1,
      ),
      dateOccasion: request.dateOccasion,
      dateStyle: request.dateStyle,
      dateTiming: request.dateTiming,
    );
  }

  factory PlanningEngineRequest.fromJson(Map<String, dynamic> json) {
    final originJson = json['origin'];
    final destinationJson = json['destination'];
    final constraintsJson = json['constraints'];
    return PlanningEngineRequest(
      mode: PlanningMode.fromWireName(json['mode']?.toString()),
      origin: PlanningLocation.fromJson(
        originJson is Map
            ? Map<String, dynamic>.from(originJson)
            : const <String, dynamic>{},
      ),
      destination: destinationJson is Map
          ? PlanningLocation.fromJson(
              Map<String, dynamic>.from(destinationJson),
            )
          : null,
      startsAt: DateTime.tryParse(json['startsAt']?.toString() ?? ''),
      endsAt: DateTime.tryParse(json['endsAt']?.toString() ?? ''),
      constraints: PlanningConstraints.fromJson(
        constraintsJson is Map
            ? Map<String, dynamic>.from(constraintsJson)
            : const <String, dynamic>{},
      ),
      dateOccasion: json['dateOccasion']?.toString(),
      dateStyle: json['dateStyle']?.toString(),
      dateTiming: json['dateTiming']?.toString(),
    );
  }

  PlanningRequest toRecommendationRequest() {
    if (mode != PlanningMode.quickDecision && mode != PlanningMode.dateNight) {
      throw StateError('${mode.wireName} is not a recommendation request.');
    }
    return PlanningRequest(
      group: constraints.group,
      budget: constraints.budget,
      energy: constraints.energy,
      isDateNight: mode == PlanningMode.dateNight,
      lat: origin.lat,
      lng: origin.lng,
      radiusMiles: constraints.radiusMiles,
      dateOccasion: dateOccasion,
      dateStyle: dateStyle,
      dateTiming: dateTiming,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.wireName,
    'origin': origin.toJson(),
    'destination': destination?.toJson(),
    'startsAt': startsAt?.toIso8601String(),
    'endsAt': endsAt?.toIso8601String(),
    'constraints': constraints.toJson(),
    'dateOccasion': dateOccasion,
    'dateStyle': dateStyle,
    'dateTiming': dateTiming,
  };
}
