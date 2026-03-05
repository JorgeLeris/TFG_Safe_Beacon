import 'package:flutter/material.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class CustomDialog extends StatelessWidget {
  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    required this.buttonText,
    this.onButtonPressed,
  });

  final String title;
  final Widget content;
  final String buttonText;
  final VoidCallback? onButtonPressed;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required Widget content,
    required String buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return showDialog(
      context: context,
      builder: (_) => CustomDialog(
        title: title,
        content: content,
        buttonText: buttonText,
        onButtonPressed: onButtonPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            right: 22,
            left: 22,
            top: 12,
            bottom: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Flexible(child: SingleChildScrollView(child: content)),

              const SizedBox(height: 24),

              CustomFilledButton(
                text: buttonText,
                onPressed: onButtonPressed ?? () => Navigator.of(context).pop(),
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
                colorText: colorScheme.onSecondary,
                fontSizeText: textTheme.labelLarge!.fontSize!,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
