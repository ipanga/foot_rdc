import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two separate things decide whether FootRDC notifications arrive:
/// - the device permission, granted or refused in the system dialog or the system settings;
/// - the app preference, the switch in Plus › Notifications, sent to OneSignal as opt in or opt out.
/// Only an explicit choice of the user changes the app preference; starting the app never does.
class NotificationState {
  /// The app preference. On by default; off only after the user turned it off.
  final bool enabled;

  /// The device permission.
  final bool hasPermission;

  /// OneSignal's current opt-in for this device's single push subscription.
  final bool isSubscribed;

  const NotificationState({required this.enabled, required this.hasPermission, required this.isSubscribed});

  /// Notifications actually arrive.
  bool get receiving => enabled && hasPermission && isSubscribed;

  /// The user wants notifications but the device refuses them.
  bool get blockedByDevice => enabled && !hasPermission;

  NotificationState copyWith({bool? enabled, bool? hasPermission, bool? isSubscribed}) => NotificationState(
    enabled: enabled ?? this.enabled,
    hasPermission: hasPermission ?? this.hasPermission,
    isSubscribed: isSubscribed ?? this.isSubscribed,
  );
}

/// The OneSignal calls the preference needs, behind an interface so the rules can be tested without the plugin.
abstract class PushGateway {
  bool get permission;
  bool get optedIn;
  Future<bool> requestPermission({required bool fallbackToSettings});
  Future<void> optIn();
  Future<void> optOut();
  void onChange(void Function() listener);
}

class OneSignalGateway implements PushGateway {
  const OneSignalGateway();
  @override
  bool get permission => OneSignal.Notifications.permission;
  @override
  bool get optedIn => OneSignal.User.pushSubscription.optedIn ?? false;
  @override
  Future<bool> requestPermission({required bool fallbackToSettings}) =>
      OneSignal.Notifications.requestPermission(fallbackToSettings);
  @override
  Future<void> optIn() => OneSignal.User.pushSubscription.optIn();
  @override
  Future<void> optOut() => OneSignal.User.pushSubscription.optOut();
  @override
  void onChange(void Function() listener) {
    OneSignal.User.pushSubscription.addObserver((_) => listener());
    OneSignal.Notifications.addPermissionObserver((_) => listener());
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final PushGateway _push;
  late final Future<void> ready;

  NotificationNotifier([this._push = const OneSignalGateway()])
    : super(const NotificationState(enabled: true, hasPermission: false, isSubscribed: false)) {
    ready = _init();
  }

  static const preferenceKey = 'notifications_enabled';

  /// Whether the app may show the system permission dialog at launch: not after the user turned notifications off.
  static Future<bool> mayPromptAtLaunch() async =>
      (await SharedPreferences.getInstance()).getBool(preferenceKey) != false;

  Future<void> _init() async {
    final saved = (await SharedPreferences.getInstance()).getBool(preferenceKey);
    // Nothing is sent to OneSignal here. A user who turned notifications off stays opted out because OneSignal keeps
    // that choice; a user who never chose keeps OneSignal's default.
    if (!mounted) return;
    state = NotificationState(enabled: saved ?? true, hasPermission: _push.permission, isSubscribed: _push.optedIn);
    _push.onChange(_sync);
  }

  void _sync() {
    if (!mounted) return;
    state = state.copyWith(hasPermission: _push.permission, isSubscribed: _push.optedIn);
  }

  Future<void> _save(bool enabled) async => (await SharedPreferences.getInstance()).setBool(preferenceKey, enabled);

  /// The user's choice in Plus › Notifications.
  Future<void> setEnabled(bool enable) async {
    await ready;
    state = state.copyWith(enabled: enable);
    await _save(enable);
    if (!enable) {
      await _push.optOut();
      _sync();
      return;
    }
    if (!_push.permission) {
      // The system dialog appears only if the user has not answered it yet; otherwise this returns false at once.
      await _push.requestPermission(fallbackToSettings: false);
    }
    await _push.optIn();
    _sync();
  }

  /// After a refusal, the only way back is the system settings. OneSignal offers to open them.
  Future<void> openDeviceSettings() async {
    await _push.requestPermission(fallbackToSettings: true);
    _sync();
  }

  /// Called when the app returns to the foreground, after the user may have changed the system settings.
  void refresh() => _sync();
}

final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(),
);
