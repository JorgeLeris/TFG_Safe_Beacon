import 'package:flutter/material.dart';

class SectionButton extends StatelessWidget {
  const SectionButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.contentColor,
    this.showArrow = true,
    this.notificationCount = 0,
  });

  final IconData icon;
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? contentColor;
  final bool showArrow;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = backgroundColor ?? colorScheme.tertiary;
    final fgColor = contentColor ?? colorScheme.onTertiary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 22,
                top: 18,
                right: 22,
                bottom: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: fgColor, size: 28),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            color: fgColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (showArrow)
                        Icon(Icons.arrow_forward_ios, color: fgColor, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        if (notificationCount > 0)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 0.75,
                ),
              ),
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  notificationCount > 99 ? '99+' : '$notificationCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
