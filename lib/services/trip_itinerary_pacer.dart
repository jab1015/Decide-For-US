import '../models/planning_option.dart';
import '../models/planning_stop.dart';

class TripItineraryPacer {
  const TripItineraryPacer({
    this.dayStartsAtHour = 9,
    this.dayEndsAtHour = 20,
  });

  final int dayStartsAtHour;
  final int dayEndsAtHour;

  PlanningOption pace(
    PlanningOption itinerary, {
    required DateTime startsAt,
  }) {
    final paced = <PlanningStop>[];
    var cursor = startsAt;

    for (final original in itinerary.stops) {
      final travelMinutes = original.travelMinutesFromPrevious ?? 0;
      var proposed = cursor.add(Duration(minutes: travelMinutes));
      final eventStart = original.activity.eventStart;
      if (eventStart != null) {
        proposed = eventStart;
      } else if (_pastDayEnd(
        proposed,
        original.durationMinutes ?? 75,
      )) {
        proposed = DateTime(
          proposed.year,
          proposed.month,
          proposed.day + 1,
          dayStartsAtHour,
        );
      }

      paced.add(
        PlanningStop(
          sequence: paced.length,
          activity: original.activity,
          startsAt: proposed,
          durationMinutes: original.durationMinutes,
          travelMinutesFromPrevious: original.travelMinutesFromPrevious,
          estimatedCostCents: original.estimatedCostCents,
        ),
      );
      cursor = proposed.add(
        Duration(minutes: original.durationMinutes ?? 75),
      );
    }

    return PlanningOption(
      id: itinerary.id,
      title: itinerary.title,
      summary: itinerary.summary,
      stops: paced,
      estimatedCostCents: itinerary.estimatedCostCents,
      totalTravelMinutes: itinerary.totalTravelMinutes,
    );
  }

  bool _pastDayEnd(DateTime startsAt, int durationMinutes) {
    final cutoff = DateTime(
      startsAt.year,
      startsAt.month,
      startsAt.day,
      dayEndsAtHour,
    );
    return !startsAt
        .add(Duration(minutes: durationMinutes))
        .isBefore(cutoff);
  }
}
