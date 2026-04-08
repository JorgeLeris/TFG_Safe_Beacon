import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:safe_beacon/core/assets/assets.dart';

enum EmptyStateType { empty, noResults, error }

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.type,
    required this.title,
    required this.description,
  });

  final EmptyStateType type;
  final String title;
  final String description;

  String _imagePath() {
    switch (type) {
      case EmptyStateType.empty:
        return AppImages.noContentImage;
      case EmptyStateType.noResults:
        return AppImages.noResultsImage;
      case EmptyStateType.error:
        return AppImages.errorImage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(_imagePath(), width: 160, height: 160),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
