import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/activity.dart';
import '../services/ai_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class LocalEventsScreen extends StatefulWidget {
  const LocalEventsScreen({super.key});

  @override
  State<LocalEventsScreen> createState() => _LocalEventsScreenState();
}

class _LocalEventsScreenState extends State<LocalEventsScreen> {
  List<Activity> _events = const [];
  bool _loading = true;
  String? _error;
  int _radius = 25;
  String _dateRange = '14days';

  ({DateTime start, DateTime end}) get _selectedDates {
    final today = DateUtils.dateOnly(DateTime.now());
    if (_dateRange == 'today') return (start: today, end: today);
    if (_dateRange == 'weekend') {
      final daysUntilSaturday = (DateTime.saturday - today.weekday + 7) % 7;
      final start = today.weekday == DateTime.sunday
          ? today
          : today.add(Duration(days: daysUntilSaturday));
      final end = start.weekday == DateTime.sunday
          ? start
          : start.add(const Duration(days: 1));
      return (start: start, end: end);
    }
    return (start: today, end: today.add(const Duration(days: 13)));
  }

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final location = await LocationService.getLatLng();
      if (location == null) {
        throw const AIServiceException(
          'We need your location to find nearby events.',
        );
      }
      final events = await AIService.getLocalEvents(
        lat: location['lat']!,
        lng: location['lng']!,
        radiusMiles: _radius,
        startDate: _selectedDates.start,
        endDate: _selectedDates.end,
      );
      if (!mounted) return;
      setState(() => _events = events);
    } on AIServiceException catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUrl(String? value) async {
    final uri = Uri.tryParse(value ?? '');
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this event.')),
        );
      }
    }
  }

  Future<void> _openMap(Activity event) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': event.address,
    });
    await _openUrl(uri.toString());
  }

  Future<void> _openCompanionMap(Activity companion) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': companion.address.isNotEmpty
          ? companion.address
          : '${companion.lat},${companion.lng}',
    });
    await _openUrl(uri.toString());
  }

  String _eventTime(Activity event) {
    final date = event.eventLocalDate;
    final time = event.eventLocalTime;
    if (date == null) return 'Date available from event organizer';
    if (time == null || time.isEmpty) return date;
    final parts = time.split(':');
    if (parts.length < 2) return '$date • $time';
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$date • $displayHour:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LOCAL EVENTS+')),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            const Text(
              '✦  HAPPENING NEAR YOU  ✦',
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
              'Make plans while\nthey’re happening.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Live events over the next two weeks, picked for your area.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 10, label: Text('10 mi')),
                ButtonSegment(value: 25, label: Text('25 mi')),
                ButtonSegment(value: 50, label: Text('50 mi')),
              ],
              selected: {_radius},
              onSelectionChanged: (selection) {
                _radius = selection.first;
                _loadEvents();
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'today', label: Text('Today')),
                ButtonSegment(value: 'weekend', label: Text('Weekend')),
                ButtonSegment(value: '14days', label: Text('Next 14 days')),
              ],
              selected: {_dateRange},
              onSelectionChanged: (selection) {
                _dateRange = selection.first;
                _loadEvents();
              },
            ),
            const SizedBox(height: 22),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 70),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _MessageCard(
                icon: Icons.cloud_off_rounded,
                title: 'Events are taking a moment',
                message: _error!,
                onRetry: _loadEvents,
              )
            else if (_events.isEmpty)
              _MessageCard(
                icon: Icons.event_busy_rounded,
                title: 'A quiet couple of weeks',
                message: 'Try a wider distance or check back soon.',
                onRetry: _loadEvents,
              )
            else ...[
              if ((_events.first.searchRadiusMiles ?? _radius) > _radius) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    'We widened the search to '
                    '${_events.first.searchRadiusMiles} miles to find '
                    'more happening near you.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              Text(
                '${_events.length} upcoming events',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ..._events.map(
                (event) => _EventCard(
                  event: event,
                  timeLabel: _eventTime(event),
                  onTickets: () => _openUrl(event.eventUrl),
                  onMap: () => _openMap(event),
                  onCompanionMap: event.companion == null
                      ? null
                      : () => _openCompanionMap(event.companion!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.timeLabel,
    required this.onTickets,
    required this.onMap,
    this.onCompanionMap,
  });

  final Activity event;
  final String timeLabel;
  final VoidCallback onTickets;
  final VoidCallback onMap;
  final VoidCallback? onCompanionMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.9,
            child: event.photoUrl?.isNotEmpty == true
                ? Image.network(
                    event.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _EventPlaceholder(),
                  )
                : const _EventPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  style: const TextStyle(
                    color: AppColors.coral,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(event.description),
                if (event.address.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: onMap,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event.address,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (event.companion != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.lavender.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MAKE IT AN OUTING',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          event.companion!.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(event.companion!.description),
                        if (event.companion!.address.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: onCompanionMap,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.add_location_alt_outlined,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    event.companion!.address,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (event.eventUrl?.isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onTickets,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('VIEW EVENT'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventPlaceholder extends StatelessWidget {
  const _EventPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.dateNight),
      child: Center(
        child: Icon(
          Icons.local_activity_outlined,
          color: AppColors.primary,
          size: 42,
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 42),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
        ],
      ),
    );
  }
}

