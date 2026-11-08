import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:foot_rdc/shared/widgets/premium_bottom_nav_bar.dart';
import 'package:integration_test/integration_test.dart';

import 'qa_support.dart';

/// Before/after screens of the 8 Nov navigation pass: article category colour, the bottom bar's selected tab, the bar
/// hiding while reading further and returning when going back up, on Accueil, an article, Matchs, Classement and
/// Plus, in light then dark theme (restored to Automatique at the end). Prints the bar's visible height at each step
/// (QA-BAR) so the run is checkable without the screenshots. Read-only against Production.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('category colour, bar indicator, scroll hide/show, Plus', (tester) async {
    final qa = Qa(tester, binding, 'navscroll');
    await qa.launch();
    await qa.wait(find.byType(ArticleListItem), seconds: 60);

    // Visible height of the bar: its on-screen top edge to the bottom of the screen (0 when slid away).
    void bar(String where) {
      final screen = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final nav = find.byType(PremiumBottomNavBar);
      final top = nav.evaluate().isEmpty ? screen : tester.getTopLeft(nav).dy;
      final rect = tester.getRect(find.byType(Scaffold).first);
      final visible = (rect.bottom - top).clamp(0, screen);
      // ignore: avoid_print
      print('QA-BAR $where visible=${visible.toStringAsFixed(0)}');
    }

    Future<void> read(double dy) async {
      // A slow drag in steps, like a finger reading down the page.
      final size = tester.view.physicalSize / tester.view.devicePixelRatio;
      final gesture = await tester.startGesture(Offset(size.width / 2, size.height * 0.55));
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(Offset(0, -dy / 12));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await qa.pumpFor(const Duration(milliseconds: 900));
    }

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
      bar('accueil-haut-$mode');
      await qa.shot('accueil-haut-$mode');
      await read(500);
      bar('accueil-lecture-$mode');
      await qa.shot('accueil-lecture-$mode');
      await read(-160);
      bar('accueil-retour-$mode');
      await qa.shot('accueil-retour-$mode');

      if (!dark) {
        await tester.tap(find.byType(ArticleListItem).first);
        await qa.wait(find.byType(ArticleDetailScreen));
        await qa.pumpFor(const Duration(seconds: 3));
        await qa.shot('article-$mode');
        await read(500);
        await qa.shot('article-lecture-$mode');
        await qa.back();
        bar('apres-retour-article-$mode');

        for (final tab in ['Matchs', 'Classement']) {
          await qa.nav(tab);
          await qa.pumpFor(const Duration(seconds: 4));
          // « Aujourd'hui » is often too short to scroll; the full calendar is not.
          if (tab == 'Matchs') {
            await tester.tap(find.text('Calendrier'));
            await qa.pumpFor(const Duration(seconds: 4));
          }
          bar('${tab.toLowerCase()}-haut');
          await qa.shot('${tab.toLowerCase()}-haut-$mode');
          await read(400);
          bar('${tab.toLowerCase()}-lecture');
          await qa.shot('${tab.toLowerCase()}-lecture-$mode');
          await read(-160);
          bar('${tab.toLowerCase()}-retour');
        }
      }

      await qa.nav('Plus');
      await qa.wait(find.text('Notifications'));
      bar('plus-$mode');
      await qa.shot('plus-$mode');
      // ignore: avoid_print
      print('QA-PLUS bon-a-savoir=${find.text('Bon à savoir').evaluate().length}');
      await qa.nav('Accueil');
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
