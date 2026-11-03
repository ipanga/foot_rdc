import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/navigation/deep_link_handler.dart';
import 'package:foot_rdc/features/football/presentation/screens/club_detail_screen.dart';
import 'package:foot_rdc/features/football/presentation/widgets/related_clubs.dart';
import 'package:foot_rdc/features/news/data/models/article_model.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/main.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

/// Club news and related clubs on a device. Read-only. Production by default; for Staging through a local tunnel:
///   QA_FLUTTER_ARGS="--dart-define=FOOTRDC_WP_BASE=http://127.0.0.1:18080/wp-json
///     --dart-define=RDCF_API_BASE=http://127.0.0.1:18080/wp-json/rdcfootball/v1
///     --dart-define=FOOTRDC_HOST_HEADER=`staging host`"
/// Article ids come from QA_ARTICLE_MULTI (several clubs) and QA_ARTICLE_NONE (no club).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const multi = int.fromEnvironment('QA_ARTICLE_MULTI', defaultValue: 72740);
  const none = int.fromEnvironment('QA_ARTICLE_NONE', defaultValue: 72748);
  const single = int.fromEnvironment('QA_ARTICLE_ONE', defaultValue: 72852);

  testWidgets('club news and related clubs', (tester) async {
    await initializeDateFormatting('fr');
    await Hive.initFlutter((await getApplicationDocumentsDirectory()).path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ArticleModelAdapter());
    await Hive.openBox<ArticleModel>('articles');
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    final os = Platform.operatingSystem;
    var step = 0;

    Future<void> wait(Finder finder, {int seconds = 30}) async {
      for (var i = 0; i < seconds * 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (finder.evaluate().isNotEmpty) return;
      }
      // ignore: avoid_print
      print('QA-FAIL step $step: not on screen: ${finder.describeMatch(Plurality.zero)}');
      await binding.takeScreenshot('$os-clubs-FAIL-$step');
      throw TestFailure('Not found on screen: $finder');
    }

    Future<void> shot(String name) async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      step++;
      // ignore: avoid_print
      print('QA-STEP $step $name');
      for (var attempt = 1; ; attempt++) {
        try {
          await binding.takeScreenshot('$os-clubs-${step.toString().padLeft(2, '0')}-$name');
          break;
        } on PlatformException catch (error) {
          if (attempt == 4) rethrow;
          // ignore: avoid_print
          print('QA-SHOT-RETRY step $step attempt $attempt: ${error.message}');
          await tester.pump(const Duration(seconds: 1));
        }
      }
    }

    Future<void> back() async {
      await tester.binding.handlePopRoute();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    Future<void> toRelatedClubs() async {
      await wait(find.byType(ArticleDetailScreen));
      await tester.pump(const Duration(seconds: 2));
      await tester.scrollUntilVisible(find.byType(RelatedClubsSection), 400, scrollable: find.byType(Scrollable).first);
      await tester.pump(const Duration(seconds: 1));
    }

    await wait(find.text('Accueil'));

    // Club → Actualités → article → Clubs liés → club → back, back.
    pushLinks.add('footrdc://club/4');
    await wait(find.byType(ClubDetailScreen));
    await tester.tap(find.widgetWithText(Tab, 'Actualités'));
    await wait(find.byType(ClubNewsTile));
    await shot('club-actualites');

    // Pagination: a full first page offers more; loading it appends rows below the first page.
    final vertical = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).last;
    await tester.scrollUntilVisible(find.text('Charger plus'), 500, scrollable: vertical);
    final firstPage = find.byType(ClubNewsTile, skipOffstage: false).evaluate().length;
    await tester.tap(find.text('Charger plus'));
    for (var i = 0; i < 50 && find.byType(ClubNewsTile, skipOffstage: false).evaluate().length <= firstPage; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    final twoPages = find.byType(ClubNewsTile, skipOffstage: false).evaluate().length;
    // ignore: avoid_print
    print('QA-INFO club news rows: page 1 built $firstPage, after Charger plus $twoPages');
    expect(twoPages, greaterThan(firstPage));
    await shot('club-actualites-page-2');
    int newsLength() => tester
        .widget<ListView>(find.ancestor(of: find.byType(ClubNewsTile).first, matching: find.byType(ListView)))
        .childrenDelegate
        .estimatedChildCount!;
    await tester.drag(vertical, const Offset(0, 20000));
    await tester.pump(const Duration(milliseconds: 600));
    final lengthBefore = newsLength();
    await tester.tap(find.byType(ClubNewsTile).first);
    await toRelatedClubs();
    expect(find.text('Clubs liés'), findsOneWidget);
    expect(find.text('FC Saint Eloi Lupopo'), findsWidgets);
    await shot('article-clubs-lies');
    await tester.tap(find.text('Voir le club').first);
    await wait(find.byType(ClubDetailScreen).last);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(ClubDetailScreen, skipOffstage: false), findsNWidgets(2), reason: 'the club opens above the article');
    await shot('club-depuis-article');
    await back();
    expect(find.byType(ArticleDetailScreen), findsOneWidget, reason: 'back returns to the article');
    await back();
    expect(find.byType(ClubNewsTile), findsWidgets, reason: 'back returns to the club news list');
    expect(newsLength(), lengthBefore, reason: 'both loaded pages are kept after back');
    await back();

    // One linked club: exactly one card, and it opens that club.
    pushLinks.add('footrdc://article/$single');
    await toRelatedClubs();
    expect(find.text('Voir le club'), findsOneWidget);
    await shot('article-un-club');
    await tester.tap(find.text('Voir le club'));
    await wait(find.text('AS Vita Club'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(ClubDetailScreen), findsOneWidget);
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('AS Vita Club')), findsOneWidget);
    await shot('club-as-vita-club');
    await back();
    await back();

    // An article linked to several clubs, one without a crest.
    pushLinks.add('footrdc://article/$multi');
    await toRelatedClubs();
    expect(find.text('Voir le club'), findsNWidgets(4));
    await shot('article-plusieurs-clubs');
    // The renamed club without a crest opens under its current name.
    await tester.tap(find.text('AF Ufalya Simba'));
    await wait(find.descendant(of: find.byType(AppBar), matching: find.text('AF Ufalya Simba')));
    await tester.pump(const Duration(seconds: 2));
    await shot('club-af-ufalya-simba');
    await back();
    await back();

    // An article without linked clubs shows no section.
    pushLinks.add('footrdc://article/$none');
    await wait(find.byType(ArticleDetailScreen));
    await tester.pump(const Duration(seconds: 3));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -20000));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(RelatedClubsSection), findsOneWidget);
    expect(find.text('Clubs liés'), findsNothing);
    await shot('article-sans-club');
    await back();
  });
}
