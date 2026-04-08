import 'package:flutter/material.dart';

/// Data model for a single feature button.
class FeatureGridItem {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? contentColor;

  const FeatureGridItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.contentColor,
  });
}

/// Adaptive grid of square feature buttons.
class FeatureGridButtons extends StatelessWidget {
  final List<FeatureGridItem> items;

  /// Number of columns per full row. Defaults to 2.
  final int columnCount;

  /// Gap between tiles. Defaults to 12.
  final double spacing;

  const FeatureGridButtons({
    super.key,
    required this.items,
    this.columnCount = 2,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += columnCount) {
      final rowItems = items.skip(i).take(columnCount).toList();
      rows.add(_buildRow(context, rowItems));
      if (i + columnCount < items.length) {
        rows.add(SizedBox(height: spacing));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildRow(BuildContext context, List<FeatureGridItem> rowItems) {
    final isFullRow = rowItems.length == columnCount;

    if (isFullRow) {
      // Every tile gets equal width
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int j = 0; j < rowItems.length; j++) ...[
              if (j > 0) SizedBox(width: spacing),
              Expanded(child: _FeatureTile(item: rowItems[j])),
            ],
          ],
        ),
      );
    }

    if (rowItems.length == 1) {
      return _FeatureTile(item: rowItems.first, forceRectangular: true);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int j = 0; j < rowItems.length; j++) ...[
            if (j > 0) SizedBox(width: spacing),
            Expanded(child: _FeatureTile(item: rowItems[j])),
          ],
        ],
      ),
    );
  }
}

/// Individual tile used inside [FeatureGridButtons].
///
/// Square (1:1) when sharing a row, rectangular (2.5:1) when alone in a row.
class _FeatureTile extends StatelessWidget {
  final FeatureGridItem item;

  final bool forceRectangular;

  const _FeatureTile({required this.item, this.forceRectangular = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = item.backgroundColor ?? colorScheme.secondary;
    final fgColor = item.contentColor ?? colorScheme.onSecondary;

    return AspectRatio(
      aspectRatio: forceRectangular ? 2.5 : 1,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: item.onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: forceRectangular
                // Rectangular: icon left, text right
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: fgColor, size: 50),
                      const SizedBox(width: 16),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: fgColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  )
                // Square: icon top, text bottom
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: fgColor, size: 50),
                      const SizedBox(height: 12),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: fgColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
