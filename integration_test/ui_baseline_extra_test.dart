/// Baseline capture of the UI before the refinement (commit 077a341). Kept as the record of how
/// `docs/ui-refinement/screens/baseline/` was produced; the drawer and "Thème et notifications" no longer exist.
@Skip('baseline of 077a341 only')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:integration_test/integration_test.dart';

import 'qa_support.dart';

/// Baseline before the UI refinement: screens the main navigation test does not show.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('baseline extra screens', (tester) async {
    final qa = Qa(tester, binding, 'base');
    await qa.launch();
    await qa.wait(find.byType(ArticleListItem));
    await qa.shot('accueil');
    // Opening the drawer builds the notification settings, which call OneSignal optOut on start (audit finding A2).
    // Android's test runner has no OneSignal channel for that call, so the drawer is captured on iOS only.
    final android = qa.os == 'android';
    if (!android) {
      await tester.tap(find.byTooltip(MaterialLocalizations.of(tester.element(find.byType(Scaffold).first)).openAppDrawerTooltip).first);
      await qa.shot('accueil-tiroir');
      await qa.back();
    }
    await qa.nav('Édito');
    await qa.wait(find.textContaining('Édito :'));
    await tester.tap(find.textContaining('Édito :').first);
    await qa.wait(find.byType(ArticleDetailScreen));
    await qa.shot('article-haut');
    await qa.scroll(1400);
    await qa.shot('article-milieu');
    await qa.scroll(20000);
    await qa.shot('article-fin');
    await qa.back();
    await qa.nav('Plus');
    await qa.wait(find.text('Thème et notifications'));
    await qa.shot('plus');
    if (!android) {
      await tester.tap(find.text('Thème et notifications'));
      await qa.pumpFor(const Duration(seconds: 1));
      await qa.shot('reglages');
      await qa.back();
    }
    await tester.tap(find.text('Articles enregistrés'));
    await qa.pumpFor(const Duration(seconds: 1));
    await qa.shot('enregistres');
    await qa.back();
  });
}
