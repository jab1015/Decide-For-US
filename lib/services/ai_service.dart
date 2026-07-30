import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/activity.dart';
import '../models/planning_request.dart';

class AIService {
  static const String baseUrl =
      'https://us-central1-decide-for-us-792bc.cloudfunctions.net/getIdeas';
  static const String resetTesterUsageUrl =
      'https://us-central1-decide-for-us-792bc.cloudfunctions.net/resetTesterUsage';
  static const String localEventsUrl =
      'https://us-central1-decide-for-us-792bc.cloudfunctions.net/getLocalEvents';

  static Future<List<Activity>> getIdeas(PlanningRequest request) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 200) {
        final decoded = jsonDecode(response.body);
        throw AIServiceException(
          decoded is Map ? decoded['error']?.toString() : null,
          response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const AIServiceException('The server returned invalid results.');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Activity.fromJson)
          .where((activity) => activity.id.isNotEmpty)
          .toList();
    } on AIServiceException {
      rethrow;
    } catch (_) {
      throw const AIServiceException(
        'We could not find ideas right now. Please try again.',
      );
    }
  }

  static Future<void> resetTesterUsage() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.post(
        Uri.parse(resetTesterUsageUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) {
        final decoded = jsonDecode(response.body);
        throw AIServiceException(
          decoded is Map ? decoded['error']?.toString() : null,
          response.statusCode,
        );
      }
    } on AIServiceException {
      rethrow;
    } catch (_) {
      throw const AIServiceException('Tester reset failed. Please try again.');
    }
  }

  static Future<List<Activity>> getLocalEvents({
    required double lat,
    required double lng,
    int radiusMiles = 25,
  }) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.post(
        Uri.parse(localEventsUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'lat': lat,
          'lng': lng,
          'radius': radiusMiles,
        }),
      );

      if (response.statusCode != 200) {
        final decoded = jsonDecode(response.body);
        throw AIServiceException(
          decoded is Map ? decoded['error']?.toString() : null,
          response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw const AIServiceException('The server returned invalid events.');
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Activity.fromJson)
          .where((event) => event.id.isNotEmpty)
          .toList();
    } on AIServiceException {
      rethrow;
    } catch (_) {
      throw const AIServiceException(
        'We could not find local events right now. Please try again.',
      );
    }
  }
}

class AIServiceException implements Exception {
  const AIServiceException([this.message, this.statusCode]);

  final String? message;
  final int? statusCode;

  @override
  String toString() => message ?? 'Recommendation request failed.';
}
