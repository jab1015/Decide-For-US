import 'dart:math' as math;

import '../models/activity.dart';
import '../models/planning_engine_request.dart';
import '../models/planning_option.dart';
import '../models/planning_stop.dart';

class ItineraryScheduler {
  const ItineraryScheduler();

  List<PlanningOption> schedule(
    Iterable<PlanningOption> options,
    PlanningEngineRequest request,
  ) {
    return options.map((option) => _scheduleOption(option, request)).toList();
  }

  PlanningOption _scheduleOption(
    PlanningOption option,
    PlanningEngineRequest request,
  ) {
    final scheduledStops = <PlanningStop>[];
    DateTime? cursor = request.startsAt;
    var totalTravelMinutes = 0;
    var totalCostCents = 0;
    var hasCostEstimate = false;

    for (var index = 0; index < option.stops.length; index++) {
      final original = option.stops[index];
      final activity = original.activity;
      final previous = index == 0 ? null : option.stops[index - 1].activity;
      final travelMinutes = previous == null
          ? null
          : original.travelMinutesFromPrevious ??
              _estimateTravelMinutes(previous, activity);
      if (travelMinutes != null) {
        totalTravelMinutes += travelMinutes;
        if (cursor != null) cursor = cursor.add(Duration(minutes: travelMinutes));
      }

      final authoritativeEventStart = activity.eventStart;
      final startsAt = authoritativeEventStart ?? original.startsAt ?? cursor;
      final durationMinutes = original.durationMinutes ??
          _durationMinutes(activity, request.constraints.energy);
      final estimatedCostCents = original.estimatedCostCents ??
          _estimatedCostCents(activity, request.constraints.travelerCount);
      if (estimatedCostCents != null) {
        totalCostCents += estimatedCostCents;
        hasCostEstimate = true;
      }

      scheduledStops.add(
        PlanningStop(
          sequence: index,
          activity: activity,
          startsAt: startsAt,
          durationMinutes: durationMinutes,
          travelMinutesFromPrevious: travelMinutes,
          estimatedCostCents: estimatedCostCents,
        ),
      );
      if (startsAt != null) {
        cursor = startsAt.add(Duration(minutes: durationMinutes));
      }
    }

    return PlanningOption(
      id: option.id,
      title: option.title,
      summary: option.summary,
      stops: scheduledStops,
      estimatedCostCents: hasCostEstimate ? totalCostCents : null,
      totalTravelMinutes: totalTravelMinutes,
    );
  }

  int _durationMinutes(Activity activity, String? energy) {
    final value = '${activity.category} ${activity.title}'.toLowerCase();
    if (activity.eventStart != null || value.contains('event')) return 120;
    if (_contains(value, const [
      'restaurant',
      'dinner',
      'lunch',
      'breakfast',
      'food',
    ])) {
      return 75;
    }
    if (_contains(value, const ['coffee', 'dessert', 'bakery'])) return 45;
    if (_contains(value, const ['museum', 'gallery', 'culture'])) return 90;
    if (_contains(value, const [
      'hiking',
      'kayak',
      'adventure',
      'fitness',
      'sports',
    ])) {
      return 120;
    }
    if (energy?.toLowerCase() == 'high') return 105;
    if (energy?.toLowerCase() == 'low') return 60;
    return 75;
  }

  int? _estimatedCostCents(Activity activity, int travelerCount) {
    final price = activity.minPrice;
    if (price == null) return null;
    return (price * math.max(1, travelerCount) * 100).round();
  }

  int _estimateTravelMinutes(Activity from, Activity to) {
    final miles = _distanceMiles(from.lat, from.lng, to.lat, to.lng);
    final drivingMinutes = (miles / 25 * 60).round();
    return (drivingMinutes + 8).clamp(5, 180).toInt();
  }

  double _distanceMiles(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    const earthRadiusMiles = 3958.8;
    final lat1 = _radians(fromLat);
    final lat2 = _radians(toLat);
    final deltaLat = _radians(toLat - fromLat);
    final deltaLng = _radians(toLng - fromLng);
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final normalized = a.clamp(0, 1).toDouble();
    return earthRadiusMiles *
        2 *
        math.atan2(math.sqrt(normalized), math.sqrt(1 - normalized));
  }

  double _radians(double degrees) => degrees * math.pi / 180;

  bool _contains(String value, Iterable<String> tokens) {
    return tokens.any(value.contains);
  }
}
