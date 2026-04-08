import 'package:flutter/material.dart';

class CustomTabView extends StatefulWidget {
  const CustomTabView({
    super.key,
    required this.tabs,
    required this.children,
    this.tabController,
    this.onTabChanged,
  }) : assert(
         tabs.length == children.length && tabs.length >= 2 && tabs.length <= 3,
         'CustomTabView requires 2 or 3 tabs',
       );

  final List<String> tabs;

  final List<Widget> children;

  final TabController? tabController;

  final ValueChanged<int>? onTabChanged;

  @override
  State<CustomTabView> createState() => _CustomTabViewState();
}

class _CustomTabViewState extends State<CustomTabView>
    with SingleTickerProviderStateMixin {
  TabController? _internalController;

  TabController get _controller => widget.tabController ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.tabController == null) {
      _internalController = TabController(
        length: widget.tabs.length,
        vsync: this,
      );
      _internalController!.addListener(() {
        if (!_internalController!.indexIsChanging) {
          widget.onTabChanged?.call(_internalController!.index);
        }
      });
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        TabBar(
          controller: _controller,
          tabs: widget.tabs.map((t) => Tab(text: t)).toList(),
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
        Expanded(
          child: TabBarView(controller: _controller, children: widget.children),
        ),
      ],
    );
  }
}
