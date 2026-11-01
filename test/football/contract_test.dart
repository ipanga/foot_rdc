import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/football/data/football_client.dart';
import 'package:foot_rdc/features/football/data/football_mappers.dart';
import 'package:foot_rdc/features/football/data/football_repository.dart';
import 'package:foot_rdc/features/football/domain/countries.dart';
import 'package:foot_rdc/features/football/domain/models.dart';
import 'package:foot_rdc/features/football/presentation/football_labels.dart';

import 'support.dart';

void main() {
  group('Production contract', () {
    test('seasons come from the API, current first, never a constant', () async {
      final (repo, _, _) = contractRepository();
      final seasons = await repo.seasons();
      expect(seasons.map((s) => s.name), ['2026-2027', '2025-2026']);
      expect(seasons.where((s) => s.isCurrent).single.id, 324);
      expect(seasons.first.label, '2026–2027');
    });

    test('provisional standings are shown: publishable:false never empties a table', () async {
      final (repo, _, _) = contractRepository();
      final tables = await repo.standings(324);
      expect(tables.map((t) => t.group?.name), ['Group A', 'Group B']);
      for (final table in tables) {
        expect(table.rows, hasLength(13));
        expect(table.rows.map((r) => r.position), List.generate(13, (i) => i + 1));
        expect(table.rows.every((r) => r.teamName.isNotEmpty), isTrue, reason: 'names join from teams');
        expect(table.verified, isFalse);
      }
    });

    test('server positions are kept as sent, nothing recalculated', () async {
      final (repo, _, _) = contractRepository();
      final group = (await repo.standings(324)).first;
      final data = productionContract()['standings_current'] as List;
      final raw = data.firstWhere((r) => r['team_id'] == group.rows.first.teamId);
      expect(group.rows.first.points, raw['points']);
      expect(group.rows.first.goalDifference, raw['goal_difference']);
    });

    test('historical season keeps its own stages, clubs and tables', () async {
      final (repo, adapter, _) = contractRepository();
      final current = await repo.standings(324);
      final past = await repo.standings(325);
      expect(past.length, greaterThan(current.length));
      expect(past.any((t) => t.stage!.isPlayoff), isTrue);
      expect(past.expand((t) => t.rows).map((r) => r.stageId).toSet().contains(464), isFalse);
      expect(
        adapter.calls.where((u) => u.path.endsWith('/standings')).map((u) => u.queryParameters['season_id']),
        containsAll(['324', '325']),
      );
      expect((await repo.clubs(325)).length, greaterThan((await repo.clubs(324)).length));
    });

    test('matches map to domain with UTC kickoff, null scores and status', () async {
      final (repo, _, _) = contractRepository();
      final upcoming = (await repo.window('upcoming', 324)).rows.first;
      expect(upcoming.status, MatchStatus.scheduled);
      expect(upcoming.home.score, isNull);
      expect(upcoming.kickoff!.isUtc, isTrue);
      final finished = await repo.match(6476);
      expect(finished.status.isOver, isTrue);
      expect(finished.home.score, 0, reason: '0 is a score, not a missing value');
      expect(finished.groupName, 'Group A');
    });

    test('a club without a crest stays null: no Sportmonks fallback', () async {
      final (repo, _, _) = contractRepository();
      final clubs = await repo.clubs(324);
      expect(clubs.where((c) => c.logoUrl == null).length, 4);
      expect(clubs.any((c) => (c.logoUrl ?? '').contains('sportmonks')), isFalse);
    });

    test('partial events stay readable', () async {
      final (repo, _, _) = contractRepository();
      final events = await repo.events(6476);
      expect(events, isNotEmpty);
      expect(events.first.type, EventType.substitution);
      expect(events.first.playerName, isNull);
      expect(events.first.clock, "61'");
    });

    test('squad and player detail', () async {
      final (repo, _, _) = contractRepository();
      final squad = await repo.squad(4, 324);
      expect(squad.length, 20);
      expect(squad.any((m) => m.number == null), isTrue);
      final player = await repo.player(squad.first.playerId);
      expect(player.memberships, isNotEmpty);
      expect(await repo.squad(4, 325), isEmpty);
    });

    test('club profile may be null', () async {
      final (repo, _, _) = contractRepository();
      expect(await repo.clubProfile(4), isNull);
    });
  });

  group('Robustness', () {
    test('a malformed row is skipped, the rest stay', () {
      final rows = mapRows([
        {'id': 1, 'name': 'Ok'},
        {'name': 'no id'},
        'junk',
        {'id': 'x'},
      ], clubFrom);
      expect(rows.single.name, 'Ok');
    });

    test('unknown status and event types do not crash', () {
      expect(MatchStatus.parse('nouveau'), MatchStatus.unknown);
      expect(EventType.parse('nouveau'), EventType.other);
    });

    test('malformed optional fields stay safe', () {
      final m = matchFrom({
        'id': 1,
        'home_team_id': 2,
        'away_team_id': 3,
        'status': 'live',
        'home_score': 'x',
        'kickoff_at': 'bad',
        'quality': 'bad',
      });
      expect(m.home.score, isNull);
      expect(m.kickoff, isNull);
      expect(m.quality.verified, isFalse);
      expect(m.status.isLive, isTrue);
    });

    test('a non-list response is a malformed failure, not a crash', () async {
      final (repo, _, _) = contractRepository(
        data: {
          ...productionContract(),
          'upcoming': {'oops': true},
        },
      );
      expect(
        () => repo.window('upcoming', 324),
        throwsA(isA<FootballFailure>().having((f) => f.kind, 'kind', FootballError.malformed)),
      );
    });

    test('HTTP and offline map to plain failure kinds', () async {
      final (repo, adapter, _) = contractRepository();
      adapter.failWith = 404;
      await expectLater(
        repo.club(99),
        throwsA(isA<FootballFailure>().having((f) => f.kind, 'kind', FootballError.notFound)),
      );
      adapter.failWith = null;
      adapter.offline = true;
      await expectLater(
        repo.club(4),
        throwsA(isA<FootballFailure>().having((f) => f.kind, 'kind', FootballError.offline)),
      );
    });
  });

  group('Cache', () {
    test('a fresh copy serves without a request; an old one refetches', () async {
      var now = DateTime.utc(2026, 11, 1, 12);
      final (repo, adapter, _) = contractRepository(clock: () => now);
      await repo.seasons();
      await repo.seasons();
      expect(adapter.calls, hasLength(1));
      now = now.add(const Duration(hours: 2));
      await repo.seasons();
      expect(adapter.calls, hasLength(2));
    });

    test('live is never cached', () async {
      final (repo, adapter, _) = contractRepository();
      await repo.window('live', 324);
      await repo.window('live', 324);
      expect(adapter.calls, hasLength(2));
    });

    test('stale-while-revalidate shows saved data, then fresh', () async {
      var now = DateTime.utc(2026, 11, 1, 12);
      final (repo, _, _) = contractRepository(clock: () => now);
      await repo.clubs(324);
      now = now.add(const Duration(hours: 3));
      final states = await staleWhileRevalidate((p) => repo.clubs(324, policy: p)).toList();
      expect(states, hasLength(2));
      expect(states.every((s) => !s.stale), isTrue);
    });

    test('offline keeps the saved copy and marks it stale', () async {
      var now = DateTime.utc(2026, 11, 1, 12);
      final (repo, adapter, _) = contractRepository(clock: () => now);
      await repo.clubs(324);
      now = now.add(const Duration(hours: 3));
      adapter.offline = true;
      final states = await staleWhileRevalidate((p) => repo.clubs(324, policy: p)).toList();
      expect(states.last.stale, isTrue);
      expect(states.last.value, hasLength(26));
    });

    test('offline with nothing saved surfaces the failure', () async {
      final (repo, adapter, _) = contractRepository();
      adapter.offline = true;
      expect(staleWhileRevalidate((p) => repo.clubs(324, policy: p)).toList(), throwsA(isA<FootballFailure>()));
    });

    test('a copy older than a day is not shown offline', () async {
      var now = DateTime.utc(2026, 11, 1, 12);
      final (repo, adapter, _) = contractRepository(clock: () => now);
      await repo.clubs(324);
      now = now.add(const Duration(hours: 25));
      adapter.offline = true;
      await expectLater(repo.clubs(324, policy: CachePolicy.cacheOnly), throwsA(isA<FootballFailure>()));
    });
  });

  group('French labels', () {
    test('phases, statuses, positions and countries', () {
      expect(phaseLabel('Group A'), 'Groupe A');
      expect(phaseLabel('Regular Season'), 'Saison régulière');
      expect(phaseLabel('Championship Round'), 'Play-offs');
      expect(statusLabel(MatchStatus.postponed), 'Reporté');
      expect(positionLabel('Attacker'), 'Attaquant');
      expect(countryName('CD'), 'RD Congo');
      expect(countryName('CG'), 'Congo');
      expect(countryName('xx'), 'xx');
    });

    test('age is omitted when implausible', () {
      expect(ageAt(DateTime(2000, 6, 15), DateTime(2026, 6, 14)), 25);
      expect(ageAt(DateTime(2020), DateTime(2026)), isNull);
      expect(ageAt(null, DateTime(2026)), isNull);
    });
  });
}
