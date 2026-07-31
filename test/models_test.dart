import 'package:decide_for_us/models/activity.dart';
import 'package:decide_for_us/models/candidate_evaluation.dart';
import 'package:decide_for_us/models/planning_constraints.dart';
import 'package:decide_for_us/models/planning_engine_request.dart';
import 'package:decide_for_us/models/planning_location.dart';
import 'package:decide_for_us/models/planning_candidate.dart';
import 'package:decide_for_us/models/planning_mode.dart';
import 'package:decide_for_us/models/planning_option.dart';
import 'package:decide_for_us/models/planning_request.dart';
import 'package:decide_for_us/models/planning_response.dart';
import 'package:decide_for_us/models/planning_stop.dart';
import 'package:decide_for_us/models/trip_plan_draft.dart';
import 'package:decide_for_us/services/candidate_evaluator.dart';
import 'package:decide_for_us/services/candidate_provider.dart';
import 'package:decide_for_us/services/itinerary_scheduler.dart';
import 'package:decide_for_us/services/planning_engine.dart';
import 'package:decide_for_us/services/planning_option_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Activity preserves category and place id', () {
    final activity = Activity.fromJson({
      'place_id': 'place-123',
      'category': 'outdoors',
      'title': 'River Walk',
      'lat': 30,
      'lng': -81,
    });

    expect(activity.id, 'place-123');
    expect(activity.category, 'outdoors');
    expect(activity.toJson()['category'], 'outdoors');
  });

  test('PlanningRequest serializes every recommendation filter', () {
    const request = PlanningRequest(
      group: 'Friends',
      budget: r'$30–$75',
      energy: 'High',
      isDateNight: false,
      lat: 30.8,
      lng: -81.7,
      radiusMiles: 50,
      dateOccasion: 'Anniversary',
      dateStyle: 'Romantic',
      dateTiming: 'This weekend',
    );

    expect(request.toJson(), {
      'group': 'Friends',
      'budget': r'$30–$75',
      'energy': 'High',
      'isDateNight': false,
      'lat': 30.8,
      'lng': -81.7,
      'radius': 50,
      'dateOccasion': 'Anniversary',
      'dateStyle': 'Romantic',
      'dateTiming': 'This weekend',
    });
  });

  test('PlanningResponse creates two ordered options from four activities', () {
    const activities = [
      Activity(
        id: 'one',
        category: 'event',
        title: 'Live Music',
        description: '',
        address: '',
        lat: 30,
        lng: -81,
      ),
      Activity(
        id: 'two',
        category: 'food',
        title: 'Dinner',
        description: '',
        address: '',
        lat: 30,
        lng: -81,
      ),
      Activity(
        id: 'three',
        category: 'outdoors',
        title: 'River Walk',
        description: '',
        address: '',
        lat: 30,
        lng: -81,
      ),
      Activity(
        id: 'four',
        category: 'culture',
        title: 'Gallery',
        description: '',
        address: '',
        lat: 30,
        lng: -81,
      ),
    ];
    final createdAt = DateTime.utc(2026, 7, 30);
    final response = PlanningResponse.fromActivities(
      mode: PlanningMode.dateNight,
      activities: activities,
      createdAt: createdAt,
    );

    expect(response.options, hasLength(2));
    expect(response.options.first.activities.map((item) => item.id), [
      'one',
      'two',
    ]);
    expect(response.options.last.activities.map((item) => item.id), [
      'three',
      'four',
    ]);
    expect(response.activities.map((item) => item.id), [
      'one',
      'two',
      'three',
      'four',
    ]);

    final restored = PlanningResponse.fromJson(response.toJson());
    expect(restored.mode, PlanningMode.dateNight);
    expect(restored.createdAt, createdAt);
    expect(restored.activities.map((item) => item.id), [
      'one',
      'two',
      'three',
      'four',
    ]);
  });

  test('Planning modes declare their Premium requirements', () {
    expect(PlanningMode.quickDecision.requiresPremium, isFalse);
    expect(PlanningMode.dateNight.requiresPremium, isTrue);
    expect(PlanningMode.localEvents.requiresPremium, isTrue);
    expect(PlanningMode.trip.requiresPremium, isTrue);
    expect(PlanningMode.fromWireName('trip'), PlanningMode.trip);
  });
  test('PlanningEngineRequest preserves trip constraints', () {
    final startsAt = DateTime.utc(2026, 10, 2, 12);
    final endsAt = DateTime.utc(2026, 10, 5, 20);
    final request = PlanningEngineRequest(
      mode: PlanningMode.trip,
      origin: const PlanningLocation(
        lat: 30.3322,
        lng: -81.6557,
        label: 'Jacksonville',
      ),
      destination: const PlanningLocation(
        lat: 32.0809,
        lng: -81.0912,
        label: 'Savannah',
      ),
      startsAt: startsAt,
      endsAt: endsAt,
      constraints: const PlanningConstraints(
        group: 'Family',
        budget: r'$100+',
        energy: 'Medium',
        radiusMiles: 50,
        travelerCount: 4,
        maxTravelMinutesBetweenStops: 120,
        interests: ['history', 'scenic'],
        exclusions: ['nightlife'],
      ),
    );

    final restored = PlanningEngineRequest.fromJson(request.toJson());

    expect(restored.mode, PlanningMode.trip);
    expect(restored.origin.label, 'Jacksonville');
    expect(restored.destination?.label, 'Savannah');
    expect(restored.startsAt, startsAt);
    expect(restored.endsAt, endsAt);
    expect(restored.constraints.travelerCount, 4);
    expect(restored.constraints.maxTravelMinutesBetweenStops, 120);
    expect(restored.constraints.interests, ['history', 'scenic']);
    expect(restored.constraints.exclusions, ['nightlife']);
  });

  test('PlanningEngineRequest adapts the current recommendation request', () {
    const recommendation = PlanningRequest(
      group: 'Couple',
      budget: r'$50–$100',
      energy: 'Low',
      isDateNight: true,
      lat: 30.8,
      lng: -81.7,
      radiusMiles: 25,
      dateOccasion: 'Anniversary',
      dateStyle: 'Romantic',
      dateTiming: 'This Weekend',
    );

    final engineRequest =
        PlanningEngineRequest.fromRecommendation(recommendation);
    final adapted = engineRequest.toRecommendationRequest();

    expect(engineRequest.mode, PlanningMode.dateNight);
    expect(engineRequest.constraints.travelerCount, 2);
    expect(adapted.toJson(), recommendation.toJson());
  });

  test('PlanningCandidate normalizes verified places and events', () {
    const place = Activity(
      id: 'place-1',
      category: 'culture',
      title: 'Gallery',
      description: '',
      address: '',
      lat: 30,
      lng: -81,
    );
    final event = Activity(
      id: 'event-1',
      category: 'event',
      title: 'Live Music',
      description: '',
      address: '',
      lat: 30,
      lng: -81,
      eventUrl: 'https://example.com/event',
      eventStart: DateTime.utc(2026, 8, 1),
      source: 'ticketmaster',
    );

    final placeCandidate = PlanningCandidate.fromActivity(place);
    final eventCandidate = PlanningCandidate.fromActivity(event);

    expect(placeCandidate.kind, CandidateKind.place);
    expect(placeCandidate.source, CandidateSource.googlePlaces);
    expect(eventCandidate.kind, CandidateKind.event);
    expect(eventCandidate.source, CandidateSource.ticketmaster);
    expect(eventCandidate.sourceUrl, event.eventUrl);

    final restored = PlanningCandidate.fromJson(eventCandidate.toJson());
    expect(restored.providerId, 'event-1');
    expect(restored.activity.title, 'Live Music');
    expect(restored.isVerified, isTrue);
  });

  test('PlanningEngine consumes candidates through an injected provider', () async {
    const activity = Activity(
      id: 'provider-result',
      category: 'outdoors',
      title: 'Scenic Walk',
      description: '',
      address: '',
      lat: 30,
      lng: -81,
    );
    final engine = DefaultPlanningEngine(
      provider: _FakeCandidateProvider([
        PlanningCandidate.fromActivity(activity),
      ]),
    );
    final response = await engine.createPlan(
      const PlanningEngineRequest(
        mode: PlanningMode.quickDecision,
        origin: PlanningLocation(lat: 30, lng: -81),
        constraints: PlanningConstraints(),
      ),
    );

    expect(response.activities.single.id, 'provider-result');
  });
  test('CandidateEvaluator rejects exclusions and over-budget events', () {
    final event = PlanningCandidate.fromActivity(
      Activity(
        id: 'event-expensive',
        category: 'nightlife',
        title: 'Downtown Nightclub',
        description: '',
        address: '',
        lat: 30,
        lng: -81,
        eventUrl: 'https://example.com/event',
        eventStart: DateTime.utc(2026, 8, 2),
        source: 'ticketmaster',
        minPrice: 80,
      ),
    );
    final evaluation = const CandidateEvaluator().evaluate(
      event,
      PlanningEngineRequest(
        mode: PlanningMode.localEvents,
        origin: const PlanningLocation(lat: 30, lng: -81),
        startsAt: DateTime.utc(2026, 8, 1),
        endsAt: DateTime.utc(2026, 8, 3),
        constraints: const PlanningConstraints(
          group: 'Family',
          budget: r'Under $30',
          exclusions: ['nightclub'],
        ),
      ),
    );

    expect(evaluation.eligible, isFalse);
    expect(evaluation.rejectionReasons, contains('excluded:nightclub'));
    expect(evaluation.rejectionReasons, contains('over_budget'));
  });

  test('CandidateEvaluator enforces event time windows', () {
    final event = PlanningCandidate.fromActivity(
      Activity(
        id: 'event-late',
        category: 'event',
        title: 'Late Concert',
        description: '',
        address: '',
        lat: 30,
        lng: -81,
        eventUrl: 'https://example.com/late',
        eventStart: DateTime.utc(2026, 8, 10),
        source: 'ticketmaster',
      ),
    );
    final evaluation = const CandidateEvaluator().evaluate(
      event,
      PlanningEngineRequest(
        mode: PlanningMode.localEvents,
        origin: const PlanningLocation(lat: 30, lng: -81),
        startsAt: DateTime.utc(2026, 8, 1),
        endsAt: DateTime.utc(2026, 8, 3),
        constraints: const PlanningConstraints(),
      ),
    );

    expect(evaluation.eligible, isFalse);
    expect(evaluation.rejectionReasons, contains('after_time_window'));
  });

  test('CandidateEvaluator rewards energy and interest matches', () {
    final candidate = PlanningCandidate.fromActivity(
      const Activity(
        id: 'kayak-1',
        category: 'adventure',
        title: 'Sunrise Kayak Adventure',
        description: 'An active outdoor trip on the water.',
        address: '',
        lat: 30,
        lng: -81,
      ),
    );
    final matched = const CandidateEvaluator().evaluate(
      candidate,
      const PlanningEngineRequest(
        mode: PlanningMode.quickDecision,
        origin: PlanningLocation(lat: 30, lng: -81),
        constraints: PlanningConstraints(
          energy: 'High',
          interests: ['water'],
        ),
      ),
    );
    final unmatched = const CandidateEvaluator().evaluate(
      candidate,
      const PlanningEngineRequest(
        mode: PlanningMode.quickDecision,
        origin: PlanningLocation(lat: 30, lng: -81),
        constraints: PlanningConstraints(energy: 'Low'),
      ),
    );

    expect(matched.eligible, isTrue);
    expect(matched.score, greaterThan(unmatched.score));
    expect(matched.scoreReasons, contains('energy_match'));
    expect(matched.scoreReasons, contains('interest_match'));
  });

  test('PlanningOptionBuilder never pairs food with food', () {
    final evaluations = [
      _evaluation(_activity('dinner', 'food', 'Italian Dinner'), 95),
      _evaluation(_activity('coffee', 'food', 'Coffee House'), 90),
      _evaluation(_activity('park', 'outdoors', 'River Park'), 85),
      _evaluation(_activity('gallery', 'culture', 'Art Gallery'), 80),
      _evaluation(_activity('arcade', 'entertainment', 'Retro Arcade'), 75),
    ];
    final options = const PlanningOptionBuilder().build(
      evaluations,
      _quickRequest,
    );

    expect(options, hasLength(2));
    for (final option in options) {
      final foodStops = option.activities.where(
        (activity) => activity.category == 'food',
      );
      expect(foodStops.length, lessThanOrEqualTo(1));
    }
    final optionsWithFood = options.where(
      (option) => option.activities.any((activity) => activity.category == 'food'),
    );
    expect(optionsWithFood.length, 1);
  });

  test('PlanningOptionBuilder orders an event before its companion', () {
    final event = Activity(
      id: 'concert',
      category: 'event',
      title: 'Live Concert',
      description: '',
      address: '',
      lat: 30,
      lng: -81,
      eventUrl: 'https://example.com/concert',
      eventStart: DateTime.utc(2026, 8, 2),
      source: 'ticketmaster',
    );
    final options = const PlanningOptionBuilder(maxOptions: 1).build(
      [
        _evaluation(_activity('dinner', 'food', 'Dinner'), 95),
        _evaluation(event, 90),
      ],
      _quickRequest,
    );

    expect(options.single.activities.map((item) => item.id), [
      'concert',
      'dinner',
    ]);
    expect(options.single.summary, 'A live moment, made into an outing.');
  });

  test('PlanningOptionBuilder supports future multi-stop options', () {
    final options = const PlanningOptionBuilder(
      maxOptions: 1,
      stopsPerOption: 3,
    ).build(
      [
        _evaluation(_activity('trail', 'outdoors', 'Scenic Trail'), 90),
        _evaluation(_activity('museum', 'culture', 'History Museum'), 85),
        _evaluation(_activity('lunch', 'food', 'Local Lunch'), 80),
      ],
      _quickRequest,
    );

    expect(options.single.stops, hasLength(3));
    expect(options.single.stops.map((stop) => stop.sequence), [0, 1, 2]);
    expect(options.single.activities.last.id, 'lunch');
  });

  test('ItineraryScheduler assigns sequential times and travel gaps', () {
    final start = DateTime.utc(2026, 8, 1, 9);
    final option = PlanningOption(
      id: 'option-1',
      title: 'Option 1',
      stops: [
        PlanningStop(
          sequence: 0,
          activity: _activity('museum', 'culture', 'History Museum'),
        ),
        const PlanningStop(
          sequence: 1,
          activity: Activity(
            id: 'lunch',
            category: 'food',
            title: 'Local Lunch',
            description: '',
            address: '',
            lat: 30.08,
            lng: -81.08,
          ),
        ),
      ],
    );
    final scheduled = const ItineraryScheduler().schedule(
      [option],
      PlanningEngineRequest(
        mode: PlanningMode.trip,
        origin: const PlanningLocation(lat: 30, lng: -81),
        startsAt: start,
        constraints: const PlanningConstraints(),
      ),
    ).single;

    final first = scheduled.stops.first;
    final second = scheduled.stops.last;
    expect(first.startsAt, start);
    expect(first.durationMinutes, 90);
    expect(second.travelMinutesFromPrevious, greaterThan(0));
    expect(
      second.startsAt,
      start.add(
        Duration(
          minutes: first.durationMinutes! + second.travelMinutesFromPrevious!,
        ),
      ),
    );
    expect(scheduled.totalTravelMinutes, second.travelMinutesFromPrevious);
  });

  test('ItineraryScheduler preserves authoritative event start times', () {
    final eventStart = DateTime.utc(2026, 8, 1, 19, 30);
    final option = PlanningOption(
      id: 'event-option',
      title: 'Event Option',
      stops: [
        PlanningStop(
          sequence: 0,
          activity: Activity(
            id: 'concert',
            category: 'event',
            title: 'Live Concert',
            description: '',
            address: '',
            lat: 30,
            lng: -81,
            eventStart: eventStart,
          ),
        ),
      ],
    );
    final scheduled = const ItineraryScheduler().schedule(
      [option],
      PlanningEngineRequest(
        mode: PlanningMode.dateNight,
        origin: const PlanningLocation(lat: 30, lng: -81),
        startsAt: DateTime.utc(2026, 8, 1, 17),
        constraints: const PlanningConstraints(),
      ),
    ).single;

    expect(scheduled.stops.single.startsAt, eventStart);
    expect(scheduled.stops.single.durationMinutes, 120);
  });

  test('ItineraryScheduler totals known costs for all travelers', () {
    const option = PlanningOption(
      id: 'priced-option',
      title: 'Priced Option',
      stops: [
        PlanningStop(
          sequence: 0,
          activity: Activity(
            id: 'event',
            category: 'event',
            title: 'Festival',
            description: '',
            address: '',
            lat: 30,
            lng: -81,
            minPrice: 20,
          ),
        ),
        PlanningStop(
          sequence: 1,
          activity: Activity(
            id: 'tour',
            category: 'culture',
            title: 'Historic Tour',
            description: '',
            address: '',
            lat: 30,
            lng: -81,
            minPrice: 10,
          ),
        ),
      ],
    );
    final scheduled = const ItineraryScheduler().schedule(
      [option],
      const PlanningEngineRequest(
        mode: PlanningMode.trip,
        origin: PlanningLocation(lat: 30, lng: -81),
        constraints: PlanningConstraints(travelerCount: 3),
      ),
    ).single;

    expect(scheduled.stops.first.estimatedCostCents, 6000);
    expect(scheduled.stops.last.estimatedCostCents, 3000);
    expect(scheduled.estimatedCostCents, 9000);
  });

  test('TripPlanDraft requires destination and dates', () {
    const draft = TripPlanDraft();

    expect(draft.isValid, isFalse);
    expect(draft.validationErrors, contains('Choose a destination.'));
    expect(draft.validationErrors, contains('Choose your trip dates.'));
  });

  test('TripPlanDraft creates a trip Planning Engine request', () {
    final draft = TripPlanDraft(
      originLabel: ' Jacksonville ',
      destinationLabel: ' Savannah ',
      startsAt: DateTime.utc(2026, 10, 2),
      endsAt: DateTime.utc(2026, 10, 5),
      travelerCount: 4,
      budget: r'$1,000–$2,500',
      maxTravelMinutesBetweenStops: 120,
      interests: const ['History', 'Local food'],
      exclusions: const ['Toll roads'],
    );
    final request = draft.toPlanningRequest(
      origin: const PlanningLocation(lat: 30.3322, lng: -81.6557),
      destination: const PlanningLocation(lat: 32.0809, lng: -81.0912),
    );

    expect(draft.isValid, isTrue);
    expect(request.mode, PlanningMode.trip);
    expect(request.origin.label, 'Jacksonville');
    expect(request.destination?.label, 'Savannah');
    expect(request.constraints.travelerCount, 4);
    expect(request.constraints.maxTravelMinutesBetweenStops, 120);
    expect(request.constraints.interests, ['History', 'Local food']);
    expect(request.constraints.exclusions, ['Toll roads']);
  });

  test('TripPlanDraft rejects impossible return dates', () {
    final draft = TripPlanDraft(
      destinationLabel: 'Savannah',
      startsAt: DateTime.utc(2026, 10, 5),
      endsAt: DateTime.utc(2026, 10, 2),
    );

    expect(draft.isValid, isFalse);
    expect(
      draft.validationErrors,
      contains('The return date must be after the departure date.'),
    );
  });

}


class _FakeCandidateProvider implements CandidateProvider {
  const _FakeCandidateProvider(this.candidates);

  final List<PlanningCandidate> candidates;

  @override
  String get id => 'fake';

  @override
  Future<List<PlanningCandidate>> fetch(PlanningEngineRequest request) async {
    return candidates;
  }
}

const _quickRequest = PlanningEngineRequest(
  mode: PlanningMode.quickDecision,
  origin: PlanningLocation(lat: 30, lng: -81),
  constraints: PlanningConstraints(),
);

Activity _activity(String id, String category, String title) {
  return Activity(
    id: id,
    category: category,
    title: title,
    description: '',
    address: '',
    lat: 30,
    lng: -81,
  );
}

CandidateEvaluation _evaluation(Activity activity, double score) {
  return CandidateEvaluation(
    candidate: PlanningCandidate.fromActivity(activity),
    eligible: true,
    score: score,
  );
}
