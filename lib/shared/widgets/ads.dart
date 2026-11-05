import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foot_rdc/core/constants/ad_constants.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ad placements inside content. Rules, from the AdMob policies and the Google Mobile Ads Flutter guides:
/// - the SDK renders the ad at the size it reports; no fixed height, no clipping, no rounded mask on the ad itself;
/// - a native "medium" template sits in Google's recommended frame, 320–400 wide and 320–400 high;
/// - ads stay inside scrolling content, away from the navigation bar, labelled "Publicité" outside the creative.

/// Small label above an ad, outside its frame, so readers can tell it from editorial content.
class AdLabel extends StatelessWidget {
  const AdLabel({super.key});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        'PUBLICITÉ',
        style: TextStyle(fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
      ),
    );
  }
}

/// A native medium-template ad in a list. [loaded] is null when the ad failed: the slot then takes no space.
///
/// Two rules keep every ad asset inside Google's native ad view (the SDK's validator warns « Not all asset views lie
/// inside the native ad view » otherwise):
/// - the platform view is created only once the whole slot is visible in the list: the SDK checks the assets when the
///   view is created, and a view created while partly below the visible area was reported on Android every time
///   (texture-layer platform views; measured 5 Nov 2026, 5 of 5);
/// - on Android the ad uses FootRDC's own layout (`footrdc_native_ad.xml`, every asset inside the native ad view) in a
///   350 dp frame it fills; the same space is reserved before the ad appears, so nothing moves.
class NativeAdSlot extends StatefulWidget {
  final NativeAd ad;
  final bool? loaded;
  const NativeAdSlot({super.key, required this.ad, required this.loaded});

  /// Google's recommended frame for the medium template.
  static const minSide = 320.0;
  static const maxSide = 400.0;

  /// Height of the Android native ad frame (`footrdc_native_ad.xml` fills it).
  static const androidTemplateHeight = 350.0;

  @override
  State<NativeAdSlot> createState() => _NativeAdSlotState();
}

class _NativeAdSlotState extends State<NativeAdSlot> {
  var _onScreen = false;
  ScrollPosition? _position;

  @visibleForTesting
  bool get onScreenForTests => _onScreen;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (!identical(position, _position)) {
      _position?.removeListener(_scheduleCheck);
      _position = position;
      if (!_onScreen) _position?.addListener(_scheduleCheck);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleCheck);
    super.dispose();
  }

  var _checkScheduled = false;

  /// Scrolling moves the slot at the next layout: check after that frame, once per frame.
  void _scheduleCheck() {
    if (_checkScheduled || _onScreen) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      _check();
    });
  }

  /// True once the whole slot is inside the list's visible area (or covers it entirely when it is taller).
  void _check() {
    if (_onScreen || !mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
    final double top, height;
    if (viewport is RenderBox && viewport.attached && viewport.hasSize) {
      top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
      height = viewport.size.height;
    } else {
      top = box.localToGlobal(Offset.zero).dy;
      height = MediaQuery.sizeOf(context).height;
    }
    final bottom = top + box.size.height;
    final fits = top >= 0 && bottom <= height;
    final covers = box.size.height > height && top <= 0 && bottom >= height;
    if (fits || covers) {
      _position?.removeListener(_scheduleCheck);
      setState(() => _onScreen = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loaded = widget.loaded;
    if (loaded == null) return const SizedBox.shrink();
    final android = defaultTargetPlatform == TargetPlatform.android;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Never squeeze the template below its minimum: on a narrower screen, show nothing.
        if (constraints.maxWidth < NativeAdSlot.minSide) return const SizedBox.shrink();
        final width = constraints.maxWidth.clamp(NativeAdSlot.minSide, NativeAdSlot.maxSide);
        final height = android ? NativeAdSlot.androidTemplateHeight : NativeAdSlot.minSide;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AdLabel(),
                  ConstrainedBox(
                    key: const ValueKey('native-ad-frame'),
                    constraints: android
                        ? BoxConstraints.tightFor(width: width, height: height)
                        : const BoxConstraints(
                            minWidth: NativeAdSlot.minSide,
                            minHeight: NativeAdSlot.minSide,
                            maxWidth: NativeAdSlot.maxSide,
                            maxHeight: NativeAdSlot.maxSide,
                          ),
                    child: loaded && _onScreen
                        ? AdWidget(key: ValueKey(widget.ad), ad: widget.ad)
                        : SizedBox(width: width, height: height),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Creates the native ads a list needs. One per [AdConstants.adFrequency] articles, never as the last item.
NativeAd createNativeAd({required void Function(NativeAd ad) onLoaded, required void Function(NativeAd ad) onFailed}) =>
    NativeAd(
      adUnitId: AdConstants.nativeAdUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) => onLoaded(ad as NativeAd),
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) debugPrint('Native ad failed to load: $error');
          onFailed(ad as NativeAd);
          ad.dispose();
        },
      ),
      request: const AdRequest(),
      // Android: FootRDC's own layout (FootrdcNativeAdFactory), whose assets all stay inside the native ad view; the
      // plugin's medium template hides a registered asset for rated ads (SDK validator warning). iOS: the template.
      factoryId: defaultTargetPlatform == TargetPlatform.android ? androidNativeAdFactoryId : null,
      nativeTemplateStyle: defaultTargetPlatform == TargetPlatform.android
          ? null
          : NativeTemplateStyle(templateType: TemplateType.medium),
    )..load();

/// Registered in MainActivity.kt (`NATIVE_AD_FACTORY`).
const androidNativeAdFactoryId = 'footrdcNative';

/// An inline adaptive banner in reading content, following Google's inline adaptive guide: the size comes from the
/// available width; the slot takes space only once the ad has loaded, at the size the SDK reports.
class InlineBannerAd extends StatefulWidget {
  const InlineBannerAd({super.key});
  @override
  State<InlineBannerAd> createState() => _InlineBannerAdState();
}

class _InlineBannerAdState extends State<InlineBannerAd> {
  static const maxHeight = 250;
  BannerAd? _ad;
  AdSize? _size;
  int? _width;

  @visibleForTesting
  static bool enabled = true;

  void _load(int width) {
    if (!enabled || width == _width) return;
    _width = width;
    _ad?.dispose();
    _ad = null;
    _size = null;
    final ad = BannerAd(
      adUnitId: AdConstants.bannerAdUnitId,
      // Capped so a tall format cannot take over the reading flow (Google's maxHeight variant of the inline size).
      size: AdSize.getInlineAdaptiveBannerAdSize(width, maxHeight),
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) async {
          final size = await (loaded as BannerAd).getPlatformAdSize();
          if (!mounted || size == null) return;
          setState(() {
            _ad = loaded;
            _size = size;
          });
        },
        onAdFailedToLoad: (failed, error) {
          if (kDebugMode) debugPrint('Inline banner failed to load: $error');
          failed.dispose();
        },
      ),
    )..load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _load(constraints.maxWidth.truncate());
        final ad = _ad;
        final size = _size;
        if (ad == null || size == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdLabel(),
              SizedBox(
                width: size.width.toDouble(),
                height: size.height.toDouble(),
                child: AdWidget(ad: ad),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Lets widget tests build screens that contain an inline banner without the ads plugin.
@visibleForTesting
void disableInlineBannerAdsForTests() => _InlineBannerAdState.enabled = false;
