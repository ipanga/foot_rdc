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
class NativeAdSlot extends StatelessWidget {
  final NativeAd ad;
  final bool? loaded;
  const NativeAdSlot({super.key, required this.ad, required this.loaded});

  /// Google's recommended frame for the medium template.
  static const minSide = 320.0;
  static const maxSide = 400.0;

  @override
  Widget build(BuildContext context) {
    if (loaded == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        // Never squeeze the template below its minimum: on a narrower screen, show nothing.
        if (constraints.maxWidth < minSide) return const SizedBox.shrink();
        final width = constraints.maxWidth.clamp(minSide, maxSide);
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
                    constraints: const BoxConstraints(
                      minWidth: minSide,
                      minHeight: minSide,
                      maxWidth: maxSide,
                      maxHeight: maxSide,
                    ),
                    child: loaded == true ? AdWidget(ad: ad) : const SizedBox(width: minSide, height: minSide),
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
      nativeTemplateStyle: NativeTemplateStyle(templateType: TemplateType.medium),
    )..load();

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
