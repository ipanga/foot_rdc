import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized AdMob ad unit IDs for the application.
/// This class provides app IDs, banner and native ad unit IDs for both Android and iOS platforms,
/// with separate IDs for release and test modes.
class AdConstants {
  AdConstants._();

  /// AdMob App ID based on platform and build mode
  static String get appId {
    if (kReleaseMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-8433726715962091~3385387531'  // Android App ID
          : 'ca-app-pub-8433726715962091~7536499845'; // iOS App ID
    } else {
      // Test App IDs for debug mode
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544~3347511713'  // Android Test App ID
          : 'ca-app-pub-3940256099942544~1458002511'; // iOS Test App ID
    }
  }

  /// Banner ad unit ID based on platform and build mode
  static String get bannerAdUnitId {
    if (kReleaseMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-8433726715962091/9671028035'  // Android Banner
          : 'ca-app-pub-8433726715962091/6183356898'; // iOS Banner
    } else {
      // Test Banner IDs for debug mode
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'  // Android Test Banner
          : 'ca-app-pub-3940256099942544/2934735716'; // iOS Test Banner
    }
  }

  /// Native ad unit ID based on platform and build mode
  static String get nativeAdUnitId {
    if (kReleaseMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-8433726715962091/5762012110'  // Android Native
          : 'ca-app-pub-8433726715962091/1275371496'; // iOS Native
    } else {
      // Test Native IDs for debug mode
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/2247696110'  // Android Test Native
          : 'ca-app-pub-3940256099942544/3986624511'; // iOS Test Native
    }
  }
}
