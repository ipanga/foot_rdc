import 'package:flutter/material.dart';

/// A custom search bar widget that provides a text input field with search functionality.
class CustomSearchBar extends StatelessWidget {
  /// Controller for the text input
  final TextEditingController controller;

  /// Callback called when search is submitted
  final VoidCallback? onSubmitted;

  /// Hint text to display in the search field
  final String hintText;

  /// Label text for the search field
  final String? labelText;

  /// Validator function for form validation
  final String? Function(String?)? validator;

  const CustomSearchBar({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.hintText = 'Rechercher...',
    this.labelText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                textInputAction: TextInputAction.search,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  labelText: labelText,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: validator,
                onFieldSubmitted: (_) => onSubmitted?.call(),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                return value.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () {
                            controller.clear();
                          },
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
