import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:foot_rdc/features/football/domain/models.dart';
import 'package:foot_rdc/features/football/presentation/providers.dart';
import 'package:foot_rdc/features/football/presentation/screens/matches_screen.dart';
import 'package:foot_rdc/features/football/presentation/widgets/football_widgets.dart';
import 'package:foot_rdc/features/football/presentation/widgets/home_football.dart';
import 'package:foot_rdc/features/home/presentation/app_tabs.dart';

import 'support.dart';

Match m(int id, MatchStatus status, DateTime kickoff, {int? hs, int? as_, String group = 'Group B'}) => Match(
  id: id,
  seasonId: 324,
  stageId: 1,
  home: MatchSide(teamId: id * 10, name: 'Domicile $id', score: hs),
  away: MatchSide(teamId: id * 10 + 1, name: 'Extérieur $id', score: as_),
  kickoff: kickoff.toUtc(),
  status: status,
  groupName: group,
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
    ClubCrest.loadImages = false;
  });
  final day = DateTime.utc(2026, 11, 8, 14);

  group('Accueil results and fixtures', () {
    test('results: only finished or awarded with a score, newest first, five at most', () {
      final rows = [
        m(1, MatchStatus.finished, day.subtract(const Duration(days: 3)), hs: 1, as_: 0),
        m(2, MatchStatus.cancelled, day),
        m(3, MatchStatus.postponed, day),
        m(4, MatchStatus.abandoned, day, hs: 0, as_: 0),
        m(5, MatchStatus.awarded, day.subtract(const Duration(days: 1)), hs: 3, as_: 0),
        m(6, MatchStatus.finished, day, hs: 2, as_: 2),
        for (var i = 7; i < 12; i++) m(i, MatchStatus.finished, day.subtract(Duration(days: 4 + i)), hs: 0, as_: 1),
        m(12, MatchStatus.finished, day, hs: null, as_: null),
      ];
      final results = homeResults(rows);
      expect(results.map((r) => r.id), [6, 5, 1, 7, 8]);
      expect(results.every((r) => r.status.isOver), isTrue);
    });

    test('fixtures: live first, then scheduled from the nearest; never postponed or invented scores', () {
      final upcoming = [
        m(21, MatchStatus.scheduled, day.add(const Duration(days: 2))),
        m(22, MatchStatus.postponed, day.add(const Duration(days: 1))),
        m(23, MatchStatus.scheduled, day.add(const Duration(hours: 3))),
        m(24, MatchStatus.scheduled, day.add(const Duration(days: 5))),
      ];
      final live = [m(30, MatchStatus.live, day, hs: 1, as_: 0), m(23, MatchStatus.live, day, hs: 0, as_: 0)];
      expect(homeFixtures(live, upcoming).map((r) => r.id), [30, 23, 21, 24]);
      expect(homeFixtures(const [], upcoming).map((r) => r.id), [23, 21, 24]);
    });

    testWidgets('cards: scores for results, kickoff time and no score for fixtures, group shown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HomeMatchCard(match: m(1, MatchStatus.finished, day, hs: 2, as_: 1)),
                HomeMatchCard(match: m(2, MatchStatus.scheduled, DateTime.now().add(const Duration(days: 30)))),
                HomeMatchCard(match: m(3, MatchStatus.live, day, hs: 1, as_: 1)),
              ],
            ),
          ),
        ),
      );
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Groupe B'), findsNWidgets(3));
      expect(find.textContaining(':'), findsWidgets, reason: 'kickoff time on the fixture');
      expect(find.text('En direct'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('long club names and large text stay inside the card', (tester) async {
      final long = Match(
        id: 9,
        seasonId: 324,
        stageId: 1,
        home: const MatchSide(teamId: 1, name: 'Association Sportive Saint-Luc de Kananga Football Club', score: 10),
        away: const MatchSide(teamId: 2, name: 'Etoile du Congo de Buta Football Club Officiel', score: 0),
        kickoff: day,
        status: MatchStatus.finished,
        groupName: 'Group A',
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(height: 140, child: HomeMatchCard(match: long)),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'both sections from the API; Tout voir opens Matchs › Résultats, Calendrier opens Matchs › Calendrier',
      (tester) async {
        final (repo, adapter, _) = contractRepository();
        final container = ProviderContainer(overrides: [footballRepositoryProvider.overrideWith((ref) async => repo)]);
        addTearDown(container.dispose);
        container.read(selectedSeasonIdProvider.notifier).state = 325;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: SingleChildScrollView(child: HomeMatchStrip())),
            ),
          ),
        );
        await settle(tester);
        expect(find.text('Derniers résultats'), findsOneWidget);
        expect(find.text('Prochains matchs'), findsOneWidget);
        for (final strip in const ['home-results-strip', 'home-fixtures-strip']) {
          expect(
            find.descendant(of: find.byKey(ValueKey(strip)), matching: find.byType(HomeMatchCard)),
            findsAtLeastNWidgets(3),
          );
        }
        // Requests: only the current season (324), never a historical one, once each.
        final calls = adapter.calls.where((u) => u.path.contains('/matches/')).toList();
        expect(calls.every((u) => u.queryParameters['season_id'] == '324'), isTrue);
        expect(calls.where((u) => u.path.endsWith('/finished')).length, 1);
        await tester.tap(find.byKey(const ValueKey('home-results-all')));
        expect(container.read(currentTabProvider), AppTab.matches);
        expect(container.read(matchesSectionProvider), MatchesSection.results);
        expect(container.read(selectedSeasonIdProvider), isNull, reason: 'results of the current season');
        await tester.tap(find.byKey(const ValueKey('home-fixtures-all')));
        expect(container.read(matchesSectionProvider), MatchesSection.fixtures);
        await tester.pumpWidget(const SizedBox());
        await settle(tester);
      },
    );

    testWidgets('API failure or empty season: the sections stay out of the way', (tester) async {
      final (repo, adapter, _) = contractRepository();
      adapter.failWith = 500;
      final container = ProviderContainer(overrides: [footballRepositoryProvider.overrideWith((ref) async => repo)]);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: HomeMatchStrip())),
          ),
        ),
      );
      await settle(tester);
      expect(find.text('Derniers résultats'), findsNothing);
      expect(find.text('Prochains matchs'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });

    testWidgets('Matchs opens on the section asked for by Accueil', (tester) async {
      final (repo, _, _) = contractRepository();
      final container = ProviderContainer(overrides: [footballRepositoryProvider.overrideWith((ref) async => repo)]);
      addTearDown(container.dispose);
      container.read(matchesSectionProvider.notifier).state = MatchesSection.results;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MatchesScreen()),
        ),
      );
      await settle(tester);
      final controller = DefaultTabController.of(tester.element(find.byType(TabBarView)));
      expect(controller.index, MatchesSection.results);
      expect(container.read(matchesSectionProvider), isNull, reason: 'consumed once');
      container.read(matchesSectionProvider.notifier).state = MatchesSection.fixtures;
      await settle(tester);
      expect(controller.index, MatchesSection.fixtures);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });
  });
}
