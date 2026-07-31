import 'package:flutter/material.dart';

import '../models/planning_location.dart';
import '../models/trip_plan_draft.dart';
import '../models/trip_route.dart';
import '../theme/app_theme.dart';

class TripRouteScreen extends StatelessWidget {
  const TripRouteScreen({
    super.key,
    required this.draft,
    required this.route,
  });

  final TripPlanDraft draft;
  final TripRoute route;

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
            'The journey is
starting to take shape.',
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
          ...points.indexed.map(
            (entry) => _RoutePointCard(
              number: entry.$1 + 1,
              title: 'Discovery zone ${entry.$1 + 1}',
              subtitle: _coordinateLabel(entry.$2),
              icon: Icons.auto_awesome_rounded,
            ),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Next we’ll search these zones using your interests: '
                    '${draft.interests.isEmpty ? 'the best local finds' : draft.interests.join(' • ')}.',
                    style: const TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _coordinateLabel(PlanningLocation point) {
    return '${point.lat.toStringAsFixed(2)}, '
        '${point.lng.toStringAsFixed(2)} • ready for discovery';
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
