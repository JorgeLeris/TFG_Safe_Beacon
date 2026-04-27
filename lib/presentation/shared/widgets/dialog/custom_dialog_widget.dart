import 'package:flutter/material.dart';
import 'package:safe_beacon/core/extensions/context_extensions.dart';
import 'package:safe_beacon/presentation/shared/widgets/widgets.dart';

class CustomDialog extends StatefulWidget {
  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    required this.buttonText,
    this.onButtonPressed,
    this.topButtonText,
    this.onTopButtonPressed,
    this.dismissible = true,
    this.secondButtonText,
    this.onSecondButtonPressed,
    this.inputHint,
    this.onInputButtonPressed,
    this.dropdownHint,
    this.dropdownItems,
    this.onFormButtonPressed,
  });

  final String title;
  final Widget content;
  final String buttonText;
  final VoidCallback? onButtonPressed;

  final String? topButtonText;
  final VoidCallback? onTopButtonPressed;

  final bool dismissible;

  final String? secondButtonText;
  final VoidCallback? onSecondButtonPressed;

  final String? inputHint;
  final ValueChanged<String>? onInputButtonPressed;

  final String? dropdownHint;
  final List<DropdownMenuItem<String>>? dropdownItems;

  /// Called when the main button is pressed and both [dropdownHint] and
  /// [inputHint] are provided.
  final void Function(String? dropdownValue, String inputText)?
  onFormButtonPressed;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required Widget content,
    required String buttonText,
    VoidCallback? onButtonPressed,
    String? topButtonText,
    VoidCallback? onTopButtonPressed,
    bool dismissible = true,
    String? secondButtonText,
    VoidCallback? onSecondButtonPressed,
    String? inputHint,
    ValueChanged<String>? onInputButtonPressed,
    String? dropdownHint,
    List<DropdownMenuItem<String>>? dropdownItems,
    void Function(String? dropdownValue, String inputText)? onFormButtonPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (_) => CustomDialog(
        title: title,
        content: content,
        buttonText: buttonText,
        onButtonPressed: onButtonPressed,
        topButtonText: topButtonText,
        onTopButtonPressed: onTopButtonPressed,
        dismissible: dismissible,
        secondButtonText: secondButtonText,
        onSecondButtonPressed: onSecondButtonPressed,
        inputHint: inputHint,
        onInputButtonPressed: onInputButtonPressed,
        dropdownHint: dropdownHint,
        dropdownItems: dropdownItems,
        onFormButtonPressed: onFormButtonPressed,
      ),
    );
  }

  @override
  State<CustomDialog> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  final TextEditingController _inputController = TextEditingController();
  String? _selectedDropdownValue;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;
    final hasInput = widget.inputHint != null;
    final hasSecondButton = widget.secondButtonText != null;
    final bool hasDropdown =
        widget.dropdownHint != null &&
        widget.dropdownItems != null &&
        widget.dropdownItems!.isNotEmpty;
    final bool hasForm = hasDropdown && hasInput;

    return PopScope(
      canPop: widget.dismissible,
      child: Dialog(
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
              top: 22,
              bottom: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title + close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (widget.dismissible)
                      IconButton(
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true).pop(),
                        icon: Icon(Icons.close, color: colorScheme.onSurface),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),

                const Divider(),
                const SizedBox(height: 16),

                Flexible(child: SingleChildScrollView(child: widget.content)),

                const SizedBox(height: 24),

                // Optional text button
                if (widget.topButtonText != null) ...[
                  TextButton(
                    onPressed: widget.onTopButtonPressed,
                    child: Text(
                      widget.topButtonText!,
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: colorScheme.tertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Optional dropdown
                if (hasDropdown) ...[
                  DropdownInputField<String>(
                    hint: widget.dropdownHint!,
                    alignedDropdown: true,
                    items: widget.dropdownItems!,
                    value: _selectedDropdownValue,
                    onChanged: (v) =>
                        setState(() => _selectedDropdownValue = v),
                  ),
                  const SizedBox(height: 16),
                ],

                // Optional input field above the main button
                if (hasInput) ...[
                  InputField(
                    hint: widget.inputHint!,
                    onChanged: (v) => _inputController.text = v,
                  ),
                  const SizedBox(height: 16),
                ],

                // Main button
                CustomFilledButton(
                  text: widget.buttonText,
                  onPressed: () {
                    if (hasForm) {
                      widget.onFormButtonPressed?.call(
                        _selectedDropdownValue,
                        _inputController.text,
                      );
                    } else if (hasInput) {
                      widget.onInputButtonPressed?.call(_inputController.text);
                    } else {
                      (widget.onButtonPressed ??
                          () => Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pop())();
                    }
                  },
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  colorText: colorScheme.onSecondary,
                  fontSizeText: textTheme.labelLarge!.fontSize!,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),

                // Optional second button below the main one
                if (hasSecondButton) ...[
                  const SizedBox(height: 12),
                  CustomFilledButton(
                    text: widget.secondButtonText!,
                    onPressed:
                        widget.onSecondButtonPressed ??
                        () => Navigator.of(context, rootNavigator: true).pop(),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    colorText: colorScheme.onPrimary,
                    fontSizeText: textTheme.labelLarge!.fontSize!,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
