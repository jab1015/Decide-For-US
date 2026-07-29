import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/activity.dart';
import '../theme/app_theme.dart';

class DecisionCard extends StatefulWidget {
  const DecisionCard({
    super.key,
    required this.activity,
    required this.index,
    this.isFavoritesView = false,
    this.onDeleted,
  });

  final Activity activity;
  final int index;
  final bool isFavoritesView;
  final VoidCallback? onDeleted;

  @override
  State<DecisionCard> createState() => _DecisionCardState();
}

class _DecisionCardState extends State<DecisionCard> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites') ?? [];

    if (!mounted) return;
    setState(() {
      isFavorite = list.any((item) {
        final decoded = jsonDecode(item);
        return decoded['id'] == widget.activity.id;
      });
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites') ?? [];

    if (isFavorite) {
      list.removeWhere((item) {
        final decoded = jsonDecode(item);
        return decoded['id'] == widget.activity.id;
      });
    } else {
      list.add(jsonEncode(widget.activity.toJson()));
    }

    await prefs.setStringList('favorites', list);

    if (!mounted) return;
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  Future<void> _deleteFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites') ?? [];

    list.removeWhere((item) {
      final decoded = jsonDecode(item);
      return decoded['id'] == widget.activity.id;
    });

    await prefs.setStringList('favorites', list);
    widget.onDeleted?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites')),
      );
    }
  }

  Future<void> _openAddress() async {
    final mapUrl = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': widget.activity.address,
    });

    if (!await launchUrl(mapUrl, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stopLabel = widget.index == 0 ? 'START HERE' : 'THEN';
    final category = widget.activity.category.trim().isEmpty
        ? 'ACTIVITY'
        : widget.activity.category.trim().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.65,
                  child:
                      widget.activity.photoUrl != null &&
                          widget.activity.photoUrl!.isNotEmpty
                      ? Image.network(
                          widget.activity.photoUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              const _ImagePlaceholder(),
                        )
                      : const _ImagePlaceholder(),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.ink.withValues(alpha: 0.8),
                          ],
                          stops: const [0.35, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  top: AppSpacing.md,
                  child: _StopBadge(label: stopLabel),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: 68,
                  bottom: AppSpacing.md,
                  child: IgnorePointer(
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
                        const SizedBox(height: 5),
                        Text(
                          widget.activity.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.94),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: widget.isFavoritesView
                          ? 'Remove from favorites'
                          : (isFavorite
                                ? 'Remove from favorites'
                                : 'Save to favorites'),
                      icon: Icon(
                        widget.isFavoritesView
                            ? Icons.delete_outline_rounded
                            : (isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border),
                        color: widget.isFavoritesView
                            ? AppColors.ink
                            : AppColors.coral,
                      ),
                      onPressed: widget.isFavoritesView
                          ? _deleteFavorite
                          : _toggleFavorite,
                    ),
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
                    widget.activity.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink,
                      fontSize: 15,
                    ),
                  ),
                  if (widget.activity.address.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      button: true,
                      label: 'Open ${widget.activity.address} in Google Maps',
                      child: InkWell(
                        onTap: _openAddress,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 11,
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
                                  widget.activity.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_outward_rounded,
                                size: 17,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
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

class _StopBadge extends StatelessWidget {
  const _StopBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
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
          size: 40,
        ),
      ),
    );
  }
}

