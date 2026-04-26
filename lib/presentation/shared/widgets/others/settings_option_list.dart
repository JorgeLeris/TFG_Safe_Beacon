import 'package:flutter/material.dart';

/// Data model for a single tappable row.
class SettingsOption {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onPressed;

  /// When non-null a [Switch] is rendered as the trailing widget.
  final bool? switchValue;

  /// Called with the new value when the switch is toggled.
  final ValueChanged<bool>? onSwitchChanged;

  const SettingsOption({
    required this.icon,
    required this.title,
    required this.description,
    this.onPressed,
    this.switchValue,
    this.onSwitchChanged,
  });
}

/// A titled list of tappable option rows.
class SettingsOptionsList extends StatelessWidget {
  final String sectionTitle;
  final List<SettingsOption> options;

  final double horizontalPadding;

  const SettingsOptionsList({
    super.key,
    required this.sectionTitle,
    required this.options,
    this.horizontalPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            sectionTitle,
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Option rows — dividers bleed full width, content is padded
        ...options.map(
          (option) => _SettingsOptionRow(
            option: option,
            horizontalPadding: horizontalPadding,
          ),
        ),

        // Closing bottom divider
        const Divider(height: 1),
      ],
    );
  }
}

class _SettingsOptionRow extends StatefulWidget {
  final SettingsOption option;
  final double horizontalPadding;

  const _SettingsOptionRow({required this.option, this.horizontalPadding = 0});

  @override
  State<_SettingsOptionRow> createState() => _SettingsOptionRowState();
}

class _SettingsOptionRowState extends State<_SettingsOptionRow> {
  late bool _switchValue;

  @override
  void initState() {
    super.initState();
    _switchValue = widget.option.switchValue ?? false;
  }

  @override
  void didUpdateWidget(_SettingsOptionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.option.switchValue != null &&
        widget.option.switchValue != oldWidget.option.switchValue) {
      _switchValue = widget.option.switchValue!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSwitch = widget.option.switchValue != null;

    return Column(
      children: [
        const Divider(height: 1),
        InkWell(
          onTap: isSwitch ? null : widget.option.onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: widget.horizontalPadding,
            ),
            child: Row(
              children: [
                // Leading icon
                Icon(widget.option.icon, color: colorScheme.tertiary, size: 28),
                const SizedBox(width: 14),

                // Title + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.option.title,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.option.description,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Trailing: switch or navigation arrow
                if (isSwitch)
                  Switch(
                    value: _switchValue,
                    onChanged: (value) {
                      setState(() => _switchValue = value);
                      widget.option.onSwitchChanged?.call(value);
                    },
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: colorScheme.tertiary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
