import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/theme/app_theme.dart';
import 'package:foot_rdc/features/football/presentation/widgets/football_widgets.dart';
import 'package:foot_rdc/features/news/data/models/article_model.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/promotions/custom_ad_slot.dart';
import 'package:foot_rdc/features/promotions/custom_ads.dart';
import 'package:foot_rdc/shared/widgets/ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> adJson({
  int id = 7,
  String placement = 'home_feed',
  String url = 'https://www.exemple.cd/offre',
  String image = 'https://footrdc.com/wp-content/uploads/2026/11/banniere.png',
  int width = 1200,
  int height = 400,
  String? endsAt,
  String alt = 'Offre spéciale',
}) => {
  'id': id,
  'placement': placement,
  'advertiser': 'Annonceur',
  'alt': alt,
  'image': {'url': image, 'width': width, 'height': height},
  'url': url,
  'ends_at': endsAt,
};

/// Serves one fixed answer to `GET /mobile-ads`.
class FixedAdapter implements HttpClientAdapter {
  int status;
  String body;
  int calls = 0;
  bool fail = false;
  FixedAdapter(this.status, this.body);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (fail) throw DioException.connectionError(requestOptions: options, reason: 'offline');
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(CustomAdsSource, FixedAdapter) source(int status, Object body) {
  final adapter = FixedAdapter(status, body is String ? body : jsonEncode(body));
  final dio = Dio(BaseOptions(baseUrl: 'https://footrdc.com/wp-json/rdcfootball/v1', responseType: ResponseType.plain))
    ..httpClientAdapter = adapter;
  return (CustomAdsSource(dio), adapter);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  // A neutral box instead of a network image (no image cache in widget tests).
  setUp(() => customAdImageForTests = (_, _) => const ColoredBox(color: Colors.grey));
  tearDown(() => customAdImageForTests = null);

  group('What the app accepts', () {
    test('a complete ad', () {
      final ad = CustomAd.fromJson(adJson(endsAt: '2026-11-08T00:00:00Z'))!;
      expect(ad.placement, AdPlacement.homeFeed);
      expect(ad.link.toString(), 'https://www.exemple.cd/offre');
      expect(ad.aspectRatio, 3.0);
      expect(ad.endsAt, DateTime.utc(2026, 11, 8));
      expect(ad.liveAt(DateTime.utc(2026, 11, 7, 23)), isTrue);
      expect(ad.liveAt(DateTime.utc(2026, 11, 8)), isFalse);
    });

    test('anything unsafe or incomplete is skipped', () {
      for (final bad in [
        adJson(url: 'http://exemple.cd'),
        adJson(url: 'javascript:alert(1)'),
        adJson(url: 'https://user:pw@exemple.cd'),
        adJson(url: 'intent://scan#Intent;end'),
        adJson(image: 'http://footrdc.com/a.png'),
        adJson(image: 'data:image/png;base64,AAAA'),
        adJson(placement: 'popup'),
        adJson(width: 40),
        {'id': 1},
        'not a map',
      ]) {
        expect(CustomAd.fromJson(bad), isNull, reason: '$bad');
      }
    });

    test('extreme proportions are contained; default description', () {
      expect(CustomAd.fromJson(adJson(width: 3000, height: 100))!.aspectRatio, 4.0);
      expect(CustomAd.fromJson(adJson(width: 400, height: 1200))!.aspectRatio, 1.0);
      expect(CustomAd.fromJson(adJson(alt: ''))!.alt, 'Publicité : Annonceur');
    });
  });

  group('The endpoint', () {
    test('ads per placement, server lifetime kept within 2–30 min', () async {
      final (s, _) = source(200, {
        'version': 1,
        'ttl': 600,
        'ads': [adJson(), adJson(id: 8, placement: 'article_inline'), adJson(id: 9)],
      });
      final (ads, ttl) = await s.fetch();
      expect(ads.keys.toSet(), {AdPlacement.homeFeed, AdPlacement.articleInline});
      expect(ads[AdPlacement.homeFeed]!.id, 7, reason: 'the first one per placement');
      expect(ttl, const Duration(minutes: 10));
      final (s2, _) = source(200, {'version': 1, 'ttl': 5, 'ads': []});
      expect((await s2.fetch()).$2, CustomAdsSource.minTtl);
    });

    test('a server without the plugin (404) means no ads; a broken answer is an error', () async {
      final (s404, _) = source(404, {'code': 'rest_no_route'});
      expect((await s404.fetch()).$1, isEmpty);
      for (final body in ['<html>', '{"version":2,"ads":[]}', '{"version":1,"ads":"x"}']) {
        final (s, _) = source(200, body);
        await expectLater(s.fetch(), throwsA(anything), reason: body);
      }
      final (s500, _) = source(500, 'error');
      await expectLater(s500.fetch(), throwsA(isA<DioException>()));
    });
  });

  group('Cache and refresh', () {
    test('fetched once per lifetime, kept for the next start, refreshed when stale', () async {
      var now = DateTime.utc(2026, 11, 6, 12);
      final (s, adapter) = source(200, {
        'version': 1,
        'ttl': 600,
        'ads': [adJson()],
      });
      final n = CustomAdsNotifier(s, now: () => now);
      await n.refreshIfStale();
      await n.refreshIfStale();
      expect(adapter.calls, 1);
      expect(n.state.at(AdPlacement.homeFeed, now)!.id, 7);
      now = now.add(const Duration(minutes: 9));
      await n.refreshIfStale();
      expect(adapter.calls, 1, reason: 'still fresh');
      now = now.add(const Duration(minutes: 2));
      adapter.body = jsonEncode({'version': 1, 'ttl': 600, 'ads': []});
      await n.refreshIfStale();
      expect(adapter.calls, 2);
      expect(n.state.at(AdPlacement.homeFeed, now), isNull, reason: 'paused in WordPress: gone after the refresh');

      final restarted = CustomAdsNotifier(s, now: () => now);
      await restarted.restored;
      expect(restarted.state.loaded, isTrue, reason: 'the last answer is kept on the device');
    });

    test('offline: the last answer stays a while, then the ad goes; retries wait a minute', () async {
      var now = DateTime.utc(2026, 11, 6, 12);
      final (s, adapter) = source(200, {
        'version': 1,
        'ttl': 600,
        'ads': [adJson()],
      });
      final n = CustomAdsNotifier(s, now: () => now);
      await n.refreshIfStale();
      adapter.fail = true;
      now = now.add(const Duration(minutes: 11));
      await n.refreshIfStale();
      expect(adapter.calls, 2);
      expect(n.state.at(AdPlacement.homeFeed, now), isNotNull, reason: 'kept up to twice its lifetime');
      now = now.add(const Duration(seconds: 30));
      await n.refreshIfStale();
      expect(adapter.calls, 2, reason: 'no retry within a minute');
      now = now.add(const Duration(minutes: 10));
      expect(n.state.at(AdPlacement.homeFeed, now), isNull, reason: 'too old: a paused campaign must not linger');
    });

    test('an ad that ends while cached disappears at its end', () async {
      final now = DateTime.utc(2026, 11, 6, 12);
      final (s, _) = source(200, {
        'version': 1,
        'ttl': 600,
        'ads': [adJson(endsAt: '2026-11-06T12:05:00Z')],
      });
      final n = CustomAdsNotifier(s, now: () => now);
      await n.refreshIfStale();
      expect(n.state.at(AdPlacement.homeFeed, now), isNotNull);
      expect(n.state.at(AdPlacement.homeFeed, now.add(const Duration(minutes: 6))), isNull);
    });
  });

  group('Article introduction', () {
    String p(int i) => '<p>Paragraphe $i.</p>';
    test('after the second paragraph when enough follows', () {
      final html = List.generate(6, p).join();
      final (intro, rest) = splitAfterIntroduction(html)!;
      expect(intro, p(0) + p(1));
      expect(rest, List.generate(4, (i) => p(i + 2)).join());
    });

    test('a short article gets no ad in its text', () {
      expect(splitAfterIntroduction(List.generate(4, p).join()), isNull);
      expect(splitAfterIntroduction('<p>Seul.</p>'), isNull);
    });

    test('empty paragraphs and images do not count as introduction', () {
      final html = '<p> </p><figure><img src="x"></figure>${List.generate(6, p).join()}';
      final (intro, _) = splitAfterIntroduction(html)!;
      expect(intro.endsWith(p(1)), isTrue);
      expect(intro.contains('<figure>'), isTrue);
    });
  });

  group('The slot', () {
    CustomAdsNotifier loaded(Map<AdPlacement, CustomAd> ads) {
      final (s, _) = source(200, {'version': 1, 'ttl': 600, 'ads': []});
      return CustomAdsNotifier(s)..state = CustomAdsState(ads: ads, fetchedAt: DateTime.now());
    }

    Widget host(CustomAdsNotifier notifier, Widget child, {ThemeData? theme, double scale = 1}) => ProviderScope(
      overrides: [customAdsProvider.overrideWith((ref) => notifier)],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: c!,
        ),
        home: Scaffold(body: ListView(children: [const Text('Avant'), child, const Text('Après')])),
      ),
    );

    testWidgets('no eligible ad: nothing at all', (tester) async {
      await tester.pumpWidget(host(loaded({}), const CustomAdSlot(placement: AdPlacement.homeFeed)));
      expect(find.text('PUBLICITÉ'), findsNothing);
      expect(tester.getSize(find.byType(CustomAdSlot)).height, 0);
    });

    testWidgets('label, proportion, accessible link; a tap opens the HTTPS page', (tester) async {
      final opened = <Uri>[];
      final ad = CustomAd.fromJson(adJson())!;
      await tester.pumpWidget(
        host(
          loaded({AdPlacement.homeFeed: ad}),
          CustomAdSlot(
            placement: AdPlacement.homeFeed,
            openLink: (u) async {
              opened.add(u);
              return true;
            },
          ),
        ),
      );
      expect(find.text('PUBLICITÉ'), findsOneWidget);
      expect(find.text('Annonceur'), findsOneWidget);
      final box = tester.getSize(find.byType(AspectRatio));
      expect(box.width / box.height, closeTo(3, 0.01));
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Offre spéciale'))),
        isSemantics(
          // Read as « Publicité », then what the banner shows and what a tap does.
          label: 'Publicité\nOffre spéciale. Ouvre le site de l’annonceur dans le navigateur.',
          isButton: true,
          isLink: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
      expect(opened, isEmpty, reason: 'nothing opens without a tap');
      await tester.tap(find.byType(InkWell));
      expect(opened, [Uri.parse('https://www.exemple.cd/offre')]);
    });

    testWidgets('an image that fails to load removes the slot', (tester) async {
      final ad = CustomAd.fromJson(adJson())!;
      customAdImageForTests = (_, onError) => onError();
      addTearDown(() => customAdImageForTests = null);
      await tester.pumpWidget(
        host(loaded({AdPlacement.homeFeed: ad}), const CustomAdSlot(placement: AdPlacement.homeFeed)),
      );
      await tester.pump();
      expect(find.text('PUBLICITÉ'), findsNothing);
      expect(find.text('Avant'), findsOneWidget, reason: 'the reading goes on');
    });

    testWidgets('an answer that arrives after the slot was built does not push the text', (tester) async {
      final notifier = loaded({});
      await tester.pumpWidget(host(notifier, const CustomAdSlot(placement: AdPlacement.homeFeed)));
      notifier.state = CustomAdsState(
        ads: {AdPlacement.homeFeed: CustomAd.fromJson(adJson())!},
        fetchedAt: DateTime.now(),
      );
      await tester.pump();
      expect(find.text('PUBLICITÉ'), findsNothing);
    });

    for (final (dark, scale, width) in [(false, 1.0, 320.0), (true, 2.0, 320.0), (false, 1.3, 768.0)]) {
      testWidgets('fits at $width px, text ×$scale, dark $dark; label contrast', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final ad = CustomAd.fromJson(adJson())!;
        await tester.pumpWidget(
          host(
            loaded({AdPlacement.homeFeed: ad}),
            const CustomAdSlot(placement: AdPlacement.homeFeed),
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            scale: scale,
          ),
        );
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      });
    }
  });

  group('Article page', () {
    setUpAll(() async {
      Hive.init(Directory.systemTemp.createTempSync('rdcf-hive-ads').path);
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ArticleModelAdapter());
      await Hive.openBox<ArticleModel>('articles');
      disableInlineBannerAdsForTests();
      ClubCrest.loadImages = false;
    });

    Article article(int paragraphs) => Article(
      id: 3,
      dateGmt: DateTime.utc(2026, 11, 6),
      guid: '',
      modifiedGmt: DateTime.utc(2026, 11, 6),
      slug: 'a',
      status: 'publish',
      type: 'post',
      category: 'rdc',
      link: 'https://footrdc.com/a/',
      title: 'Titre',
      content: List.generate(paragraphs, (i) => '<p>Paragraphe $i du texte.</p>').join(),
      excerpt: '',
      imageUrl: '',
    );

    Future<void> pump(WidgetTester tester, Article a, Map<AdPlacement, CustomAd> ads) async {
      final (s, _) = source(200, {'version': 1, 'ttl': 600, 'ads': []});
      final n = CustomAdsNotifier(s)..state = CustomAdsState(ads: ads, fetchedAt: DateTime.now());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [customAdsProvider.overrideWith((ref) => n)],
          child: MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: ArticleDetailScreen(article: a),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('the ad sits after the introduction, before the rest of the text', (tester) async {
      await pump(tester, article(8), {
        AdPlacement.articleInline: CustomAd.fromJson(adJson(placement: 'article_inline'))!,
      });
      final slot = find.byKey(const ValueKey('custom-ad-article_inline'));
      await tester.scrollUntilVisible(slot, 200, scrollable: find.byType(Scrollable).first);
      final y = tester.getTopLeft(slot).dy;
      expect(tester.getTopLeft(find.textContaining('Paragraphe 1 du texte')).dy, lessThan(y));
      await tester.scrollUntilVisible(
        find.textContaining('Paragraphe 2 du texte'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.getTopLeft(find.textContaining('Paragraphe 2 du texte')).dy,
        greaterThan(tester.getTopLeft(slot).dy),
      );
    });

    testWidgets('no ad, or a short article: the text is unchanged and in one piece', (tester) async {
      await pump(tester, article(8), {});
      expect(find.byKey(const ValueKey('custom-ad-article_inline')), findsNothing);
      await pump(tester, article(3), {
        AdPlacement.articleInline: CustomAd.fromJson(adJson(placement: 'article_inline'))!,
      });
      expect(find.byKey(const ValueKey('custom-ad-article_inline'), skipOffstage: false), findsNothing);
    });
  });
}
