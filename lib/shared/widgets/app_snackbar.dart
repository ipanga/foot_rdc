import 'package:flutter/material.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';

/// Snackbar type for different visual styles
enum AppSnackbarType {
  success,
  error,
  info,
  warning,
}

/// A consistent, modern snackbar helper for the entire app.
/// Based on Material 3 design principles with floating behavior,
/// icons, and optional actions.
class AppSnackbar {
  AppSnackbar._();

  /// Shows a styled snackbar with the given message and optional parameters.
  ///
  /// [context] - BuildContext for showing the snackbar
  /// [message] - The main message to display
  /// [type] - The snackbar type (success, error, info, warning)
  /// [icon] - Optional custom icon (defaults based on type)
  /// [actionLabel] - Optional action button label
  /// [onAction] - Optional callback when action button is pressed
  /// [duration] - How long the snackbar is displayed (default: 3 seconds)
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);

    // Clear any existing snackbars
    messenger.hideCurrentSnackBar();

    // Determine colors and icon based on type
    final config = _getTypeConfig(type, colorScheme, icon);

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              config.icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppDesignSystem.space10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: config.backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppDesignSystem.borderRadiusMd,
        ),
        margin: const EdgeInsets.all(AppDesignSystem.space16),
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  /// Shows a success snackbar
  static void showSuccess(
    BuildContext context, {
    required String message,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: AppSnackbarType.success,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Shows an error snackbar
  static void showError(
    BuildContext context, {
    required String message,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: AppSnackbarType.error,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Shows an info snackbar
  static void showInfo(
    BuildContext context, {
    required String message,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: AppSnackbarType.info,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Shows a warning snackbar
  static void showWarning(
    BuildContext context, {
    required String message,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: AppSnackbarType.warning,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Shows a confirmation snackbar with Yes/No buttons
  ///
  /// [context] - BuildContext for showing the snackbar
  /// [message] - The confirmation question to display
  /// [onConfirm] - Callback when user confirms (presses Yes)
  /// [onCancel] - Optional callback when user cancels (presses No)
  /// [confirmLabel] - Label for confirm button (default: 'Oui')
  /// [cancelLabel] - Label for cancel button (default: 'Non')
  /// [duration] - How long the snackbar is displayed (default: 8 seconds)
  static void showConfirmation(
    BuildContext context, {
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmLabel = 'Oui',
    String cancelLabel = 'Non',
    Duration duration = const Duration(seconds: 8),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        showCloseIcon: true,
        closeIconColor: colorScheme.onSurface.withAlpha(179),
        backgroundColor: colorScheme.surface,
        elevation: 8,
        margin: const EdgeInsets.all(AppDesignSystem.space16),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.space12,
          vertical: AppDesignSystem.space10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppDesignSystem.borderRadiusMd,
          side: BorderSide(color: colorScheme.outline.withAlpha(38)),
        ),
        dismissDirection: DismissDirection.horizontal,
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                messenger.hideCurrentSnackBar();
                onConfirm();
              },
              child: Text(confirmLabel),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () {
                messenger.hideCurrentSnackBar();
                onCancel?.call();
              },
              child: Text(cancelLabel),
            ),
          ],
        ),
      ),
    );
  }

  static _SnackbarConfig _getTypeConfig(
    AppSnackbarType type,
    ColorScheme colorScheme,
    IconData? customIcon,
  ) {
    switch (type) {
      case AppSnackbarType.success:
        return _SnackbarConfig(
          icon: customIcon ?? Icons.check_circle_outline,
          backgroundColor: colorScheme.primary,
        );
      case AppSnackbarType.error:
        return _SnackbarConfig(
          icon: customIcon ?? Icons.error_outline,
          backgroundColor: colorScheme.error,
        );
      case AppSnackbarType.warning:
        return _SnackbarConfig(
          icon: customIcon ?? Icons.warning_amber_rounded,
          backgroundColor: const Color(0xFFF59E0B), // AppColors.warning
        );
      case AppSnackbarType.info:
        return _SnackbarConfig(
          icon: customIcon ?? Icons.info_outline,
          backgroundColor: colorScheme.primary,
        );
    }
  }
}

class _SnackbarConfig {
  final IconData icon;
  final Color backgroundColor;

  _SnackbarConfig({
    required this.icon,
    required this.backgroundColor,
  });
}
