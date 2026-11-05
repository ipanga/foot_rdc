import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:integration_test/integration_test.dart';

import 'qa_support.dart';

/// FootRDC advertiser banners on a device, light then dark. Run with
/// `--dart-define=FOOTRDC_ADS_BASE=http://127.0.0.1:8472/wp-json/rdcfootball/v1` against the local dev stack seeded
/// with QA campaigns (Android: `adb reverse tcp:8472 tcp:8472`). With `QA_EXPECT_ADS=false` (no active campaign) the
/// test checks that no slot appears. News and football still come from Production, read-only.
const expectAds = bool.fromEnvironment('QA_EXPECT_ADS', defaultValue: true);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('custom ads: Home and article', (tester) async {
    final qa = Qa(tester, binding, expectAds ? 'pub' : 'sans-pub');
    await qa.launch();
    await qa.wait(find.byType(ArticleListItem), seconds: 60);
    await qa.pumpFor(const Duration(seconds: 3));
    final home = find.byKey(const ValueKey('custom-ad-home_feed'), skipOffstage: false);
    final article = find.byKey(const ValueKey('custom-ad-article_inline'), skipOffstage: false);

    for (final dark in [false, true]) {
      final mode = dark ? 'sombre' : 'clair';
      if (dark) {
        await qa.nav('Plus');
        await tester.tap(find.text('Thème'));
        await qa.wait(find.text('Sombre'));
        await tester.tap(find.text('Sombre'));
        await qa.pumpFor(const Duration(seconds: 1));
        await qa.back();
        await qa.nav('Accueil');
        await qa.pumpFor(const Duration(seconds: 2));
      }
      final list = find.byType(Scrollable).first;
      if (expectAds) {
        await tester.scrollUntilVisible(home, 250, scrollable: list, maxScrolls: 30);
        // Bring the whole banner and the stories around it into view.
        await tester.drag(list, const Offset(0, 200));
        await qa.pumpFor(const Duration(seconds: 2));
        expect(find.text('PUBLICITÉ'), findsWidgets);
        await qa.shot('accueil-$mode');
      } else {
        await tester.drag(list, const Offset(0, -1500));
        await qa.pumpFor(const Duration(seconds: 2));
        expect(home, findsNothing);
        await qa.shot('accueil-$mode');
      }

      // An article long enough for an ad after its introduction.
      await tester.drag(list, const Offset(0, 4000));
      await qa.pumpFor(const Duration(seconds: 1));
      var found = false;
      for (var i = 0; i < 4 && !found; i++) {
        final row = find.byType(ArticleListItem).at(i);
        await tester.ensureVisible(row);
        await qa.pumpFor(const Duration(milliseconds: 500));
        await tester.tap(row);
        await qa.wait(find.byType(ArticleDetailScreen));
        await qa.pumpFor(const Duration(seconds: 3));
        final scroll = find.descendant(of: find.byType(ArticleDetailScreen), matching: find.byType(Scrollable)).first;
        for (var s = 0; s < 12 && article.evaluate().isEmpty; s++) {
          await tester.drag(scroll, const Offset(0, -300));
          await qa.pumpFor(const Duration(milliseconds: 400));
        }
        found = article.evaluate().isNotEmpty;
        if (found || !expectAds) {
          if (found) {
            await tester.ensureVisible(article);
            await tester.drag(scroll, const Offset(0, 150));
            await qa.pumpFor(const Duration(seconds: 2));
          }
          await qa.shot('article-$mode');
          if (!expectAds) {
            expect(article, findsNothing);
            found = true;
          }
        }
        await qa.back();
        await qa.pumpFor(const Duration(seconds: 1));
      }
      expect(found, isTrue, reason: 'an article with the inline ad');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await qa.pumpFor(const Duration(seconds: 1));
    }

    await qa.nav('Plus');
    await tester.tap(find.text('Thème'));
    await qa.wait(find.text('Automatique'));
    await tester.tap(find.text('Automatique'));
    await qa.pumpFor(const Duration(seconds: 1));
    await qa.back();
  });
}
