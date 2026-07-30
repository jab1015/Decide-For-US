import 'package:flutter_test/flutter_test.dart';

import 'package:decide_for_us/models/activity.dart';

void main() {
  test('parses an event with a complementary stop', () {
    final event = Activity.fromJson({
      'id': 'ticketmaster:event-1',
      'category': 'event',
      'title': 'Live Music',
      'description': 'An evening show.',
      'address': '1 Main Street',
      'lat': 35.0,
      'lng': -80.0,
      'companionDistanceMiles': 1.4,
      'searchRadiusMiles': 50,
      'minPrice': 25,
      'maxPrice': 60,
      'priceCurrency': 'USD',
      'companion': {
        'id': 'place-1',
        'category': 'food',
        'title': 'Local Dessert',
        'description': 'A nearby add-on.',
        'address': '2 Main Street',
        'lat': 35.01,
        'lng': -80.01,
      },
    });

    expect(event.companion?.title, 'Local Dessert');
    expect(event.companion?.category, 'food');
    expect(event.companionDistanceMiles, 1.4);
    expect(event.searchRadiusMiles, 50);
    expect(event.minPrice, 25);
    expect(event.maxPrice, 60);
    expect(event.toJson()['companion'], isA<Map<String, dynamic>>());
  });
}

