import 'package:decide_for_us/models/activity.dart';
import 'package:decide_for_us/models/planning_mode.dart';
import 'package:decide_for_us/models/planning_request.dart';
import 'package:decide_for_us/models/planning_response.dart';
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
}

