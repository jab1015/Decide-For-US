import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/activity.dart';
import '../theme/app_theme.dart';

class ExperienceCard extends StatefulWidget {
  const ExperienceCard({
    super.key,
    required this.first,
    required this.second,
    required this.optionIndex,
  });

  final Activity first;
  final Activity second;
  final int optionIndex;

  @override
  State<ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<ExperienceCard> {
  Set<String> favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favorites') ?? [];
    final ids = saved.map((item) => jsonDecode(item)['id'].toString()).toSet();
    if (mounted) setState(() => favoriteIds = ids);
  }

  Future<void> _toggleFavorite(Activity activity) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favorites') ?? [];
    final isSaved = favoriteIds.contains(activity.id);

    if (isSaved) {
      saved.removeWhere((item) => jsonDecode(item)['id'] == activity.id);
    } else {
      saved.add(jsonEncode(activity.toJson()));
    }

    await prefs.setStringList('favorites', saved);
    if (!mounted) return;
    setState(() {
      if (isSaved) {
        favoriteIds.remove(activity.id);
      } else {
        favoriteIds.add(activity.id);
      }
    });
  }

  Future<void> _openAddress(Activity activity) async {
    final mapUrl = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': activity.address,
    });
    if (!await launchUrl(mapUrl, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  Future<void> _openEvent(Activity activity) async {
    final eventUrl = Uri.tryParse(activity.eventUrl ?? '');
    if (eventUrl == null ||
        !await launchUrl(eventUrl, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this event')),
        );
      }
    }
  }

  Future<void> _openEventInfo(Activity activity) async {
    final infoUrl = Uri.tryParse(activity.infoUrl ?? '');
    if (infoUrl == null ||
        !await launchUrl(infoUrl, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open event information')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final optionName = widget.optionIndex == 0 ? 'OPTION ONE' : 'OPTION TWO';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
              decoration: const BoxDecoration(gradient: AppGradients.primary),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    optionName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '2 stops',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _Stop(
              activity: widget.first,
              label: 'START HERE',
              isFavorite: favoriteIds.contains(widget.first.id),
              onFavorite: () => _toggleFavorite(widget.first),
              onAddress: () => _openAddress(widget.first),
              onEvent: () => _openEvent(widget.first),
              onEventInfo: () => _openEventInfo(widget.first),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: AppColors.background,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'THEN',
                      style: TextStyle(
                        color: AppColors.coral,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
            ),
            _Stop(
              activity: widget.second,
              label: 'NEXT STOP',
              isFavorite: favoriteIds.contains(widget.second.id),
              onFavorite: () => _toggleFavorite(widget.second),
              onAddress: () => _openAddress(widget.second),
              onEvent: () => _openEvent(widget.second),
              onEventInfo: () => _openEventInfo(widget.second),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.activity,
    required this.label,
    required this.isFavorite,
    required this.onFavorite,
    required this.onAddress,
    required this.onEvent,
    required this.onEventInfo,
  });

  final Activity activity;
  final String label;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onAddress;
  final VoidCallback onEvent;
  final VoidCallback onEventInfo;

  @override
  Widget build(BuildContext context) {
    final category = activity.category.trim().isEmpty
        ? 'ACTIVITY'
        : activity.category.trim().toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 1.9,
              child: activity.photoUrl != null && activity.photoUrl!.isNotEmpty
                  ? Image.network(
                      activity.photoUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                    )
                  : const _ImagePlaceholder(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.ink.withValues(alpha: 0.78),
                    ],
                    stops: const [0.38, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              top: AppSpacing.md,
              child: _Pill(label: label),
            ),
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Material(
                color: Colors.white.withValues(alpha: 0.94),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: isFavorite
                      ? 'Remove from favorites'
                      : 'Save to favorites',
                  onPressed: onFavorite,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: AppColors.coral,
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: 68,
              bottom: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      color: Color(0xFFFFC5B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
              ),
              if (activity.address.isNotEmpty) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: onAddress,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activity.address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_outward_rounded,
                          size: 17,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (activity.eventUrl?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onEventInfo,
                    icon: const Icon(Icons.info_outline_rounded),
                    label: const Text('EVENT INFO'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onEvent,
                    icon: const Icon(Icons.local_activity_outlined),
                    label: const Text('TICKETS'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.dateNight),
      child: Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: AppColors.primary,
          size: 38,
        ),
      ),
    );
  }
}
