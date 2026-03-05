import 'package:flutter/material.dart';

class CustomFilledButton extends StatelessWidget {
  const CustomFilledButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.colorText,
    this.fontSizeText,
    this.icon,
    this.padding,
  });

  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? colorText;
  final double? fontSizeText;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final textWidget = Text(
      text,
      textAlign: TextAlign.center,
      overflow: TextOverflow.visible,
      softWrap: true,
      style: TextStyle(
        fontSize: fontSizeText ?? textTheme.labelLarge!.fontSize!,
        color: colorText ?? colorScheme.onPrimary,
      ),
    );

    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? colorScheme.inversePrimary,
        foregroundColor: foregroundColor ?? colorScheme.onPrimary,
        shape: const StadiumBorder(),
        padding: padding,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: colorText ?? colorScheme.onPrimary, size: 22),
                const SizedBox(width: 8),
                Flexible(child: textWidget),
              ],
            )
          : textWidget,
    );
  }
}
