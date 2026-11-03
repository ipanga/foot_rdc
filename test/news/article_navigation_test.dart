import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/football/presentation/widgets/football_widgets.dart';
import 'package:foot_rdc/features/news/data/models/article_model.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/shared/widgets/ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Back stays reachable anywhere in a long article, and leaving returns to the list.
void main() {
  setUpAll(() async {
    Hive.init(Directory.systemTemp.createTempSync('rdcf-hive').path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ArticleModelAdapter());
    await Hive.openBox<ArticleModel>('articles');
    disableInlineBannerAdsForTests();
    ClubCrest.loadImages = false;
  });

  Article longArticle() => Article(
    id: 1,
    dateGmt: DateTime.utc(2026, 11, 2),
    guid: '',
    modifiedGmt: DateTime.utc(2026, 11, 2),
    slug: 'long',
    status: 'publish',
    type: 'post',
    category: 'Édito',
    link: 'https://footrdc.com/long/',
    title: 'Un très long éditorial',
    content: List.generate(60, (i) => '<p>Paragraphe $i : le football congolais avance pas à pas.</p>').join(),
    excerpt: '',
    imageUrl: '',
  );

  Widget app() => ProviderScope(
    child: MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => ArticleDetailScreen(article: longArticle()))),
              child: const Text('Liste'),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('back stays on screen deep in a long article and returns to the list', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Liste'));
    await tester.pumpAndSettle();
    final back = find.byTooltip('Retour');
    expect(back, findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    expect(position.pixels, greaterThan(1500), reason: 'scrolled deep into the article');
    final rect = tester.getRect(back);
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThan(200), reason: 'pinned at the top of the screen');
    expect(find.text('Un très long éditorial'), findsWidgets, reason: 'title shown in the collapsed bar');
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('Liste'), findsOneWidget);
  });

  testWidgets('the system back route also leaves the article', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('Liste'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Liste'), findsOneWidget);
  });
}
