import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SelectionGroup extends StatelessWidget {
  const SelectionGroup({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final active = selected == option;
              return ChoiceChip(
                label: Text(option),
                selected: active,
                onSelected: (_) => onSelected(option),
                showCheckmark: false,
                side: BorderSide(
                  color: active ? AppColors.primary : AppColors.border,
                ),
                backgroundColor: AppColors.background,
                selectedColor: AppColors.lavender,
                labelStyle: TextStyle(
                  color: active ? AppColors.primaryDark : AppColors.ink,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
