import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// FootRDC notifications through Firebase Cloud Messaging, registered with the FootRDC server (RDC Football Notify).
/// No account: an installation id and a secret only this app knows; the server stores a hash of the secret.

/// The user's choices. Stored on the device and sent to the server, which applies them.
class NotificationPrefs {
  /// All FootRDC notifications (master switch).
  final bool enabled;

  /// « Articles à la Une ».
  final bool news;

  /// Alerts for followed clubs; when off, the per-type choices are kept but nothing is subscribed.
  final bool matchAlerts;
  final bool prematch;
  final bool kickoff;
  final bool goals;
  final bool result;
  final bool changes;

  /// Optional quiet hours, minutes after midnight in the device's time zone.
  final int? quietStart;
  final int? quietEnd;

  /// Defaults (6 Nov 2026): once the user turns on alerts for followed clubs, kickoff, final result and
  /// postponement/cancellation alerts are on; goals and the one-hour reminder are off. Values the user changed are
  /// kept (see [PushStore.loadPrefs]).
  const NotificationPrefs({
    this.enabled = true,
    this.news = true,
    this.matchAlerts = false,
    this.prematch = false,
    this.kickoff = true,
    this.goals = false,
    this.result = true,
    this.changes = true,
    this.quietStart,
    this.quietEnd,
  });

  bool get quietHours => quietStart != null && quietEnd != null;

  NotificationPrefs copyWith({
    bool? enabled,
    bool? news,
    bool? matchAlerts,
    bool? prematch,
    bool? kickoff,
    bool? goals,
    bool? result,
    bool? changes,
    int? Function()? quietStart,
    int? Function()? quietEnd,
  }) => NotificationPrefs(
    enabled: enabled ?? this.enabled,
    news: news ?? this.news,
    matchAlerts: matchAlerts ?? this.matchAlerts,
    prematch: prematch ?? this.prematch,
    kickoff: kickoff ?? this.kickoff,
    goals: goals ?? this.goals,
    result: result ?? this.result,
    changes: changes ?? this.changes,
    quietStart: quietStart != null ? quietStart() : this.quietStart,
    quietEnd: quietEnd != null ? quietEnd() : this.quietEnd,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'news': news,
    'match_alerts': matchAlerts,
    'prematch': prematch,
    'kickoff': kickoff,
    'goals': goals,
    'result': result,
    'changes': changes,
    'quiet_start': quietStart,
    'quiet_end': quietEnd,
  };

  /// Missing or malformed values take the current defaults.
  factory NotificationPrefs.fromJson(Map<String, dynamic> j) {
    const d = NotificationPrefs();
    bool b(String key, bool fallback) => j[key] is bool ? j[key] as bool : fallback;
    return NotificationPrefs(
      enabled: b('enabled', d.enabled),
      news: b('news', d.news),
      matchAlerts: b('match_alerts', d.matchAlerts),
      prematch: b('prematch', d.prematch),
      kickoff: b('kickoff', d.kickoff),
      goals: b('goals', d.goals),
      result: b('result', d.result),
      changes: b('changes', d.changes),
      quietStart: j['quiet_start'] is int ? j['quiet_start'] as int : null,
      quietEnd: j['quiet_end'] is int ? j['quiet_end'] as int : null,
    );
  }

  /// Keys whose value differs between two sets of preferences.
  static Set<String> changedKeys(NotificationPrefs a, NotificationPrefs b) {
    final x = a.toJson(), y = b.toJson();
    return {
      for (final k in x.keys)
        if (x[k] != y[k]) k,
    };
  }

  /// What the server receives for each followed club (nothing when match alerts are off).
  Map<String, int> clubFlags() => {
    'prematch': matchAlerts && prematch ? 1 : 0,
    'kickoff': matchAlerts && kickoff ? 1 : 0,
    'goals': matchAlerts && goals ? 1 : 0,
    'result': matchAlerts && result ? 1 : 0,
    'changes': matchAlerts && changes ? 1 : 0,
  };

  @override
  bool operator ==(Object other) => other is NotificationPrefs && jsonEncode(toJson()) == jsonEncode(other.toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

/// Device-side storage of preferences and the installation identity.
class PushStore {
  static const prefsKey = 'rdcf_push_prefs';
  static const installKey = 'rdcf_push_install';
  static const secretKey = 'rdcf_push_secret';
  static const codeKey = 'rdcf_push_code';
  static const oneSignalLeftKey = 'rdcf_push_onesignal_left';

  /// Notifications switched on or off before this screen existed (key of the OneSignal-era setting).
  static const legacyEnabledKey = 'notifications_enabled';

  /// Keys the user set explicitly. Only those are kept from storage; every other key follows the current defaults,
  /// so a later change of defaults reaches users who never touched that setting, and never overrides a choice.
  static const explicitKey = 'rdcf_push_explicit';

  Future<NotificationPrefs> loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(prefsKey);
    if (raw != null) {
      try {
        final stored = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final explicit = p.getStringList(explicitKey);
        // Saved before explicit keys were tracked (5.12.11 (34)): every stored value counts as the user's choice.
        if (explicit == null) return NotificationPrefs.fromJson(stored);
        final merged = const NotificationPrefs().toJson();
        for (final k in explicit) {
          if (stored.containsKey(k)) merged[k] = stored[k];
        }
        return NotificationPrefs.fromJson(merged);
      } catch (_) {
        // Corrupt value: start again from defaults.
      }
    }
    return NotificationPrefs(enabled: p.getBool(legacyEnabledKey) ?? true);
  }

  /// Saves [prefs]; [changed] are the keys the user just changed.
  Future<void> savePrefs(NotificationPrefs prefs, {Set<String> changed = const {}}) async {
    final p = await SharedPreferences.getInstance();
    final legacy = p.getString(prefsKey) != null && p.getStringList(explicitKey) == null;
    // Notifications turned off with the OneSignal-era switch stay a choice of the user.
    final oneSignalOff = p.getString(prefsKey) == null && p.getBool(legacyEnabledKey) == false;
    final explicit = legacy
        ? prefs.toJson().keys.toSet()
        : {...?p.getStringList(explicitKey), ...changed, if (oneSignalOff) 'enabled'};
    await p.setString(prefsKey, jsonEncode(prefs.toJson()));
    await p.setStringList(explicitKey, explicit.toList()..sort());
    await p.setBool(legacyEnabledKey, prefs.enabled);
  }

  /// The installation identity, created once and kept across restarts, token refreshes and upgrades.
  Future<(String, String)> identity() async {
    final p = await SharedPreferences.getInstance();
    var install = p.getString(installKey);
    var secret = p.getString(secretKey);
    if (install == null || secret == null) {
      install = uuidV4();
      secret = randomSecret();
      await p.setString(installKey, install);
      await p.setString(secretKey, secret);
    }
    return (install, secret);
  }

  Future<String?> code() async => (await SharedPreferences.getInstance()).getString(codeKey);
  Future<void> saveCode(String code) async => (await SharedPreferences.getInstance()).setString(codeKey, code);
  Future<bool> leftOneSignal() async => (await SharedPreferences.getInstance()).getBool(oneSignalLeftKey) ?? false;
  Future<void> markLeftOneSignal() async => (await SharedPreferences.getInstance()).setBool(oneSignalLeftKey, true);

  static String uuidV4() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  static String randomSecret() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(32, (_) => r.nextInt(256))).replaceAll('=', '');
  }
}

/// What the server says about the service.
class PushConfig {
  final bool enabled;
  final bool leaveOneSignal;
  final List<String> matchAlerts;
  const PushConfig({this.enabled = false, this.leaveOneSignal = false, this.matchAlerts = const []});
}

/// The FootRDC server side (RDC Football Notify). Its own HTTP client: registration bodies carry the secret and the
/// token, so they must never pass through the app's logging interceptor.
class PushBackend {
  /// FOOTRDC_PUSH_BASE overrides only the notification server (device QA points it at nothing, so test devices
  /// never register on Production); otherwise the RDC Football API base.
  static const baseUrl = String.fromEnvironment(
    'FOOTRDC_PUSH_BASE',
    defaultValue: String.fromEnvironment('RDCF_API_BASE', defaultValue: 'https://footrdc.com/wp-json/rdcfootball/v1'),
  );
  static const _hostHeader = String.fromEnvironment('FOOTRDC_HOST_HEADER');
  final Dio dio;

  PushBackend([Dio? dio])
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {if (_hostHeader.isNotEmpty) 'Host': _hostHeader},
            ),
          );

  Future<PushConfig> config() async {
    final r = await dio.get<Map<String, dynamic>>('/notify/config');
    final d = r.data ?? const {};
    return PushConfig(
      enabled: d['enabled'] == true,
      leaveOneSignal: d['onesignal_opt_out'] == true,
      matchAlerts: [for (final k in (d['match_alerts'] as List? ?? const [])) '$k'],
    );
  }

  /// Creates or updates this installation. Returns its diagnostic code.
  Future<String?> register(Map<String, dynamic> body, String secret) async {
    final r = await dio.post<Map<String, dynamic>>(
      '/notify/devices',
      data: body,
      options: Options(headers: {'X-RDCF-Device-Secret': secret}),
    );
    return r.data?['code'] as String?;
  }
}

enum PushPermission { granted, denied, notDetermined }

/// The device side: permission, token, system settings. An interface so the rules can be tested without plugins.
abstract class PushGateway {
  Future<PushPermission> permission();
  Future<PushPermission> requestPermission();
  Future<String?> token();
  Stream<String> get tokenRefresh;
  Future<void> openSettings();
  Future<void> leaveOneSignal();
  Future<void> setOneSignal(bool enabled);
  String get platform;
}

class FirebaseGateway implements PushGateway {
  static const _settings = MethodChannel('footrdc/notification_settings');
  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  /// Firebase may be absent (tests that start the app without `main`): then nothing is registered.
  static bool get _ready => Firebase.apps.isNotEmpty;

  static PushPermission _map(AuthorizationStatus s) => switch (s) {
    AuthorizationStatus.authorized || AuthorizationStatus.provisional => PushPermission.granted,
    AuthorizationStatus.denied || AuthorizationStatus.deniedPermanently => PushPermission.denied,
    AuthorizationStatus.notDetermined => PushPermission.notDetermined,
  };

  @override
  Future<PushPermission> permission() async {
    if (!_ready) return PushPermission.notDetermined;
    try {
      return _map((await _fm.getNotificationSettings()).authorizationStatus);
    } catch (_) {
      return PushPermission.notDetermined;
    }
  }

  @override
  Future<PushPermission> requestPermission() async {
    if (!_ready) return PushPermission.notDetermined;
    try {
      return _map((await _fm.requestPermission(alert: true, badge: true, sound: true)).authorizationStatus);
    } catch (_) {
      return PushPermission.notDetermined;
    }
  }

  /// Null when unavailable (no Play services, APNs not configured, offline): registration then waits for a refresh.
  @override
  Future<String?> token() async {
    if (!_ready) return null;
    try {
      if (Platform.isIOS && await _fm.getAPNSToken() == null) {
        return null;
      }
      return await _fm.getToken();
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<String> get tokenRefresh => _ready ? _fm.onTokenRefresh : const Stream.empty();

  @override
  Future<void> openSettings() async {
    if (Platform.isIOS) {
      await launchUrl(Uri.parse('app-settings:'));
    } else {
      await _settings.invokeMethod<void>('open');
    }
  }

  @override
  Future<void> leaveOneSignal() async {
    try {
      await OneSignal.User.pushSubscription.optOut();
    } catch (_) {
      // OneSignal unavailable: nothing to leave.
    }
  }

  @override
  Future<void> setOneSignal(bool enabled) async {
    try {
      enabled ? await OneSignal.User.pushSubscription.optIn() : await OneSignal.User.pushSubscription.optOut();
    } catch (_) {
      // Ignore: OneSignal is only kept for the transition.
    }
  }

  @override
  String get platform => Platform.isIOS ? 'ios' : 'android';
}
