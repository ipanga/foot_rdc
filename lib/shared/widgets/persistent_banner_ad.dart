import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foot_rdc/core/constants/ad_constants.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Persistent anchored-adaptive banner ad rendered above the bottom navigation
/// bar. The slot height is reserved BEFORE the ad loads, so the ad container
/// is never resized after `onAdLoaded` (the AdMob policy violation that
/// flagged the app: "Modification du code d'une annonce : redimensionnement
/// du cadre d'une annonce"). Only the child of the [SizedBox] swaps from an
/// empty placeholder to [AdWidget] once the ad is served.
class PersistentBannerAd extends StatefulWidget {
  const PersistentBannerAd({super.key});

  @override
  State<PersistentBannerAd> createState() => _PersistentBannerAdState();
}

class _PersistentBannerAdState extends State<PersistentBannerAd> {
  static const double _fallbackHeight = 60;

  BannerAd? _bannerAd;
  AnchoredAdaptiveBannerAdSize? _adSize;
  bool _isLoaded = false;
  bool _isLoading = false;
  int? _resolvedForWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.of(context).size.width.truncate();
    if (width != _resolvedForWidth) {
      _resolvedForWidth = width;
      _resolveAndLoad(width);
    }
  }

  Future<void> _resolveAndLoad(int width) async {
    if (_isLoading) return;
    _isLoading = true;

    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      width,
    );

    if (!mounted) {
      _isLoading = false;
      return;
    }

    if (size == null) {
      _isLoading = false;
      return;
    }

    // Reserve the correct slot height before the ad arrives.
    _bannerAd?.dispose();
    setState(() {
      _adSize = size;
      _bannerAd = null;
      _isLoaded = false;
    });

    final ad = BannerAd(
      adUnitId: AdConstants.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (failedAd, error) {
          if (kDebugMode) {
            debugPrint('PersistentBannerAd failed to load: $error');
          }
          failedAd.dispose();
        },
      ),
    );

    _bannerAd = ad;
    await ad.load();
    _isLoading = false;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = (_adSize?.height ?? _fallbackHeight).toDouble();
    return SizedBox(
      width: double.infinity,
      height: height,
      child: _isLoaded && _bannerAd != null
          ? AdWidget(ad: _bannerAd!)
          : const SizedBox.shrink(),
    );
  }
}
