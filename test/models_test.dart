import 'package:decide_for_us/models/activity.dart';
import 'package:decide_for_us/models/planning_request.dart';
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
    );

    expect(request.toJson(), {
      'group': 'Friends',
      'budget': r'$30–$75',
      'energy': 'High',
      'isDateNight': false,
      'lat': 30.8,
      'lng': -81.7,
      'radius': 50,
    });
  });
}

