import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/navigation/deep_links.dart';
import 'package:foot_rdc/features/football/domain/models.dart';
import 'package:foot_rdc/features/football/presentation/providers.dart';
import 'package:foot_rdc/features/football/presentation/screens/club_detail_screen.dart';
import 'package:foot_rdc/features/football/presentation/screens/linafoot_screen.dart';
import 'package:foot_rdc/features/football/presentation/screens/match_detail_screen.dart';
import 'package:foot_rdc/features/football/presentation/screens/matches_screen.dart';
import 'package:foot_rdc/features/football/presentation/screens/player_detail_screen.dart';
import 'package:foot_rdc/features/football/presentation/widgets/football_widgets.dart';
import 'package:foot_rdc/features/football/presentation/widgets/home_football.dart';
import 'package:foot_rdc/features/home/presentation/app_tabs.dart';
import 'package:foot_rdc/shared/widgets/premium_bottom_nav_bar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

const home = MatchSide(teamId: 1, name: 'TP Mazembe', score: 2);
const away = MatchSide(teamId: 2, name: 'AS Vita Club', score: 1);
Match sample(MatchStatus status, {int? minute}) => Match(
  id: 1,
  seasonId: 324,
  stageId: 1,
  home: home,
  away: away,
  status: status,
  minute: minute,
  kickoff: DateTime.utc(2026, 11, 4, 12),
);

void tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
    ClubCrest.loadImages = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('MatchRow', () {
    testWidgets('states are in words, not only colour', (tester) async {
      for (final (status, text) in [
        (MatchStatus.postponed, 'Reporté'),
        (MatchStatus.awarded, 'Décision administrative'),
        (MatchStatus.halftime, 'Mi-temps'),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MatchRow(match: sample(status))),
          ),
        );
        expect(find.text(text), findsOneWidget);
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MatchRow(match: sample(MatchStatus.live, minute: 63))),
        ),
      );
      expect(find.text("63'"), findsOneWidget);
    });

    testWidgets('a list without day headers carries the date', (tester) async {
      await initializeDateFormatting('fr');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MatchRow(match: sample(MatchStatus.scheduled), showDate: true)),
        ),
      );
      expect(find.textContaining('nov'), findsOneWidget);
    });

    testWidgets('a scheduled match shows no invented score', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MatchRow(match: sample(MatchStatus.scheduled))),
        ),
      );
      expect(find.text('2'), findsNothing);
    });

    testWidgets('screen readers hear the match', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MatchRow(match: sample(MatchStatus.finished))),
        ),
      );
      expect(find.bySemanticsLabel(RegExp('TP Mazembe contre AS Vita Club, 2 à 1')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('tap target is at least 48 high', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchRow(match: sample(MatchStatus.finished), onTap: () {}),
          ),
        ),
      );
      expect(tester.getSize(find.byType(InkWell)).height, greaterThanOrEqualTo(48));
    });
  });

  group('Crest', () {
    testWidgets('a club without a crest shows initials', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ClubCrest(name: 'Etoile du Congo', size: 40)),
        ),
      );
      expect(find.text('EC'), findsOneWidget);
    });
  });

  group('Standings', () {
    final rows = [
      for (var i = 1; i <= 13; i++)
        StandingRow(
          teamId: i,
          teamName: 'Club très long numéro $i de Lubumbashi',
          stageId: 1,
          position: i,
          played: 3,
          won: 1,
          drawn: 1,
          lost: 1,
          goalsFor: 2,
          goalsAgainst: 2,
          goalDifference: 0,
          points: 4,
        ),
    ];
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 1.3]) {
        for (final full in [false, true]) {
          testWidgets('fits $width at scale $scale, full $full', (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: StandingsTableView(rows: rows, full: full),
                  ),
                ),
              ),
            );
            expect(tester.takeException(), isNull);
            expect(find.text(full ? 'BC' : 'Diff.'), findsOneWidget);
          });
        }
      }
    }
  });

  group('Screens on the Production contract', () {
    testWidgets('Matchs tab shows an honest empty day and the next matches', (tester) async {
      tall(tester);
      final (repo, _, _) = contractRepository();
      await tester.pumpWidget(app(const MatchesScreen(), repo));
      await settle(tester);
      expect(find.text("Pas de match aujourd'hui"), findsOneWidget);
      expect(find.text('Prochains matchs'), findsOneWidget);
    });

    testWidgets('switching to 2025–2026 changes every request and shows the notice', (tester) async {
      final (repo, adapter, _) = contractRepository();
      await tester.pumpWidget(app(const LinafootScreen(), repo));
      await settle(tester);
      expect(find.text('2026–2027 · Saison régulière'), findsOneWidget);
      adapter.calls.clear();
      await tester.tap(find.byTooltip('Changer de saison'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('2025–2026').last);
      await settle(tester);
      expect(find.text('Saison passée · 2025–2026'), findsOneWidget);
      final seasons = adapter.calls.map((u) => u.queryParameters['season_id']).whereType<String>().toSet();
      expect(seasons, {'325'}, reason: 'no request may mix seasons');
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });

    testWidgets('standings tab shows provisional tables and the full view', (tester) async {
      tall(tester);
      final (repo, _, _) = contractRepository();
      await tester.pumpWidget(app(const LinafootScreen(initialTab: 3), repo));
      await settle(tester);
      expect(find.text('Groupe A'), findsWidgets);
      expect(find.textContaining('Classement provisoire'), findsOneWidget);
      await tester.tap(find.text('Tableau complet'));
      await tester.pump();
      expect(find.text('BP'), findsOneWidget);
    });

    testWidgets('match detail shows partial events without inventing names', (tester) async {
      final (repo, _, _) = contractRepository();
      await tester.pumpWidget(app(const MatchDetailScreen(matchId: 6476), repo));
      await settle(tester);
      expect(find.text('Malole'), findsWidgets);
      expect(find.text('Fil du match'), findsOneWidget);
      expect(find.textContaining('Stade Tshikisha'), findsOneWidget);
      expect(find.text('Kalombo Kalala'), findsOneWidget);
      expect(find.text('Remplacement'), findsWidgets);
    });

    testWidgets('club page opens with its tabs and squad groups', (tester) async {
      tall(tester);
      final (repo, _, _) = contractRepository();
      await tester.pumpWidget(app(const ClubDetailScreen(clubId: 4), repo));
      await settle(tester);
      expect(find.text('FC Saint Eloi Lupopo'), findsWidgets);
      await tester.ensureVisible(find.widgetWithText(Tab, 'Effectif'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(Tab, 'Effectif'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await settle(tester);
      expect(find.textContaining('Défenseurs'), findsOneWidget);
      expect(find.text('Effectif non disponible'), findsNothing);
    });

    testWidgets('player page shows only known fields', (tester) async {
      final (repo, _, _) = contractRepository();
      final id = (productionContract()['squad'] as List).first['player_id'] as int;
      await tester.pumpWidget(app(PlayerDetailScreen(playerId: id), repo));
      await settle(tester);
      expect(find.text('Effectifs'), findsOneWidget);
      expect(find.text('null'), findsNothing);
    });

    testWidgets('offline with nothing saved shows plain French and a retry', (tester) async {
      final (repo, adapter, _) = contractRepository();
      adapter.offline = true;
      await tester.pumpWidget(app(const MatchDetailScreen(matchId: 6476), repo));
      await settle(tester);
      expect(find.text('Pas de connexion. Vérifiez votre réseau.'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.textContaining('Dio'), findsNothing);
      expect(find.textContaining('404'), findsNothing);
    });

    testWidgets('a server error never shows HTTP details', (tester) async {
      final (repo, adapter, _) = contractRepository();
      adapter.failWith = 503;
      await tester.pumpWidget(app(const MatchDetailScreen(matchId: 6476), repo));
      await settle(tester);
      expect(find.text('Les données sont indisponibles pour le moment.'), findsOneWidget);
      expect(find.textContaining('503'), findsNothing);
    });

    testWidgets('saved data stays on screen with a notice when refresh fails', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadedView<String>(
              value: const AsyncValue.data(Loaded('saved', stale: true)),
              builder: (v) => Text(v),
            ),
          ),
        ),
      );
      expect(find.text('saved'), findsOneWidget);
      expect(find.byType(StaleNotice), findsOneWidget);
    });
  });

  group('Responsive', () {
    for (final width in [320.0, 360.0, 768.0]) {
      for (final scale in [1.0, 1.3]) {
        for (final dark in [false, true]) {
          testWidgets('main screens at $width, text $scale, dark $dark', (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final (repo, _, _) = contractRepository();
            for (final screen in const <Widget>[
              MatchesScreen(),
              LinafootScreen(),
              LinafootScreen(initialTab: 3),
              ClubDetailScreen(clubId: 4),
              MatchDetailScreen(matchId: 6476),
            ]) {
              await tester.pumpWidget(
                ProviderScope(
                  key: UniqueKey(),
                  overrides: [footballRepositoryProvider.overrideWith((ref) async => repo)],
                  child: MaterialApp(
                    theme: dark ? ThemeData.dark() : ThemeData.light(),
                    locale: const Locale('fr'),
                    supportedLocales: const [Locale('fr')],
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                      child: child!,
                    ),
                    home: screen,
                  ),
                ),
              );
              await settle(tester);
              expect(tester.takeException(), isNull);
            }
            await tester.pumpWidget(const SizedBox());
            await settle(tester);
          });
        }
      }
    }
  });

  group('Bottom tabs', () {
    test('the order is the owner\'s', () {
      expect(AppTab.values.map((t) => t.label), ['Accueil', 'Édito', 'Matchs', 'Linafoot', 'Plus']);
    });

    testWidgets('the bar shows them in that order and reports the tab by name', (tester) async {
      AppTab? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: PremiumBottomNavBar(
              currentIndex: AppTab.home.index,
              enableHaptics: false,
              onTap: (index) => tapped = AppTab.values[index],
              items: [for (final tab in AppTab.values) appTabNavItem(tab)],
            ),
          ),
        ),
      );
      final x = [for (final tab in AppTab.values) tester.getCenter(find.text(tab.label)).dx];
      expect(x, [...x]..sort());
      for (final tab in AppTab.values) {
        await tester.tap(find.text(tab.label));
        await tester.pump(const Duration(milliseconds: 600));
        expect(tapped, tab);
      }
    });

    testWidgets('each tab shows its own page, is built once and keeps its state', (tester) async {
      final built = <AppTab>[];
      Widget pages(AppTab current) => MaterialApp(
        home: TabPages(
          current: current,
          builder: (tab) {
            built.add(tab);
            return _Counter(key: ValueKey(tab), name: tab.label);
          },
        ),
      );
      await tester.pumpWidget(pages(AppTab.home));
      expect(built, [AppTab.home]);
      await tester.pumpWidget(pages(AppTab.matches));
      await tester.tap(find.text('Matchs 0'));
      await tester.pump();
      await tester.pumpWidget(pages(AppTab.edito));
      expect(find.text('Édito 0'), findsOneWidget);
      expect(find.text('Matchs 1'), findsNothing);
      await tester.pumpWidget(pages(AppTab.matches));
      expect(find.text('Matchs 1'), findsOneWidget);
      expect(built.toSet(), {AppTab.home, AppTab.matches, AppTab.edito}, reason: 'unvisited tabs stay unbuilt');
    });

    testWidgets('Tout voir opens Matchs by name', (tester) async {
      final (repo, _, _) = contractRepository();
      final container = ProviderContainer(overrides: [footballRepositoryProvider.overrideWith((ref) async => repo)]);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: HomeMatchStrip())),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('Tout voir'));
      expect(container.read(currentTabProvider), AppTab.matches);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });

    testWidgets('Classements opens the standings', (tester) async {
      final (repo, _, _) = contractRepository();
      await tester.pumpWidget(app(const Scaffold(body: SingleChildScrollView(child: HomeLinafootSnapshot())), repo));
      await settle(tester);
      await tester.tap(find.text('Classements'));
      await settle(tester);
      final tabs = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabs.controller!.index, LinafootScreen.standingsTab);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });

    test('live polling stops on tabs without live scores and resumes', () async {
      final data = productionContract();
      final (repo, adapter, _) = contractRepository(data: {...data, 'live': data['finished']});
      final container = ProviderContainer(
        overrides: [
          footballRepositoryProvider.overrideWith((ref) async => repo),
          livePollIntervalProvider.overrideWithValue(const Duration(milliseconds: 10)),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(liveMatchesProvider(324), (_, _) {});
      bool isLive(Uri uri) => uri.path.endsWith('/live');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(adapter.calls.where(isLive), isNotEmpty);
      container.read(currentTabProvider.notifier).state = AppTab.edito;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final calls = adapter.calls.where(isLive).length;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(adapter.calls.where(isLive).length, calls);
      container.read(currentTabProvider.notifier).state = AppTab.matches;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(adapter.calls.where(isLive).length, greaterThan(calls));
      sub.close();
    });

    test('returning to a tab refreshes old data and leaves fresh data alone', () async {
      final clock = _Clock();
      final (repo, adapter, _) = contractRepository(clock: clock.now);
      final container = ProviderContainer(overrides: [footballRepositoryProvider.overrideWith((ref) async => repo)]);
      addTearDown(container.dispose);
      final sub = container.listen(standingsProvider(324), (_, _) {});
      await container.read(standingsProvider(324).future);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      final first = adapter.calls.length;
      container.read(footballRefreshProvider.notifier).state++;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(adapter.calls.length, first, reason: 'fresh data makes no request');
      clock.advance(const Duration(minutes: 3));
      container.read(footballRefreshProvider.notifier).state++;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(adapter.calls.length, greaterThan(first));
      sub.close();
    });
  });

  group('Links do not depend on tabs', () {
    test('every link kind parses to its destination', () {
      expect(DeepLink.parse('footrdc://match/6476'), isA<MatchLink>());
      expect(DeepLink.parse('footrdc://club/4'), isA<ClubLink>());
      expect(DeepLink.parse('footrdc://article/12'), isA<ArticleLink>());
      expect(DeepLink.parse('footrdc://standings'), isA<LinafootLink>());
      expect(DeepLink.parse('https://footrdc.com/edito-merci-les-leopards/'), isA<ArticleSlugLink>());
    });

    test('a notification link comes from whichever field carries it', () {
      expect(notificationLink({'link': 'footrdc://club/4'}, 'https://footrdc.com/x/'), 'footrdc://club/4');
      expect(notificationLink({'url': 'footrdc://match/1'}, null), 'footrdc://match/1');
      expect(notificationLink(null, 'https://footrdc.com/x/'), 'https://footrdc.com/x/');
      expect(notificationLink({'link': 7}, null), isNull);
      expect(notificationLink(null, null), isNull);
    });
  });

  testWidgets('a message fits a very small space', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 60,
              child: MessageState(icon: Icons.search_off, title: 'Aucun club trouvé'),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('club search stays usable with the keyboard open on a small screen', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 420);
    addTearDown(tester.view.reset);
    final (repo, _, _) = contractRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [footballRepositoryProvider.overrideWith((ref) async => repo)],
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const LinafootScreen(initialTab: 4),
        ),
      ),
    );
    await settle(tester);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzz');
    await settle(tester);
    // Below the fold while the keyboard is open, but in the list.
    expect(find.text('Aucun club trouvé', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });

  group('Live polling', () {
    test('polls while live and stops when the server says it ended', () async {
      final data = productionContract();
      final live = {...(data['match'] as Map), 'status': 'live', 'current_minute': 60};
      final (repo, adapter, _) = contractRepository(data: {...data, 'match': live});
      final container = ProviderContainer(
        overrides: [
          footballRepositoryProvider.overrideWith((ref) async => repo),
          livePollIntervalProvider.overrideWithValue(const Duration(milliseconds: 10)),
        ],
      );
      addTearDown(container.dispose);
      final states = <MatchStatus>[];
      final done = Completer<void>();
      final sub = container.listen(matchDetailProvider(6476), (_, next) {
        final status = next.valueOrNull?.value.match.status;
        if (status == null) return;
        states.add(status);
        if (states.length == 3) adapter.data['match'] = {...live, 'status': 'finished'};
        if (status == MatchStatus.finished && !done.isCompleted) done.complete();
      });
      await done.future.timeout(const Duration(seconds: 5));
      final calls = adapter.calls.length;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(adapter.calls.length, calls, reason: 'no request after the match ends');
      sub.close();
    });

    test('background pauses polling', () async {
      final data = productionContract();
      final live = {...(data['match'] as Map), 'status': 'live'};
      final (repo, adapter, _) = contractRepository(data: {...data, 'match': live});
      final container = ProviderContainer(
        overrides: [
          footballRepositoryProvider.overrideWith((ref) async => repo),
          livePollIntervalProvider.overrideWithValue(const Duration(milliseconds: 10)),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(matchDetailProvider(6476), (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 60));
      container.read(appForegroundProvider.notifier).state = false;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final calls = adapter.calls.length;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(adapter.calls.length, calls);
      sub.close();
    });
  });

  group('Favorites', () {
    test('toggle persists on the device', () async {
      SharedPreferences.setMockInitialValues({});
      final favorites = FavoriteClubs();
      await Future<void>.delayed(Duration.zero);
      await favorites.toggle(4);
      expect(favorites.state, {4});
      expect((await SharedPreferences.getInstance()).getStringList('rdcf_favorite_clubs'), ['4']);
      await favorites.toggle(4);
      expect(favorites.state, isEmpty);
    });
  });

  group('Deep links', () {
    test('every link form', () {
      expect((DeepLink.parse('footrdc://match/6476') as MatchLink).id, 6476);
      expect((DeepLink.parse('footrdc://club/4') as ClubLink).id, 4);
      expect((DeepLink.parse('footrdc://article/72557') as ArticleLink).id, 72557);
      expect(DeepLink.parse('footrdc://linafoot'), isA<LinafootLink>());
      expect((DeepLink.parse('footrdc://standings') as LinafootLink).standings, isTrue);
      expect((DeepLink.parse('https://footrdc.com/linafoot/classement-groupe-a/') as LinafootLink).standings, isTrue);
      expect(
        (DeepLink.parse('https://footrdc.com/a-la-une/edito-la-confusion/') as ArticleSlugLink).slug,
        'edito-la-confusion',
      );
    });

    test('junk opens nothing', () {
      for (final raw in [
        null,
        '',
        'footrdc://match/x',
        'footrdc://match/0',
        'footrdc://nope/1',
        'https://evil.example/club/4',
        'not a link',
        'https://footrdc.com/',
      ]) {
        expect(DeepLink.parse(raw), isNull, reason: '$raw');
      }
    });
  });
}

class _Clock {
  DateTime _value = DateTime.now();
  DateTime now() => _value;
  void advance(Duration by) => _value = _value.add(by);
}

class _Counter extends StatefulWidget {
  final String name;
  const _Counter({super.key, required this.name});
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  var _count = 0;
  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: () => setState(() => _count++), child: Text('${widget.name} $_count'));
}
