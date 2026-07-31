import 'package:flutter/material.dart';

import '../models/planning_option.dart';
import '../models/trip_plan_draft.dart';
import '../models/trip_route.dart';
import '../services/trip_plan_storage.dart';
import '../theme/app_theme.dart';
import 'trip_itinerary_screen.dart';
import 'trip_route_screen.dart';

class SavedTripsScreen extends StatefulWidget {
  const SavedTripsScreen({super.key});

  @override
  State<SavedTripsScreen> createState() => _SavedTripsScreenState();
}

class _SavedTripsScreenState extends State<SavedTripsScreen> {
  final TripPlanStorage _storage = const TripPlanStorage();
  late Future<List<Map<String, dynamic>>> _savedTrips;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _savedTrips = _storage.loadAll();
  }

  Future<void> _delete(Map<String, dynamic> trip) async {
    final id = trip['id']?.toString();
    if (id == null || id.isEmpty) return;
    await _storage.delete(id);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved trip removed.')),
    );
  }

  void _open(Map<String, dynamic> trip) {
    try {
      final routeJson = Map<String, dynamic>.from(trip['route'] as Map);
      final itineraryJson = Map<String, dynamic>.from(
        trip['itinerary'] as Map,
      );
      final draft = TripPlanDraft.fromJson(trip);
      final route = TripRoute.fromJson(routeJson);
      final itinerary = PlanningOption.fromJson(itineraryJson);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (itineraryContext) => TripItineraryScreen(
            draft: draft,
            route: route,
            itinerary: itinerary,
            onChangeStops: () {
              Navigator.of(itineraryContext).push(
                MaterialPageRoute<void>(
                  builder: (_) => TripRouteScreen(
                    draft: draft,
                    route: route,
                    initialSelectedActivityIds: [
                      for (final stop in itinerary.stops) stop.activity.id,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This saved trip could not be opened.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SAVED TRIPS')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _savedTrips,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final trips = snapshot.data ?? const <Map<String, dynamic>>[];
          if (trips.isEmpty) return const _EmptySavedTrips();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            children: [
              const Text(
                '✦  YOUR ADVENTURES  ✦',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Good trips deserve\na second look.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 22),
              for (final trip in trips)
                _SavedTripCard(
                  trip: trip,
                  onOpen: () => _open(trip),
                  onDelete: () => _delete(trip),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SavedTripCard extends StatelessWidget {
  const _SavedTripCard({
    required this.trip,
    required this.onOpen,
    required this.onDelete,
  });

  final Map<String, dynamic> trip;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final itinerary = trip['itinerary'] is Map
        ? Map<String, dynamic>.from(trip['itinerary'] as Map)
        : const <String, dynamic>{};
    final rawStops = itinerary['stops'];
    final stopCount = rawStops is List ? rawStops.length : 0;
    final startsAt = DateTime.tryParse(trip['startsAt']?.toString() ?? '');
    final destination = trip['destinationLabel']?.toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination == null || destination.isEmpty
                          ? 'Saved road trip'
                          : destination,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_date(startsAt)} • $stopCount '
                      '${stopCount == 1 ? 'stop' : 'stops'}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete saved trip',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  static String _date(DateTime? value) {
    if (value == null) return 'Dates flexible';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}

class _EmptySavedTrips extends StatelessWidget {
  const _EmptySavedTrips();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.lavender,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.luggage_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No trips saved yet.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Build a road trip, choose your favorite stops, and save the '
              'itinerary here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
