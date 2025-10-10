import 'package:flutter/material.dart';

/// A custom search bar widget that provides a text input field with search functionality.
///
/// This widget combines a text field with built-in validation and submit handling.
/// It supports both keyboard submission (search key) and programmatic submission.
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
    this.hintText = 'Search...',
    this.labelText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      //margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: hintText,
                labelText: labelText,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                border: InputBorder.none,
              ),
              validator: validator,
              // Submit when pressing the search/enter key
              onFieldSubmitted: (_) => onSubmitted?.call(),
            ),
          ),
          // Add a clear button when there's text
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              return value.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        controller.clear();
                      },
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
