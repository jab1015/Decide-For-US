import 'package:flutter/material.dart';

import '../models/planning_option.dart';
import '../models/planning_stop.dart';
import '../models/trip_plan_draft.dart';
import '../models/trip_route.dart';
import '../services/trip_plan_storage.dart';
import '../theme/app_theme.dart';

class TripItineraryScreen extends StatefulWidget {
  const TripItineraryScreen({
    super.key,
    required this.draft,
    required this.route,
    required this.itinerary,
    this.onChangeStops,
  });

  final TripPlanDraft draft;
  final TripRoute route;
  final PlanningOption itinerary;
  final VoidCallback? onChangeStops;

  @override
  State<TripItineraryScreen> createState() => _TripItineraryScreenState();
}

class _TripItineraryScreenState extends State<TripItineraryScreen> {
  bool _saving = false;
  bool _saved = false;

  TripPlanDraft get draft => widget.draft;
  TripRoute get route => widget.route;
  PlanningOption get itinerary => widget.itinerary;

  Future<void> _saveTrip() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await const TripPlanStorage().save(
        draft: draft,
        route: route,
        itinerary: itinerary,
      );
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Road trip saved.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YOUR ITINERARY')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const Text(
            '✦  YOUR ROAD TRIP, DECIDED  ✦',
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
            'A journey worth\nlooking forward to.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 20),
          _SummaryCard(draft: draft, route: route, itinerary: itinerary),
          const SizedBox(height: 22),
          Text('Your stops', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Times are a first-pass plan. Live events keep their official '
            'start times.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          for (final stop in itinerary.stops)
            _ItineraryStopCard(stop: stop),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.onChangeStops ?? () => Navigator.pop(context),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('CHANGE MY STOPS'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _saving ? null : _saveTrip,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _saved ? Icons.check_rounded : Icons.bookmark_add_outlined,
                  ),
            label: Text(_saved ? 'TRIP SAVED' : 'SAVE THIS TRIP'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.draft,
    required this.route,
    required this.itinerary,
  });

  final TripPlanDraft draft;
  final TripRoute route;
  final PlanningOption itinerary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            route.destination.label ?? draft.destinationLabel,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '${route.distanceLabel} • ${route.durationLabel} driving',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${itinerary.stops.length} selected '
            '${itinerary.stops.length == 1 ? 'stop' : 'stops'}'
            ' • ${draft.travelerCount} '
            '${draft.travelerCount == 1 ? 'traveler' : 'travelers'}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ItineraryStopCard extends StatelessWidget {
  const _ItineraryStopCard({required this.stop});

  final PlanningStop stop;

  @override
  Widget build(BuildContext context) {
    final startsAt = stop.startsAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              children: [
                Text(
                  startsAt == null ? 'FLEX' : _time(startsAt),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (startsAt != null)
                  Text(
                    _date(startsAt),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.activity.category.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.coral,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stop.activity.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (stop.activity.address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    stop.activity.address,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (stop.travelMinutesFromPrevious != null)
                      _Detail(
                        icon: Icons.directions_car_outlined,
                        text: '${stop.travelMinutesFromPrevious} min drive',
                      ),
                    if (stop.durationMinutes != null)
                      _Detail(
                        icon: Icons.schedule_outlined,
                        text: '${stop.durationMinutes} min visit',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _time(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute${value.hour >= 12 ? 'P' : 'A'}';
  }

  static String _date(DateTime value) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${months[value.month - 1]} ${value.day}';
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ],
    );
  }
}
