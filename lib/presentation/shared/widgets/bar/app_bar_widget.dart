import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, this.showBottomBorder = false});

  final bool showBottomBorder;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return AppBar(
      backgroundColor: colorScheme.surfaceContainer,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: true,
      title: Text(
        l10n.appName,
        style: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottom: showBottomBorder
          ? PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Divider(
                height: 0,
                thickness: 0.75,
                color: colorScheme.outlineVariant,
              ),
            )
          : null,
    );
  }
}
