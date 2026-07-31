import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/planning_option.dart';
import '../models/planning_stop.dart';
import '../models/trip_discovery_zone.dart';
import '../models/trip_plan_draft.dart';
import '../models/trip_route.dart';
import '../services/itinerary_scheduler.dart';
import '../services/trip_itinerary_pacer.dart';
import '../services/trip_route_service.dart';
import '../theme/app_theme.dart';
import 'trip_itinerary_screen.dart';

class TripRouteScreen extends StatefulWidget {
  const TripRouteScreen({
    super.key,
    required this.draft,
    required this.route,
  });

  final TripPlanDraft draft;
  final TripRoute route;

  @override
  State<TripRouteScreen> createState() => _TripRouteScreenState();
}

class _TripRouteScreenState extends State<TripRouteScreen> {
  late Future<List<TripDiscoveryZone>> _discovery;
  List<TripDiscoveryZone> _zones = const [];
  final Map<int, String> _selectedByZone = {};

  TripPlanDraft get draft => widget.draft;
  TripRoute get route => widget.route;

  @override
  void initState() {
    super.initState();
    _loadDiscoveries();
  }

  void _loadDiscoveries() {
    _discovery = const TripRouteService()
        .discoverStops(route: route, draft: draft)
        .then((zones) {
      _zones = zones;
      return zones;
    });
  }

  void _retryDiscoveries() {
    setState(_loadDiscoveries);
  }


  void _selectCandidate(int zoneIndex, Activity candidate) {
    setState(() {
      if (_selectedByZone[zoneIndex] == candidate.id) {
        _selectedByZone.remove(zoneIndex);
      } else {
        _selectedByZone[zoneIndex] = candidate.id;
      }
    });
  }

  void _buildItinerary() {
    if (_selectedByZone.isEmpty) return;
    final selected = <Activity>[];
    for (final zone in [..._zones]..sort((a, b) => a.index.compareTo(b.index))) {
      final id = _selectedByZone[zone.index];
      if (id == null) continue;
      final matches = zone.candidates.where((candidate) => candidate.id == id);
      if (matches.isNotEmpty) selected.add(matches.first);
    }
    if (selected.isEmpty || draft.startsAt == null) return;

    final date = draft.startsAt!;
    final timedDraft = draft.copyWith(
      startsAt: DateTime(date.year, date.month, date.day, 9),
    );
    final request = timedDraft.toPlanningRequest(
      origin: route.origin,
      destination: route.destination,
    );
    final option = PlanningOption(
      id: 'trip-${DateTime.now().millisecondsSinceEpoch}',
      title: route.destination.label ?? draft.destinationLabel,
      summary: 'Your selected road-trip discoveries.',
      stops: [
        for (var index = 0; index < selected.length; index++)
          PlanningStop(sequence: index, activity: selected[index]),
      ],
    );
    final scheduled = const ItineraryScheduler()
        .schedule([option], request)
        .single;
    final itinerary = const TripItineraryPacer().pace(
      scheduled,
      startsAt: timedDraft.startsAt!,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripItineraryScreen(
          draft: timedDraft,
          route: route,
          itinerary: itinerary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = route.corridorPoints;
    return Scaffold(
      appBar: AppBar(title: const Text('YOUR ROAD TRIP')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const Text(
            '✦  THE ROUTE IS ONLY THE BEGINNING  ✦',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.coral,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'The journey is\nstarting to take shape.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 20),
          _RouteHero(draft: draft, route: route),
          const SizedBox(height: 22),
          Text(
            'Discovery zones',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            points.isEmpty
                ? 'This is a direct route. We’ll focus discoveries near '
                    'your destination.'
                : 'These are the parts of the drive where we’ll look for '
                    'local food, hidden gems, events, and worthwhile stops.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          _RoutePointCard(
            number: 0,
            title: route.origin.label ?? draft.originLabel,
            subtitle: 'Your journey begins',
            icon: Icons.trip_origin_rounded,
          ),
          FutureBuilder<List<TripDiscoveryZone>>(
            future: _discovery,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _DiscoveryLoading();
              }
              if (snapshot.hasError) {
                return _DiscoveryError(
                  message: snapshot.error.toString(),
                  onRetry: _retryDiscoveries,
                );
              }
              final zones = snapshot.data ?? const [];
              return Column(
                children: [
                  for (final zone in zones)
                    _DiscoveryZoneCard(
                      zone: zone,
                      selectedId: _selectedByZone[zone.index],
                      onSelected: (candidate) =>
                          _selectCandidate(zone.index, candidate),
                    ),
                ],
              );
            },
          ),
          _RoutePointCard(
            number: points.length + 1,
            title: route.destination.label ?? draft.destinationLabel,
            subtitle: 'Destination',
            icon: Icons.flag_rounded,
            isLast: true,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tune_rounded, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose one favorite in any discovery zone. '
                    'Choosing another option in that zone replaces it.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _selectedByZone.isEmpty ? null : _buildItinerary,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(
              _selectedByZone.isEmpty
                  ? 'CHOOSE YOUR STOPS'
                  : 'BUILD MY ITINERARY (${_selectedByZone.length})',
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteHero extends StatelessWidget {
  const _RouteHero({required this.draft, required this.route});

  final TripPlanDraft draft;
  final TripRoute route;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF7B68EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${route.origin.label ?? draft.originLabel} →',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 3),
          Text(
            route.destination.label ?? draft.destinationLabel,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _Metric(
                icon: Icons.route_rounded,
                label: route.distanceLabel,
              ),
              const SizedBox(width: 22),
              _Metric(
                icon: Icons.schedule_rounded,
                label: route.durationLabel,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${draft.travelerCount} '
            '${draft.travelerCount == 1 ? 'traveler' : 'travelers'}'
            '  •  ${draft.budget}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 19),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RoutePointCard extends StatelessWidget {
  const _RoutePointCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isLast = false,
  });

  final int number;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 38,
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.lavender,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 17),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 64,
                  color: AppColors.border,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class _DiscoveryLoading extends StatelessWidget {
  const _DiscoveryLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Finding local favorites, events, and worthwhile stops…',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DiscoveryError extends StatelessWidget {
  const _DiscoveryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
        ],
      ),
    );
  }
}

class _DiscoveryZoneCard extends StatelessWidget {
  const _DiscoveryZoneCard({
    required this.zone,
    required this.selectedId,
    required this.onSelected,
  });

  final TripDiscoveryZone zone;
  final String? selectedId;
  final ValueChanged<Activity> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DISCOVERY ZONE ${zone.index + 1}',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${zone.location.lat.toStringAsFixed(2)}, '
            '${zone.location.lng.toStringAsFixed(2)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (zone.candidates.isEmpty)
            const Text('No strong matches found in this stretch.')
          else
            for (final candidate in zone.candidates)
              _TripCandidateTile(
                candidate: candidate,
                selected: selectedId == candidate.id,
                onTap: () => onSelected(candidate),
              ),
        ],
      ),
    );
  }
}

class _TripCandidateTile extends StatelessWidget {
  const _TripCandidateTile({
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  final Activity candidate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = candidate.photoUrl;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? AppColors.lavender : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 72,
              height: 72,
              child: imageUrl == null || imageUrl.isEmpty
                  ? Container(
                      color: AppColors.lavender,
                      child: const Icon(
                        Icons.explore_rounded,
                        color: AppColors.primary,
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.lavender,
                        child: const Icon(
                          Icons.explore_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.category.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.coral,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  candidate.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (candidate.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    candidate.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
