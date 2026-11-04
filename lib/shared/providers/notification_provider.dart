import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/notifications/push.dart';
import 'package:foot_rdc/features/football/presentation/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Two separate things decide whether FootRDC notifications arrive:
/// - the device permission, granted or refused in the system dialog or the system settings;
/// - the app preferences (Plus › Notifications), sent to the FootRDC server, which sends only what was chosen.
class NotificationState {
  final NotificationPrefs prefs;
  final PushPermission permission;

  /// The server knows this installation (and its token, when the device has one).
  final bool registered;
  final bool hasToken;

  /// Short code shown in the app, used by an administrator to mark a test device.
  final String? code;

  /// The server's notification service is active (test or on).
  final bool serviceActive;

  /// The last synchronisation failed (offline, server unavailable); it is retried on the next change or start.
  final bool syncFailed;

  const NotificationState({
    this.prefs = const NotificationPrefs(),
    this.permission = PushPermission.notDetermined,
    this.registered = false,
    this.hasToken = false,
    this.code,
    this.serviceActive = false,
    this.syncFailed = false,
  });

  bool get enabled => prefs.enabled;
  bool get hasPermission => permission == PushPermission.granted;
  bool get receiving => enabled && hasPermission;
  bool get blockedByDevice => enabled && permission == PushPermission.denied;

  NotificationState copyWith({
    NotificationPrefs? prefs,
    PushPermission? permission,
    bool? registered,
    bool? hasToken,
    String? code,
    bool? serviceActive,
    bool? syncFailed,
  }) => NotificationState(
    prefs: prefs ?? this.prefs,
    permission: permission ?? this.permission,
    registered: registered ?? this.registered,
    hasToken: hasToken ?? this.hasToken,
    code: code ?? this.code,
    serviceActive: serviceActive ?? this.serviceActive,
    syncFailed: syncFailed ?? this.syncFailed,
  );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final PushGateway _push;
  final PushBackend _backend;
  final PushStore _store;
  final Duration debounce;
  Set<int> _clubs = const {};
  Timer? _timer;
  StreamSubscription<String>? _refresh;
  late final Future<void> ready;
  Future<void>? _running;

  NotificationNotifier(this._push, this._backend, this._store, {this.debounce = const Duration(milliseconds: 600)})
    : super(const NotificationState()) {
    ready = _init();
  }

  /// Whether the app may show the system permission dialog at launch: not after the user turned notifications off.
  static Future<bool> mayPromptAtLaunch() async =>
      (await SharedPreferences.getInstance()).getBool(PushStore.legacyEnabledKey) != false;

  Future<void> _init() async {
    final prefs = await _store.loadPrefs();
    final permission = await _push.permission();
    if (!mounted) return;
    state = state.copyWith(prefs: prefs, permission: permission, code: await _store.code());
    _refresh = _push.tokenRefresh.listen((_) => sync());
    _schedule(); // first registration or refresh of this installation, shortly after start
  }

  @override
  void dispose() {
    _timer?.cancel();
    _refresh?.cancel();
    super.dispose();
  }

  /// Followed clubs (Plus › Clubs suivis, the star on a club page) are the clubs whose alerts are sent.
  void followsChanged(Set<int> clubs) {
    if (setEquals(clubs, _clubs)) return;
    _clubs = Set.of(clubs);
    _schedule();
  }

  Future<void> setPrefs(NotificationPrefs prefs) async {
    await ready;
    final turnedOn = prefs.enabled && !state.prefs.enabled;
    state = state.copyWith(prefs: prefs);
    await _store.savePrefs(prefs);
    if (!await _store.leftOneSignal()) {
      // Until the server takes over, OneSignal follows the master switch, as before.
      await _push.setOneSignal(prefs.enabled);
    }
    if (turnedOn && state.permission == PushPermission.notDetermined) {
      await requestPermission();
    }
    _schedule();
  }

  Future<void> setEnabled(bool enabled) async {
    await ready;
    await setPrefs(state.prefs.copyWith(enabled: enabled));
  }

  Future<void> requestPermission() async {
    final p = await _push.requestPermission();
    if (!mounted) return;
    state = state.copyWith(permission: p);
    _schedule();
  }

  Future<void> openDeviceSettings() => _push.openSettings();

  /// Asks the system first (Android reports « refused » before the first request); only a real refusal opens the
  /// system settings, where the user can allow FootRDC.
  Future<void> allowOrOpenSettings() async {
    await requestPermission();
    if (state.permission != PushPermission.granted) await _push.openSettings();
  }

  /// Back from the system settings, or the app resumed.
  Future<void> refresh() async {
    final p = await _push.permission();
    if (!mounted) return;
    final changed = p != state.permission;
    state = state.copyWith(permission: p);
    if (changed) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(debounce, () => sync());
  }

  /// Sends this installation's token and choices to the server. Safe to call often; one call at a time.
  Future<void> sync() async {
    await ready;
    if (_running != null) {
      await _running;
    }
    final run = _sync();
    _running = run;
    try {
      await run;
    } finally {
      if (identical(_running, run)) _running = null;
    }
  }

  Future<void> _sync() async {
    final (install, secret) = await _store.identity();
    final token = state.hasPermission ? await _push.token() : null;
    final prefs = state.prefs;
    final offset = DateTime.now().timeZoneOffset.inMinutes;
    int? utc(int? local) => local == null ? null : (local - offset) % 1440;
    final body = {
      'install_id': install,
      'platform': _push.platform,
      'app_version': '',
      'locale': 'fr',
      'timezone': 'UTC',
      'token': ?token,
      'prefs': {
        'enabled': prefs.enabled,
        'news': prefs.news,
        'quiet_start': prefs.quietHours ? utc(prefs.quietStart) : null,
        'quiet_end': prefs.quietHours ? utc(prefs.quietEnd) : null,
      },
      'follows': [
        if (prefs.matchAlerts)
          for (final id in _clubs) {'team_id': id, ...prefs.clubFlags()},
      ],
    };
    try {
      final code = await _backend.register(body, secret);
      if (code != null) await _store.saveCode(code);
      final config = await _backend.config();
      if (config.leaveOneSignal && !await _store.leftOneSignal()) {
        await _push.leaveOneSignal();
        await _store.markLeftOneSignal();
      }
      if (!mounted) return;
      state = state.copyWith(
        registered: true,
        hasToken: token != null,
        code: code,
        serviceActive: config.enabled,
        syncFailed: false,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(syncFailed: true);
    }
  }
}

final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final notifier = NotificationNotifier(FirebaseGateway(), PushBackend(), PushStore());
  ref.listen<Set<int>>(favoriteClubsProvider, (_, next) => notifier.followsChanged(next), fireImmediately: true);
  return notifier;
});
