import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FootRDC's own advertisers (« Publicités mobiles » on footrdc.com), separate from Google AdMob.
/// The app shows an image and opens an HTTPS link; it never runs anything it receives.
enum AdPlacement {
  homeFeed('home_feed'),
  articleInline('article_inline');

  final String key;
  const AdPlacement(this.key);
}

class CustomAd {
  final int id;
  final AdPlacement placement;
  final String advertiser;
  final String alt;
  final Uri image;
  final int width;
  final int height;
  final Uri link;
  final DateTime? endsAt;
  const CustomAd({
    required this.id,
    required this.placement,
    required this.advertiser,
    required this.alt,
    required this.image,
    required this.width,
    required this.height,
    required this.link,
    this.endsAt,
  });

  /// Width / height, kept within 1:1 and 4:1 so a malformed image can neither take the screen nor become a strip.
  double get aspectRatio => (width / height).clamp(1.0, 4.0);

  bool liveAt(DateTime now) => endsAt == null || now.isBefore(endsAt!);

  /// Only HTTPS links with a host. Images: HTTPS, or a loopback host in debug builds (local QA stack).
  static Uri? httpsLink(Object? raw) {
    if (raw is! String || raw.length > 2000) return null;
    final u = Uri.tryParse(raw);
    if (u == null || u.scheme != 'https' || u.host.isEmpty || u.userInfo.isNotEmpty) return null;
    return u;
  }

  static Uri? imageLink(Object? raw) {
    final secure = httpsLink(raw);
    if (secure != null) return secure;
    if (!kDebugMode || raw is! String) return null;
    final u = Uri.tryParse(raw);
    const loopback = {'127.0.0.1', 'localhost', '10.0.2.2'};
    return u != null && u.scheme == 'http' && loopback.contains(u.host) ? u : null;
  }

  /// Null for anything incomplete or unsafe: such an entry is skipped, never shown half-built.
  static CustomAd? fromJson(Object? json) {
    if (json is! Map) return null;
    final placement = AdPlacement.values.where((p) => p.key == json['placement']).firstOrNull;
    final image = json['image'];
    if (placement == null || image is! Map) return null;
    final src = imageLink(image['url']);
    final link = httpsLink(json['url']);
    final w = image['width'], h = image['height'], id = json['id'];
    if (src == null || link == null || w is! int || h is! int || w < 100 || h < 50 || id is! int) return null;
    final ends = json['ends_at'] is String ? DateTime.tryParse(json['ends_at'] as String) : null;
    final advertiser = (json['advertiser'] is String ? json['advertiser'] as String : '').trim();
    final alt = (json['alt'] is String ? json['alt'] as String : '').trim();
    return CustomAd(
      id: id,
      placement: placement,
      advertiser: advertiser.length > 100 ? advertiser.substring(0, 100) : advertiser,
      alt: alt.isEmpty ? 'Publicité : $advertiser' : (alt.length > 160 ? alt.substring(0, 160) : alt),
      image: src,
      width: w,
      height: h,
      link: link,
      endsAt: ends?.toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'placement': placement.key,
    'advertiser': advertiser,
    'alt': alt,
    'image': {'url': image.toString(), 'width': width, 'height': height},
    'url': link.toString(),
    'ends_at': endsAt?.toIso8601String(),
  };
}

/// What the app knows: one ad per placement (or none), and when it was fetched.
class CustomAdsState {
  final Map<AdPlacement, CustomAd> ads;
  final DateTime? fetchedAt;
  final Duration ttl;
  const CustomAdsState({this.ads = const {}, this.fetchedAt, this.ttl = CustomAdsSource.defaultTtl});

  bool get loaded => fetchedAt != null;
  bool staleAt(DateTime now) => fetchedAt == null || now.difference(fetchedAt!) >= ttl;

  /// The ad for [placement] at [now]: none once it ended, and none from an answer older than twice its lifetime
  /// (offline for long: a paused campaign must not keep showing).
  CustomAd? at(AdPlacement placement, DateTime now) {
    final ad = ads[placement];
    if (ad == null || !ad.liveAt(now) || fetchedAt == null || now.difference(fetchedAt!) > ttl * 2) return null;
    return ad;
  }
}

/// The endpoint `GET /wp-json/rdcfootball/v1/mobile-ads`. Its own small HTTP client (public data, short timeouts).
class CustomAdsSource {
  static const baseUrl = String.fromEnvironment(
    'FOOTRDC_ADS_BASE',
    defaultValue: String.fromEnvironment('RDCF_API_BASE', defaultValue: 'https://footrdc.com/wp-json/rdcfootball/v1'),
  );
  static const defaultTtl = Duration(minutes: 10);
  static const minTtl = Duration(minutes: 2);
  static const maxTtl = Duration(minutes: 30);
  final Dio dio;
  CustomAdsSource([Dio? dio])
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 10),
              responseType: ResponseType.plain,
            ),
          );

  /// Throws on network or format errors. A server without the plugin (404) means « no ads ».
  Future<(Map<AdPlacement, CustomAd>, Duration)> fetch() async {
    final Response<String> r;
    try {
      r = await dio.get<String>('/mobile-ads');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return (<AdPlacement, CustomAd>{}, defaultTtl);
      rethrow;
    }
    final body = jsonDecode(r.data ?? '');
    if (body is! Map || body['version'] != 1 || body['ads'] is! List) throw const FormatException('mobile-ads');
    final ttlSeconds = body['ttl'] is int ? body['ttl'] as int : defaultTtl.inSeconds;
    final ttl = Duration(seconds: ttlSeconds.clamp(minTtl.inSeconds, maxTtl.inSeconds));
    final ads = <AdPlacement, CustomAd>{};
    for (final raw in body['ads'] as List) {
      final ad = CustomAd.fromJson(raw);
      if (ad != null) ads.putIfAbsent(ad.placement, () => ad);
    }
    return (ads, ttl);
  }
}

/// Fetches when the answer is stale (app start, return to the app, a screen with an ad slot), at most one request at
/// a time and not again within a minute after a failure. The last answer is kept on the device for the next start.
class CustomAdsNotifier extends StateNotifier<CustomAdsState> {
  static const storeKey = 'rdcf_custom_ads_v1';
  final CustomAdsSource _source;
  final DateTime Function() _now;
  Future<void>? _inFlight;
  DateTime? _failedAt;
  late final Future<void> restored;

  CustomAdsNotifier(this._source, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const CustomAdsState()) {
    restored = _restore();
  }

  Future<void> _restore() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(storeKey);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final fetched = DateTime.tryParse(j['fetched_at'] as String? ?? '');
      final ads = <AdPlacement, CustomAd>{};
      for (final a in (j['ads'] as List? ?? const [])) {
        final ad = CustomAd.fromJson(a);
        if (ad != null) ads[ad.placement] = ad;
      }
      if (mounted && fetched != null && !state.loaded) {
        state = CustomAdsState(
          ads: ads,
          fetchedAt: fetched,
          ttl: Duration(seconds: j['ttl'] as int? ?? 600),
        );
      }
    } catch (_) {
      // A damaged copy is ignored; the next fetch replaces it.
    }
  }

  Future<void> refreshIfStale() async {
    await restored;
    final now = _now();
    if (!state.staleAt(now)) return;
    if (_failedAt != null && now.difference(_failedAt!) < const Duration(minutes: 1)) return;
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  Future<void> _fetch() async {
    try {
      final (ads, ttl) = await _source.fetch();
      final fetched = _now();
      _failedAt = null;
      debugPrint('custom-ads: ${ads.length} ad(s), ttl ${ttl.inMinutes} min');
      if (!mounted) return;
      state = CustomAdsState(ads: ads, fetchedAt: fetched, ttl: ttl);
      final p = await SharedPreferences.getInstance();
      await p.setString(
        storeKey,
        jsonEncode({
          'fetched_at': fetched.toIso8601String(),
          'ttl': ttl.inSeconds,
          'ads': [for (final a in ads.values) a.toJson()],
        }),
      );
    } catch (e) {
      _failedAt = _now();
      debugPrint('custom-ads: unavailable (${e.runtimeType}); retry in a minute at the earliest');
    }
  }
}

final customAdsSourceProvider = Provider<CustomAdsSource>((ref) => CustomAdsSource());

final customAdsProvider = StateNotifierProvider<CustomAdsNotifier, CustomAdsState>((ref) {
  final notifier = CustomAdsNotifier(ref.watch(customAdsSourceProvider));
  unawaited(notifier.refreshIfStale());
  // Changes made in WordPress reach the app when it comes back to the front with a stale answer.
  final lifecycle = AppLifecycleListener(onResume: () => unawaited(notifier.refreshIfStale()));
  ref.onDispose(lifecycle.dispose);
  return notifier;
});
