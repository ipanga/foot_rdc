import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/navigation/deep_link_handler.dart';
import 'package:foot_rdc/features/football/data/football_repository.dart';
import 'package:foot_rdc/features/football/presentation/screens/club_detail_screen.dart';
import 'package:foot_rdc/features/football/presentation/widgets/football_widgets.dart';
import 'package:foot_rdc/features/football/presentation/widgets/related_clubs.dart';
import 'package:foot_rdc/features/news/data/models/article_model.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

/// The shape RDC Football returns on Staging for /teams/{id}/news (synthetic values).
Map<String, dynamic> newsRow(int id, {List<Map<String, dynamic>>? clubs}) => {
  'id': id,
  'title': 'Lupopo contraint au partage des points $id',
  'url': 'https://example.org/article-$id/',
  'published_at': '2026-10-20T16:42:41Z',
  'excerpt': 'Pour leur première sortie officielle…',
  'image': null,
  'category': 'RDC',
  'related_clubs': clubs ?? [lupopo],
};

const lupopo = {'id': 4, 'name': 'FC Saint Eloi Lupopo', 'slug': 'fc-saint-eloi-lupopo', 'crest': null, 'url': null};

Map<String, dynamic> wpPost({Object? relatedClubs}) => {
  'id': 72740,
  'date_gmt': '2026-10-21T10:00:00',
  'modified_gmt': '2026-10-21T10:00:00',
  'slug': 'fc-les-aigles-du-congo',
  'status': 'publish',
  'type': 'post',
  'link': 'https://footrdc.com/rd-congo/fc-les-aigles-du-congo/',
  'title': {'rendered': 'FC Les Aigles du Congo'},
  'content': {'rendered': '<p>x</p>'},
  'excerpt': {'rendered': '<p>x</p>'},
  'related_clubs': ?relatedClubs,
};

Future<void> openNews(WidgetTester tester, FootballRepository repo) async {
  await tester.pumpWidget(app(const ClubDetailScreen(clubId: 4), repo));
  await settle(tester);
  await tester.tap(find.widgetWithText(Tab, 'Actualités'));
  await settle(tester);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    ClubCrest.loadImages = false;
    await initializeDateFormatting('fr');
  });

  group('Related clubs parsing', () {
    test('an article carries its linked clubs in order, with canonical ids', () {
      final article = Article.fromJson(
        wpPost(
          relatedClubs: [
            {
              'id': 5,
              'name': 'Maniema Union',
              'slug': 'maniema-union',
              'crest': 'https://footrdc.com/c/5.png',
              'url': 'x',
            },
            {'id': 2229, 'name': 'AF Ufalya Simba', 'slug': 'af-ufalya-simba', 'crest': null, 'url': null},
          ],
        ),
      );
      expect(article.relatedClubs.map((c) => c.id), [5, 2229]);
      expect(article.relatedClubs.first.crestUrl, 'https://footrdc.com/c/5.png');
      expect(article.relatedClubs.last.crestUrl, isNull, reason: 'a missing crest stays null and shows initials');
    });

    test('older responses and malformed entries are tolerated', () {
      expect(Article.fromJson(wpPost()).relatedClubs, isEmpty);
      expect(Article.fromJson(wpPost(relatedClubs: 'oops')).relatedClubs, isEmpty);
      final article = Article.fromJson(
        wpPost(
          relatedClubs: [
            {'id': '5', 'name': 'Texte'},
            {'id': 0, 'name': 'Zéro'},
            {'id': 7, 'name': ''},
            {'id': 8, 'name': 'Valide', 'crest': 'javascript:alert(1)'},
          ],
        ),
      );
      expect(article.relatedClubs.map((c) => c.id), [8]);
      expect(article.relatedClubs.single.crestUrl, isNull, reason: 'only http(s) crests are used');
    });

    test('saved articles keep their clubs, and articles saved before keep working', () {
      final article = Article.fromJson(wpPost(relatedClubs: [lupopo]));
      final restored = ArticleModel.fromEntity(article).toEntity();
      expect(restored.relatedClubs.single.name, 'FC Saint Eloi Lupopo');
      final legacy = ArticleModel(
        id: 1,
        dateGmt: DateTime(2026),
        guid: '',
        modifiedGmt: DateTime(2026),
        slug: '',
        status: 'publish',
        type: 'post',
        category: '',
        link: '',
        title: 'Ancien',
        content: '',
        excerpt: '',
        imageUrl: '',
      );
      expect(legacy.toEntity().relatedClubs, isEmpty);
      expect(
        ArticleModel(
          id: 2,
          dateGmt: DateTime(2026),
          guid: '',
          modifiedGmt: DateTime(2026),
          slug: '',
          status: '',
          type: '',
          category: '',
          link: '',
          title: '',
          content: '',
          excerpt: '',
          imageUrl: '',
          relatedClubsJson: '{broken',
        ).toEntity().relatedClubs,
        isEmpty,
      );
    });
  });

  group('Club news', () {
    test('rows carry category and excerpt, and pages are requested', () async {
      final (repo, adapter, _) = contractRepository(
        data: {
          ...productionContract(),
          'team_news': [newsRow(1), newsRow(2)],
        },
      );
      final rows = await repo.clubNews(4, page: 2);
      expect(rows.first.category, 'RDC');
      expect(rows.first.excerpt, startsWith('Pour leur'));
      final call = adapter.calls.last;
      expect(call.queryParameters['page'], '2');
      expect(call.queryParameters['limit'], '${FootballRepository.clubNewsPageSize}');
    });

    testWidgets('the tab lists linked articles and opens one by id inside the app', (tester) async {
      final (repo, _, _) = contractRepository(
        data: {
          ...productionContract(),
          'team_news': [newsRow(11), newsRow(12)],
        },
      );
      final opened = <String>[];
      final sub = pushLinks.stream.listen(opened.add);
      addTearDown(sub.cancel);
      await openNews(tester, repo);
      expect(find.text('Lupopo contraint au partage des points 11'), findsOneWidget);
      expect(find.text('RDC'), findsWidgets);
      expect(find.text('Charger plus'), findsNothing, reason: 'fewer rows than a page: no more to load');
      await tester.tap(find.text('Lupopo contraint au partage des points 12'));
      await tester.pump();
      expect(opened, ['footrdc://article/12']);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });

    testWidgets('a full page offers more, and an empty club explains why', (tester) async {
      final full = [for (var i = 0; i < FootballRepository.clubNewsPageSize; i++) newsRow(100 + i)];
      final (repo, _, _) = contractRepository(data: {...productionContract(), 'team_news': full});
      await openNews(tester, repo);
      await tester.scrollUntilVisible(
        find.text('Charger plus'),
        300,
        scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).last,
      );
      expect(find.text('Charger plus'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
      final (empty, _, _) = contractRepository(data: {...productionContract(), 'team_news': <Object>[]});
      await openNews(tester, empty);
      expect(find.text('Aucune actualité liée à ce club'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });
  });

  testWidgets('club news offline with nothing saved shows a clear message, not a raw error', (tester) async {
    final (repo, adapter, _) = contractRepository(
      data: {
        ...productionContract(),
        'team_news': [newsRow(1)],
      },
    );
    adapter.offline = true;
    await openNews(tester, repo);
    expect(find.textContaining('Pas de connexion'), findsWidgets);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('Dio'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  group('Related clubs on an article', () {
    testWidgets('each club opens the native club screen; no section without clubs', (tester) async {
      final (repo, _, _) = contractRepository();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: ListView(
              children: const [
                RelatedClubsSection(
                  clubs: [
                    RelatedClub(id: 4, name: 'FC Saint Eloi Lupopo'),
                    RelatedClub(id: 2212, name: 'AS Saint-Luc de Kananga, un nom de club très long pour tester'),
                  ],
                ),
              ],
            ),
          ),
          repo,
          size: const Size(320, 700),
        ),
      );
      await settle(tester);
      expect(find.text('Clubs liés'), findsOneWidget);
      expect(find.text('Voir le club'), findsNWidgets(2));
      expect(tester.takeException(), isNull, reason: 'long names fit a 320 px screen');
      await tester.tap(find.text('FC Saint Eloi Lupopo'));
      await settle(tester);
      expect(find.byType(ClubDetailScreen), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await settle(tester);
      expect(find.text('Clubs liés'), findsOneWidget, reason: 'back returns to the article');
      await tester.pumpWidget(app(const Scaffold(body: RelatedClubsSection(clubs: [])), repo));
      await settle(tester);
      expect(find.text('Clubs liés'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });
  });
}
