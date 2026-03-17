import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.text, this.onRefresh});

  final String text;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      color: colorScheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onRefresh != null)
            Positioned(
              right: 0,
              child: GestureDetector(
                onTap: onRefresh,
                child: Icon(
                  Icons.refresh_rounded,
                  color: colorScheme.onPrimary,
                  size: 25,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
