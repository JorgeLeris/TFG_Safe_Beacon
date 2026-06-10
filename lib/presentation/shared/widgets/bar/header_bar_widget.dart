import 'dart:async';

import 'package:flutter/material.dart';
import 'package:safe_beacon/core/language/l10n/app_localizations.dart';

class SectionHeader extends StatefulWidget {
  const SectionHeader({
    super.key,
    required this.text,
    this.onRefresh,
    this.trailingIcon,
    this.onTrailingIconPressed,
  });

  final String text;
  final Future<void> Function()? onRefresh;

  final IconData? trailingIcon;
  final VoidCallback? onTrailingIconPressed;

  @override
  State<SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<SectionHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    unawaited(_controller.repeat());

    await Future.wait([
      widget.onRefresh?.call() ?? Future.value(),
      Future.delayed(const Duration(milliseconds: 700)),
    ]);

    _controller.stop();
    _controller.reset();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    // Determine which trailing widget to show (refresh takes priority)
    Widget? trailing;

    if (widget.onRefresh != null) {
      trailing = Semantics(
        button: true,
        label: _isRefreshing ? l10n.updating : l10n.update,
        child: GestureDetector(
          onTap: _isRefreshing ? null : _handleRefresh,
          child: RotationTransition(
            turns: _controller,
            child: Icon(
              Icons.refresh_rounded,
              color: colorScheme.onPrimary.withValues(
                alpha: _isRefreshing ? 0.5 : 1.0,
              ),
              size: 25,
            ),
          ),
        ),
      );
    } else if (widget.trailingIcon != null) {
      trailing = Semantics(
        button: true,
        label: l10n.moreInformation,
        child: GestureDetector(
          onTap: widget.onTrailingIconPressed,
          child: Icon(
            widget.trailingIcon,
            color: colorScheme.onPrimary,
            size: 25,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: colorScheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            widget.text,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailing != null) Positioned(right: 0, child: trailing),
        ],
      ),
    );
  }
}
