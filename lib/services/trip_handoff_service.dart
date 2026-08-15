import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/planning_option.dart';
import '../models/trip_plan_draft.dart';
import '../models/trip_route.dart';

class TripHandoffService {
  const TripHandoffService();

  Uri mapsUri({
    required TripPlanDraft draft,
    required TripRoute route,
    required PlanningOption itinerary,
  }) {
    final waypoints = itinerary.stops
        .map((stop) => _activityLocation(stop.activity.address, stop.activity.lat, stop.activity.lng))
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': _location(
        route.origin.label ?? draft.originLabel,
        route.origin.lat,
        route.origin.lng,
      ),
      'destination': _location(
        route.destination.label ?? draft.destinationLabel,
        route.destination.lat,
        route.destination.lng,
      ),
      if (waypoints.isNotEmpty) 'waypoints': waypoints.join('|'),
      'travelmode': 'driving',
    });
  }

  String shareText({
    required TripPlanDraft draft,
    required TripRoute route,
    required PlanningOption itinerary,
  }) {
    final buffer = StringBuffer()
      ..writeln('Our Decide For Us road trip')
      ..writeln(
        '${route.origin.label ?? draft.originLabel} → '
        '${route.destination.label ?? draft.destinationLabel}',
      )
      ..writeln('${route.distanceLabel} • ${route.durationLabel} driving')
      ..writeln();
    for (var index = 0; index < itinerary.stops.length; index++) {
      final stop = itinerary.stops[index];
      buffer.writeln('${index + 1}. ${stop.activity.title}');
      if (stop.activity.address.isNotEmpty) {
        buffer.writeln('   ${stop.activity.address}');
      }
    }
    buffer
      ..writeln()
      ..writeln('Open the complete route in Google Maps:')
      ..write(mapsUri(draft: draft, route: route, itinerary: itinerary));
    return buffer.toString();
  }

  Future<void> openMaps({
    required TripPlanDraft draft,
    required TripRoute route,
    required PlanningOption itinerary,
  }) async {
    final uri = mapsUri(draft: draft, route: route, itinerary: itinerary);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Google Maps could not be opened.');
    }
  }

  Future<bool> share({
    required TripPlanDraft draft,
    required TripRoute route,
    required PlanningOption itinerary,
  }) async {
    final text = shareText(draft: draft, route: route, itinerary: itinerary);
    try {
      await Share.share(
        text,
        subject: 'Our Decide For Us road trip',
      );
      return true;
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      return false;
    }
  }

  static String _location(String label, double lat, double lng) {
    final trimmed = label.trim();
    if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'current location') {
      return trimmed;
    }
    return '$lat,$lng';
  }

  static String _activityLocation(String address, double lat, double lng) {
    final trimmed = address.trim();
    return trimmed.isNotEmpty ? trimmed : '$lat,$lng';
  }
}
