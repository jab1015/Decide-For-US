import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/trip_discovery_zone.dart';
import '../models/trip_plan_draft.dart';
import '../models/trip_route.dart';

class TripRouteService {
  const TripRouteService();

  static const endpoint =
      'https://us-central1-decide-for-us-792bc.cloudfunctions.net/resolveTripRoute';
  static const discoveryEndpoint =
      'https://us-central1-decide-for-us-792bc.cloudfunctions.net/discoverTripStops';

  Future<TripRoute> resolve({
    required String origin,
    required String destination,
    required int maxTravelMinutesBetweenStops,
    double? originLat,
    double? originLng,
  }) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        throw const TripRouteException('Sign in is required to plan a trip.');
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'origin': origin,
          'destination': destination,
          'maxTravelMinutesBetweenStops': maxTravelMinutesBetweenStops,
          if (originLat != null) 'originLat': originLat,
          if (originLng != null) 'originLng': originLng,
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode != 200 || decoded is! Map) {
        throw TripRouteException(
          decoded is Map ? decoded['error']?.toString() : null,
          response.statusCode,
        );
      }
      return TripRoute.fromJson(Map<String, dynamic>.from(decoded));
    } on TripRouteException {
      rethrow;
    } catch (_) {
      throw const TripRouteException(
        'We could not map that route. Check the places and try again.',
      );
    }
  }

  Future<List<TripDiscoveryZone>> discoverStops({
    required TripRoute route,
    required TripPlanDraft draft,
  }) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) {
        throw const TripRouteException('Sign in is required to plan a trip.');
      }

      final response = await http.post(
        Uri.parse(discoveryEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'corridorPoints':
              route.corridorPoints.map((point) => point.toJson()).toList(),
          'interests': draft.interests,
          'exclusions': draft.exclusions,
          if (draft.startsAt != null)
            'startsAt': draft.startsAt!.toUtc().toIso8601String(),
          if (draft.endsAt != null)
            'endsAt': draft.endsAt!.toUtc().toIso8601String(),
        }),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode != 200 || decoded is! List) {
        throw TripRouteException(
          decoded is Map ? decoded['error']?.toString() : null,
          response.statusCode,
        );
      }
      return decoded
          .whereType<Map>()
          .map(
            (value) => TripDiscoveryZone.fromJson(
              Map<String, dynamic>.from(value),
            ),
          )
          .toList(growable: false);
    } on TripRouteException {
      rethrow;
    } catch (_) {
      throw const TripRouteException(
        'We could not discover stops along this route. Please try again.',
      );
    }
  }

}

class TripRouteException implements Exception {
  const TripRouteException([this.message, this.statusCode]);

  final String? message;
  final int? statusCode;

  @override
  String toString() => message ?? 'Trip route failed.';
}
