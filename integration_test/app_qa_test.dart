import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/navigation/deep_link_handler.dart';
import 'package:foot_rdc/features/football/presentation/widgets/football_widgets.dart';
import 'package:foot_rdc/features/news/data/models/article_model.dart';
import 'package:foot_rdc/main.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

/// Real navigation against the public Production API, read-only. Device QA for iOS and Android.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full navigation', (tester) async {
    await initializeDateFormatting('fr');
    await Hive.initFlutter((await getApplicationDocumentsDirectory()).path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ArticleModelAdapter());
    await Hive.openBox<ArticleModel>('articles');
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    final os = Platform.operatingSystem;
    var step = 0;

    Future<void> wait(Finder finder, {int seconds = 25}) async {
      for (var i = 0; i < seconds * 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (finder.evaluate().isNotEmpty) return;
      }
      // ignore: avoid_print
      print('QA-FAIL step $step: not on screen: ${finder.describeMatch(Plurality.zero)}');
      await binding.takeScreenshot('$os-FAIL-$step');
      throw TestFailure('Not found on screen: $finder');
    }

    Future<void> shot(String name) async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      step++;
      // ignore: avoid_print
      print('QA-STEP $step $name');
      await binding.takeScreenshot('$os-${step.toString().padLeft(2, '0')}-$name');
    }

    Future<void> nav(String label) async {
      await tester.tap(find.text(label).last);
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> tab(String label) async {
      await tester.ensureVisible(find.widgetWithText(Tab, label).first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.widgetWithText(Tab, label).first);
      await tester.pump(const Duration(milliseconds: 500));
    }

    Future<void> back() async {
      appNavigatorKey.currentState!.pop();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    await wait(find.text('Matchs'));
    await wait(find.textContaining('Tout voir'));
    await shot('accueil');

    await nav('Matchs');
    await wait(find.text('Prochains matchs'));
    await shot('matchs-aujourdhui');
    await tab('À venir');
    await wait(find.textContaining('novembre'));
    await shot('matchs-a-venir');
    await tab('Résultats');
    await wait(find.byType(MatchRow));
    await shot('matchs-resultats');
    await tester.tap(find.byType(MatchRow).first);
    await wait(find.text('Fil du match'));
    await shot('match-detail');
    await back();

    await nav('Linafoot');
    await wait(find.text('Derniers résultats'));
    await shot('linafoot-apercu');
    await tab('Calendrier');
    await wait(find.text('Groupe A'));
    await shot('linafoot-calendrier');
    await tab('Classements');
    await wait(find.textContaining('Tableau complet'));
    await shot('linafoot-classements');
    await tester.tap(find.text('Tableau complet'));
    await tester.pump(const Duration(milliseconds: 300));
    await shot('linafoot-classement-complet');
    await tab('Clubs');
    await wait(find.text('Blessing'));
    await shot('linafoot-clubs');
    await tester.tap(find.text('Blessing'));
    await wait(find.text('Prochain match'));
    await shot('club-apercu');
    await tab('Effectif');
    await tester.pump(const Duration(seconds: 2));
    await shot('club-effectif');
    await back();

    // Past season: every tab changes together.
    await tester.tap(find.byTooltip('Changer de saison'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('2025–2026').last);
    await wait(find.text('Saison passée · 2025–2026'));
    await tab('Classements');
    await wait(find.textContaining('Tableau complet'));
    await shot('saison-2025-classements');
    await tab('Résultats');
    await wait(find.byType(MatchRow));
    await shot('saison-2025-resultats');
    await tester.tap(find.byTooltip('Changer de saison'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('2026–2027').last);
    await tester.pump(const Duration(seconds: 1));

    await nav('Édito');
    await wait(find.text('ÉDITO'));
    await tester.pump(const Duration(seconds: 4));
    await shot('edito');

    await nav('Plus');
    await wait(find.text('Clubs suivis'));
    await shot('plus');

    await nav('Accueil');
    await tester.pump(const Duration(seconds: 2));
  });
}
