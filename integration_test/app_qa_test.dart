import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/navigation/deep_link_handler.dart';
import 'package:foot_rdc/features/football/presentation/widgets/football_widgets.dart';
import 'package:foot_rdc/features/editorial/presentation/providers/editorial_providers.dart';
import 'package:foot_rdc/features/editorial/presentation/providers/editorial_cache_provider.dart';
import 'package:foot_rdc/features/home/presentation/app_tabs.dart';
import 'package:foot_rdc/features/home/presentation/screens/home_screen.dart';
import 'package:foot_rdc/features/news/presentation/providers/article_cache_provider.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:foot_rdc/features/news/data/models/article_model.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/main.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

const footballApi = 'https://footrdc.com/wp-json/rdcfootball/v1';
const wordpressApi = 'https://footrdc.com/wp-json/wp/v2';

Future<List<dynamic>> publicJson(String url) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(Uri.parse(url))).close();
    return jsonDecode(await response.transform(utf8.decoder).join()) as List<dynamic>;
  } finally {
    client.close();
  }
}

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
      // Android's screenshot helper fails now and then with "Could not copy the pixels". Only that call is retried.
      for (var attempt = 1; ; attempt++) {
        try {
          await binding.takeScreenshot('$os-${step.toString().padLeft(2, '0')}-$name');
          break;
        } on PlatformException catch (error) {
          if (attempt == 4) rethrow;
          // ignore: avoid_print
          print('QA-SHOT-RETRY step $step attempt $attempt: ${error.message}');
          await tester.pump(const Duration(seconds: 1));
        }
      }
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
      // The route Android's back button takes.
      await tester.binding.handlePopRoute();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    await wait(find.text('Matchs'));
    final positions = [for (final tab in AppTab.values) tester.getCenter(find.text(tab.label).last).dx];
    expect(positions, [...positions]..sort(), reason: 'tabs read ${AppTab.values.map((t) => t.label)}');
    await wait(find.textContaining('Tout voir'));
    await shot('accueil');

    await nav('Matchs');
    await wait(find.text('Prochains matchs'));
    await shot('matchs-aujourdhui');
    await tab('Calendrier');
    await wait(find.textContaining('novembre'));
    await shot('matchs-a-venir');
    await tab('Résultats');
    await wait(find.byType(MatchRow));
    await shot('matchs-resultats');
    await tester.tap(find.byType(MatchRow).first);
    await wait(find.text('Fil du match'));
    await shot('match-detail');
    await back();

    await nav('Classement');
    await wait(find.textContaining('Tableau complet'));
    await shot('classement-groupe-a');
    await tester.tap(find.text('Tableau complet'));
    await tester.pump(const Duration(milliseconds: 300));
    await shot('classement-complet');
    await tab('Groupe B');
    await tester.pump(const Duration(seconds: 1));
    await shot('classement-groupe-b');
    await tab('Clubs');
    await wait(find.text('AC Rangers'));
    await shot('linafoot-clubs');
    await tester.enterText(find.byType(TextField).first, 'Blessing');
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    await tester.tap(find.text('Blessing').last);
    await wait(find.text('Prochain match'));
    await shot('club-apercu');
    await tab('Effectif');
    await tester.pump(const Duration(seconds: 2));
    await shot('club-effectif');
    await back();

    // Past season: Classement and Matchs change together.
    await tester.tap(find.byTooltip('Changer de saison'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('2025–2026').last);
    await wait(find.text('Saison passée · 2025–2026'));
    await wait(find.textContaining('Tableau complet'));
    await shot('saison-2025-classement');
    await nav('Matchs');
    await tab('Résultats');
    await wait(find.text('Saison passée · 2025–2026'));
    await wait(find.byType(MatchRow));
    await shot('saison-2025-resultats');
    await tester.tap(find.text('Saison en cours'));
    await tester.pump(const Duration(seconds: 1));
    // Already on a tab root: no system back here (on Android it would send the app to the background).
    final finished = await publicJson('$footballApi/matches/finished?season_id=324&limit=1');
    pushLinks.add('footrdc://match/${finished[0]['id']}');
    await wait(find.text('Fil du match'));
    await shot('lien-match');
    await back();
    await nav('Classement');
    final article = await publicJson('$wordpressApi/posts?per_page=1&_fields=id');
    pushLinks.add('footrdc://article/${article[0]['id']}');
    await wait(find.byType(ArticleDetailScreen), seconds: 40);
    await tester.pump(const Duration(seconds: 2));
    await shot('lien-article');
    await back();
    await nav('Plus');
    final edito = await publicJson('$wordpressApi/posts?categories=47&per_page=1&_fields=link');
    pushLinks.add(edito[0]['link'] as String);
    await wait(find.byType(ArticleDetailScreen), seconds: 40);
    await tester.pump(const Duration(seconds: 2));
    await shot('lien-edito');
    await back();

    // A tab reopened after its cache expired refreshes in place. Forced, so the check does not depend on device speed.
    await nav('Accueil');
    final container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
    await wait(find.byType(ArticleListItem));
    container.read(articleCacheProvider.notifier).clearCache();
    await tester.pump();
    await tester.pump();
    await wait(find.byType(ArticleListItem));
    for (var i = 0; i < 20 && container.read(articleCacheProvider).articles.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(container.read(articleCacheProvider).articles, isNotEmpty);
    await nav('Édito');
    final edito2 = editorialCacheProvider(EditorialChannel.edito.slug);
    container.read(edito2.notifier).clearCache();
    await tester.pump();
    await tester.pump();
    for (var i = 0; i < 40 && container.read(edito2).articles.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(container.read(edito2).articles, isNotEmpty);
    await nav('Accueil');
    await tester.pump(const Duration(seconds: 2));
    await shot('accueil-apres-actualisation');
  });
}
