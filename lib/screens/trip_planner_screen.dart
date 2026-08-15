import 'package:flutter/material.dart';

import '../models/trip_plan_draft.dart';
import '../models/trip_route.dart';
import '../services/location_service.dart';
import '../services/trip_route_service.dart';
import '../theme/app_theme.dart';
import 'trip_route_screen.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  final _originController = TextEditingController(text: 'Current location');
  final _destinationController = TextEditingController();
  final _exclusionsController = TextEditingController();

  DateTime? _startsAt;
  DateTime? _endsAt;
  int _travelers = 2;
  String _budget = r'$500–$1,000';
  int _driveInterval = 120;
  final Set<String> _interests = {'Hidden gems'};
  final _routeService = const TripRouteService();
  bool _isResolvingRoute = false;

  static const _interestChoices = [
    'Local food',
    'Scenic stops',
    'History',
    'Outdoors',
    'Family fun',
    'Hidden gems',
  ];

  TripPlanDraft get _draft => TripPlanDraft(
        originLabel: _originController.text,
        destinationLabel: _destinationController.text,
        startsAt: _startsAt,
        endsAt: _endsAt,
        travelerCount: _travelers,
        budget: _budget,
        maxTravelMinutesBetweenStops: _driveInterval,
        interests: _interests.toList(),
        exclusions: _exclusionsController.text
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
      );

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _exclusionsController.dispose();
    super.dispose();
  }

  Future<void> _chooseDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(today.year + 2, 12, 31),
      initialDateRange: _startsAt != null && _endsAt != null
          ? DateTimeRange(start: _startsAt!, end: _endsAt!)
          : null,
      helpText: 'WHEN ARE WE GOING?',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _startsAt = selected.start;
      _endsAt = selected.end;
    });
  }

  Future<void> _reviewTrip() async {
    final draft = _draft;
    if (!draft.isValid || _isResolvingRoute) return;
    FocusScope.of(context).unfocus();
    setState(() => _isResolvingRoute = true);

    try {
      double? originLat;
      double? originLng;
      if (draft.originLabel.toLowerCase() == 'current location') {
        final current = await LocationService.getLatLng();
        originLat = current?['lat'];
        originLng = current?['lng'];
        if (current == null) {
          throw const TripRouteException(
            'Turn on location access or enter a starting city.',
          );
        }
      }

      final route = await _routeService.resolve(
        origin: draft.originLabel,
        destination: draft.destinationLabel,
        maxTravelMinutesBetweenStops: draft.maxTravelMinutesBetweenStops,
        originLat: originLat,
        originLng: originLng,
      );
      if (!mounted) return;
      _showRouteReview(draft, route);
    } on TripRouteException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isResolvingRoute = false);
    }
  }

  void _showRouteReview(TripPlanDraft draft, TripRoute route) {
    final pageContext = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✦  ROUTE DISCOVERED',
                style: TextStyle(
                  color: AppColors.coral,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${route.origin.label ?? draft.originLabel} → '
                '${route.destination.label ?? draft.destinationLabel}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _ReviewLine(
                icon: Icons.route_outlined,
                text: '${route.distanceLabel} • ${route.durationLabel} driving',
              ),
              _ReviewLine(
                icon: Icons.calendar_month_outlined,
                text: _dateLabel,
              ),
              _ReviewLine(
                icon: Icons.group_outlined,
                text: '$_travelers '
                    '${_travelers == 1 ? 'traveler' : 'travelers'}',
              ),
              _ReviewLine(
                icon: Icons.account_balance_wallet_outlined,
                text: '$_budget total budget',
              ),
              _ReviewLine(
                icon: Icons.explore_outlined,
                text: route.corridorPoints.isEmpty
                    ? 'Direct route — destination discoveries come next'
                    : '${route.corridorPoints.length} route '
                        '${route.corridorPoints.length == 1 ? 'zone' : 'zones'} '
                        'ready for discovery',
              ),
              if (_interests.isNotEmpty)
                _ReviewLine(
                  icon: Icons.auto_awesome_outlined,
                  text: _interests.join(' • '),
                ),
              const SizedBox(height: 14),
              const Text(
                'Your route is verified. Next, we’ll discover worthwhile '
                'stops along the way and shape them into a paced itinerary.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(pageContext).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TripRouteScreen(
                        draft: draft,
                        route: route,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('CONTINUE TO MY ROUTE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _dateLabel {
    if (_startsAt == null || _endsAt == null) return 'Choose dates';
    return '${_shortDate(_startsAt!)} – ${_shortDate(_endsAt!)}';
  }

  String _shortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _driveLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '$hours hr' : '$hours hr $remainder min';
  }

  Widget _section({
    required String number,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.lavender,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
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
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valid = _draft.isValid;
    return Scaffold(
      appBar: AppBar(title: const Text('TRIP PLANNER+')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const Text(
            '✦  THE JOURNEY COUNTS TOO  ✦',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.coral,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tell us where.\nWe’ll shape the story.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Plan the destination and the memorable stops along the way.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          _section(
            number: '1',
            title: 'Where are you going?',
            subtitle: 'Start with the route. We’ll make it interesting.',
            child: Column(
              children: [
                TextField(
                  controller: _originController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    'Starting point',
                    Icons.trip_origin_rounded,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _destinationController,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    'Destination',
                    Icons.location_on_outlined,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          _section(
            number: '2',
            title: 'When and with whom?',
            subtitle: 'We’ll pace the trip around your time and crew.',
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: _chooseDates,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(_dateLabel),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Travelers',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: _travelers > 1
                          ? () => setState(() => _travelers--)
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    SizedBox(
                      width: 46,
                      child: Text(
                        '$_travelers',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: _travelers < 12
                          ? () => setState(() => _travelers++)
                          : null,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _section(
            number: '3',
            title: 'What should the trip feel like?',
            subtitle: 'Budget, pace, and the things worth pulling over for.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total trip budget',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [r'Under $500', r'$500–$1,000', r'$1,000–$2,500', r'$2,500+']
                      .map(
                        (value) => ChoiceChip(
                          label: Text(value),
                          selected: _budget == value,
                          onSelected: (_) => setState(() => _budget = value),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Maximum time between interesting stops',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [60, 120, 180]
                      .map(
                        (minutes) => ChoiceChip(
                          label: Text(_driveLabel(minutes)),
                          selected: _driveInterval == minutes,
                          onSelected: (_) =>
                              setState(() => _driveInterval = minutes),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'What sounds good?',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _interestChoices
                      .map(
                        (value) => FilterChip(
                          label: Text(value),
                          selected: _interests.contains(value),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _interests.add(value);
                              } else {
                                _interests.remove(value);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _exclusionsController,
                  decoration: _inputDecoration(
                    'Skip anything? (optional)',
                    Icons.block_outlined,
                  ).copyWith(
                    helperText: 'Example: hiking, seafood, toll roads',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: valid && !_isResolvingRoute ? _reviewTrip : null,
            icon: _isResolvingRoute
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.route_rounded),
            label: Text(
              _isResolvingRoute ? 'MAPPING YOUR ROUTE…' : 'REVIEW MY TRIP',
            ),
          ),
          if (!valid) ...[
            const SizedBox(height: 10),
            Text(
              _draft.validationErrors.first,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
