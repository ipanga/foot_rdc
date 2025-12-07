import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationState {
  final bool enabled;
  final bool hasPermission;
  final bool isSubscribed;

  const NotificationState({
    required this.enabled,
    required this.hasPermission,
    required this.isSubscribed,
  });

  NotificationState copyWith({
    bool? enabled,
    bool? hasPermission,
    bool? isSubscribed,
  }) => NotificationState(
        enabled: enabled ?? this.enabled,
        hasPermission: hasPermission ?? this.hasPermission,
        isSubscribed: isSubscribed ?? this.isSubscribed,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier()
      : super(const NotificationState(
          enabled: false,
          hasPermission: false,
          isSubscribed: false,
        )) {
    _init();
  }

  static const String _notificationKey = 'notifications_enabled';

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEnabled = prefs.getBool(_notificationKey);

    final permission = OneSignal.Notifications.permission;
    final optedIn = OneSignal.User.pushSubscription.optedIn ?? false;

    final derivedEnabled = savedEnabled ?? (permission && optedIn);

    state = NotificationState(
      enabled: derivedEnabled,
      hasPermission: permission,
      isSubscribed: optedIn,
    );

    await _applyEnabledToOneSignal(derivedEnabled);

    OneSignal.User.pushSubscription.addObserver((s) {
      _syncFromOneSignal();
    });
    OneSignal.Notifications.addPermissionObserver((p) {
      _syncFromOneSignal();
    });
  }

  Future<void> _syncFromOneSignal() async {
    final permission = OneSignal.Notifications.permission;
    final optedIn = OneSignal.User.pushSubscription.optedIn ?? false;
    state = state.copyWith(
      hasPermission: permission,
      isSubscribed: optedIn,
    );
  }

  Future<void> _applyEnabledToOneSignal(bool enabled) async {
    if (enabled) {
      await OneSignal.User.pushSubscription.optIn();
    } else {
      await OneSignal.User.pushSubscription.optOut();
    }
    await _syncFromOneSignal();
  }

  Future<NotificationState> toggleNotifications(bool enable) async {
    if (enable && !OneSignal.Notifications.permission) {
      final granted = await OneSignal.Notifications.requestPermission(true);
      if (!granted) {
        state = state.copyWith(enabled: false, hasPermission: false);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_notificationKey, false);
        await _syncFromOneSignal();
        return state;
      }
    }

    state = state.copyWith(enabled: enable);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationKey, enable);
    await _applyEnabledToOneSignal(enable);
    return state;
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(),
);
