import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:foot_rdc/shared/widgets/ads.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:integration_test/integration_test.dart';

import 'qa_support.dart';

/// Ads on a device with Google's test ad units: no banner by the navigation, native ads within Google's frame,
/// inline banner at the end of an article. Never taps an ad.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('ad placements', (tester) async {
    final qa = Qa(tester, binding, 'ads');
    await qa.launch();
    await qa.wait(find.byType(ArticleListItem));
    expect(find.byType(AdWidget), findsNothing, reason: 'no ad pinned to the navigation');
    await qa.shot('accueil-sans-banniere');

    // Feed: scroll until the first native ad is on screen and loaded.
    final slot = find.byType(NativeAdSlot);
    for (var i = 0; i < 40 && slot.evaluate().isEmpty; i++) {
      await qa.scroll(500);
    }
    await tester.ensureVisible(slot.first);
    final frame = find.byKey(const ValueKey('native-ad-frame'));
    for (
      var i = 0;
      i < 60 && find.descendant(of: frame.first, matching: find.byType(AdWidget)).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.ensureVisible(frame.first);
    await qa.pumpFor(const Duration(seconds: 2));
    final size = tester.getSize(frame.first);
    // ignore: avoid_print
    print(
      'QA-INFO native frame ${size.width.toStringAsFixed(0)}x${size.height.toStringAsFixed(0)} loaded=${find.descendant(of: frame.first, matching: find.byType(AdWidget)).evaluate().isNotEmpty}',
    );
    expect(size.width, inInclusiveRange(320, 400));
    expect(size.height, inInclusiveRange(320, 400));
    await qa.shot('fil-annonce-native');

    // Article: the inline banner sits at the end of the body.
    await qa.nav('Édito');
    await qa.wait(find.textContaining('Édito :'));
    await tester.tap(find.textContaining('Édito :').first);
    await qa.wait(find.byType(ArticleDetailScreen));
    await qa.pumpFor(const Duration(seconds: 3));
    await tester.scrollUntilVisible(find.byType(InlineBannerAd), 600, scrollable: find.byType(Scrollable).first);
    for (
      var i = 0;
      i < 60 && find.descendant(of: find.byType(InlineBannerAd), matching: find.byType(AdWidget)).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    final banner = find.descendant(of: find.byType(InlineBannerAd), matching: find.byType(AdWidget));
    // ignore: avoid_print
    print(
      'QA-INFO inline banner loaded=${banner.evaluate().isNotEmpty}${banner.evaluate().isNotEmpty ? ' size=${tester.getSize(banner)}' : ''}',
    );
    if (banner.evaluate().isNotEmpty) await tester.ensureVisible(banner);
    await qa.shot('article-banniere-en-ligne');
    await qa.back();
  });
}
