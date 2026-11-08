import 'dart:convert' show jsonDecode;
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// A public App Store version newer than the installed one.
class StoreRelease {
  final String version;
  final Uri url;
  const StoreRelease(this.version, this.url);
}

/// Optional update suggestion (iOS for now; Android is documented as a later phase).
///
/// The installed version is compared with the public App Store version from Apple's free lookup service (one
/// request at most every [checkEvery], no key, no permission). TestFlight builds never appear there, so they are never
/// offered. « Plus tard » hides the suggestion for that version for [snooze].
class AppUpdate {
  static const checkEvery = Duration(hours: 24);
  static const snooze = Duration(days: 7);
  static const bundleId = 'com.tootiyesolutions.footrdc';
  static const _checkedAt = 'app_update_checked_at';
  static const _storeVersion = 'app_update_store_version';
  static const _storeUrl = 'app_update_store_url';
  static const _dismissedVersion = 'app_update_dismissed_version';
  static const _dismissedAt = 'app_update_dismissed_at';

  /// QA only: pretends this version is installed (`--dart-define=APP_UPDATE_INSTALLED=1.0.0`).
  static const _installedOverride = String.fromEnvironment('APP_UPDATE_INSTALLED');

  /// True when [store] is a later dotted version than [installed] (« 5.12.10 » < « 5.12.11 » < « 5.13 »).
  static bool isNewer(String store, String installed) {
    List<int> parts(String v) =>
        v.split('.').map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
    final a = parts(store), b = parts(installed);
    for (var i = 0; i < a.length || i < b.length; i++) {
      final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  /// The release to suggest, or null. Never throws: any failure means no suggestion.
  static Future<StoreRelease?> check({Dio? dio, DateTime? now}) async {
    if (kIsWeb || !Platform.isIOS) return null;
    try {
      final at = now ?? DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      final installed = _installedOverride.isNotEmpty ? _installedOverride : (await PackageInfo.fromPlatform()).version;
      final checked = DateTime.tryParse(prefs.getString(_checkedAt) ?? '');
      if (checked == null || at.difference(checked) >= checkEvery || at.isBefore(checked)) {
        final found = await _lookup(
          dio ??
              Dio(BaseOptions(connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 8))),
        );
        await prefs.setString(_checkedAt, at.toIso8601String());
        if (found == null) {
          await prefs.remove(_storeVersion);
        } else {
          await prefs.setString(_storeVersion, found.version);
          await prefs.setString(_storeUrl, found.url.toString());
        }
      }
      final version = prefs.getString(_storeVersion);
      final url = Uri.tryParse(prefs.getString(_storeUrl) ?? '');
      if (version == null || url == null || !isNewer(version, installed)) return null;
      final dismissedAt = DateTime.tryParse(prefs.getString(_dismissedAt) ?? '');
      if (prefs.getString(_dismissedVersion) == version && dismissedAt != null && at.difference(dismissedAt) < snooze) {
        return null;
      }
      return StoreRelease(version, url);
    } catch (_) {
      return null;
    }
  }

  static Future<StoreRelease?> _lookup(Dio dio) async {
    final region = PlatformDispatcher.instance.locale.countryCode?.toLowerCase();
    for (final country in {if (region != null && region.length == 2) region, 'cd'}) {
      final response = await dio.get<dynamic>(
        'https://itunes.apple.com/lookup',
        queryParameters: {'bundleId': bundleId, 'country': country},
        options: Options(responseType: ResponseType.json),
      );
      var data = response.data;
      if (data is String) data = jsonDecode(data);
      final results = data is Map ? data['results'] : null;
      if (results is List && results.isNotEmpty && results.first is Map) {
        final r = results.first as Map;
        final version = r['version'], url = Uri.tryParse('${r['trackViewUrl'] ?? ''}');
        if (version is String && url != null && url.hasScheme) return StoreRelease(version, url);
      }
    }
    return null;
  }

  static Future<void> dismiss(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersion, version);
    await prefs.setString(_dismissedAt, DateTime.now().toIso8601String());
  }
}

/// Checked once per app session; null while unknown or when nothing should be suggested.
final appUpdateProvider = FutureProvider<StoreRelease?>((ref) => AppUpdate.check());

/// Set when the suggestion was acted on in this session.
final appUpdateClosedProvider = StateProvider<bool>((ref) => false);

/// A slim, dismissible line above the tab bar: « Nouvelle version disponible » · Plus tard · Mettre à jour.
/// Shown only on the Accueil tab, never over an article, a match or a dialog.
class AppUpdateBanner extends ConsumerWidget {
  const AppUpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final release = ref.watch(appUpdateProvider).valueOrNull;
    final closed = ref.watch(appUpdateClosedProvider);
    final show = release != null && !closed;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: !show
          ? const SizedBox(width: double.infinity)
          : Material(
              key: const ValueKey('app-update-banner'),
              color: scheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                child: Row(
                  children: [
                    Icon(Icons.system_update_outlined, size: 20, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nouvelle version de FootRDC disponible',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(appUpdateClosedProvider.notifier).state = true;
                        AppUpdate.dismiss(release.version);
                      },
                      child: const Text('Plus tard'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(appUpdateClosedProvider.notifier).state = true;
                        launchUrl(release.url, mode: LaunchMode.externalApplication);
                      },
                      child: const Text('Mettre à jour'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
