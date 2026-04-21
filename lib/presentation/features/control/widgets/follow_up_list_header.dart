import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';

/// Header widget for the follow-ups list in the Control screen.
class FollowUpsListHeader extends StatelessWidget {
  const FollowUpsListHeader({
    super.key,
    required this.followUpCount,
    required this.activeFilterCount,
    required this.onFilterTap,
  });

  /// Total number of follow-ups currently listed.
  final int followUpCount;

  /// Number of non-default filters currently applied.
  final int activeFilterCount;

  /// Called when the user taps the filter button.
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final hasFilters = activeFilterCount > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: accent bar + counter label
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: colorScheme.tertiary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.followUpsCount(followUpCount),
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),

        // Right: filter button with optional active state
        GestureDetector(
          onTap: onFilterTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: hasFilters
                  ? colorScheme.tertiary.withValues(alpha: 0.12)
                  : colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasFilters
                    ? colorScheme.tertiary
                    : colorScheme.onSurface.withValues(alpha: 0.15),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 18,
                  color: hasFilters
                      ? colorScheme.tertiary
                      : colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.filter,
                  style: textTheme.labelMedium?.copyWith(
                    color: hasFilters
                        ? colorScheme.tertiary
                        : colorScheme.onSurface.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w600,
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
