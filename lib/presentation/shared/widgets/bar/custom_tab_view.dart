import 'package:flutter/material.dart';

class CustomTabView extends StatelessWidget {
  const CustomTabView({super.key, required this.tabs, required this.children})
    : assert(
        tabs.length == children.length && tabs.length >= 2 && tabs.length <= 3,
        'CustomTabView requires 2 or 3 tabs',
      );

  final List<String> tabs;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(
            tabs: tabs.map((t) => Tab(text: t)).toList(),
            labelStyle: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.5),
            indicatorColor: colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: colorScheme.outlineVariant,
          ),
          Expanded(child: TabBarView(children: children)),
        ],
      ),
    );
  }
}
