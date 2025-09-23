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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      //margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hintText,
                labelText: labelText,
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
                      icon: const Icon(Icons.clear, color: Colors.grey),
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
