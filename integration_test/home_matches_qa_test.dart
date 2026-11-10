import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:integration_test/integration_test.dart';

import 'qa_support.dart';

/// Home matches (10 Nov 2026): « Derniers résultats » and « Prochains matchs » carousels between the featured article and
/// the news feed, their horizontal scrolling, a card opening its match, « Tout voir » opening Matchs › Résultats and
/// « Calendrier » opening Matchs › Calendrier, the home tab kept on return; light then dark theme (restored to
/// Automatique). Runs on the old home too (steps for the new sections are skipped) to give the « before » screens.
/// Read-only against Production. Prints QA-HOME lines so the run is checkable without the screenshots.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('home results and fixtures', (tester) async {
    final qa = Qa(tester, binding, 'homematches');
    await qa.launch();
    await qa.wait(find.byType(ArticleListItem), seconds: 60);
    await qa.pumpFor(const Duration(seconds: 3));
    void log(String text) => debugPrint('QA-HOME $text');
    final results = find.text('Derniers résultats');
    final fixtures = find.text('Prochains matchs');

    // Brings a widget to the middle of the screen (the header floats over the top of the list).
    Future<void> centre(Finder finder) async {
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(finder, 120, scrollable: find.byType(Scrollable).first, maxScrolls: 20);
      }
      await Scrollable.ensureVisible(tester.element(finder), alignment: 0.4);
      await qa.pumpFor(const Duration(milliseconds: 800));
    }

    Future<void> reveal(Finder header) => centre(header);

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
      await qa.shot('accueil-haut-$mode');
      // The football sections arrive after the articles: give them time before treating the page as the old home.
      for (var i = 0; i < 100 && results.evaluate().isEmpty && find.text('Matchs').evaluate().length < 2; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      if (results.evaluate().isEmpty) {
        // Old home: one « Matchs » strip.
        await qa.scroll(260);
        await qa.shot('accueil-matchs-$mode');
        log('$mode old-home');
        continue;
      }
      await reveal(results);
      final strips = find.byKey(const ValueKey('home-results-strip'));
      final cards = find.descendant(of: strips, matching: find.byType(InkWell));
      log('$mode results-cards=${cards.evaluate().length} fixtures-header=${fixtures.evaluate().isNotEmpty}');
      await qa.shot('accueil-sections-$mode');
      if (dark) continue;

      // Horizontal scrolling of each carousel, independently.
      await tester.drag(strips, const Offset(-300, 0));
      await qa.pumpFor(const Duration(milliseconds: 800));
      await qa.shot('resultats-defiles');
      await tester.drag(find.byKey(const ValueKey('home-fixtures-strip')), const Offset(-300, 0));
      await qa.pumpFor(const Duration(milliseconds: 800));
      await qa.shot('prochains-defiles');
      await tester.drag(strips, const Offset(600, 0));
      await qa.pumpFor(const Duration(milliseconds: 600));

      // A result card opens its match.
      await tester.tap(cards.first);
      await qa.wait(find.text('Fil du match'));
      await qa.shot('resultat-detail');
      await qa.back();

      // « Tout voir » → Matchs › Résultats; back on Accueil the page is where it was.
      await centre(find.byKey(const ValueKey('home-results-all')));
      await tester.tap(find.byKey(const ValueKey('home-results-all')));
      await qa.pumpFor(const Duration(seconds: 3));
      final selected = find.byWidgetPredicate((w) => w is Tab);
      log('tout-voir tabs=${selected.evaluate().length}');
      await qa.shot('tout-voir-resultats');
      await qa.nav('Accueil');
      await qa.pumpFor(const Duration(seconds: 1));
      log('retour-accueil results-visible=${results.evaluate().isNotEmpty}');

      // « Calendrier » → Matchs › Calendrier.
      await centre(find.byKey(const ValueKey('home-fixtures-all')));
      await tester.tap(find.byKey(const ValueKey('home-fixtures-all')));
      await qa.pumpFor(const Duration(seconds: 3));
      await qa.shot('calendrier');
      await qa.nav('Accueil');
      await qa.pumpFor(const Duration(seconds: 1));

      // A fixture card opens its match.
      await reveal(fixtures);
      await tester.tap(
        find.descendant(of: find.byKey(const ValueKey('home-fixtures-strip')), matching: find.byType(InkWell)).first,
      );
      await qa.wait(find.text('Match'));
      await qa.shot('prochain-detail');
      await qa.back();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await qa.pumpFor(const Duration(milliseconds: 800));
    }

    // Theme back to Automatique.
    await qa.nav('Plus');
    await tester.tap(find.text('Thème'));
    await qa.wait(find.text('Automatique'));
    await tester.tap(find.text('Automatique'));
    await qa.pumpFor(const Duration(seconds: 1));
    await qa.back();
    await qa.nav('Accueil');
    log('done');
  });
}
