import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/football/data/football_api.dart';
import 'package:foot_rdc/features/football/data/football_config.dart';
import 'package:foot_rdc/features/football/domain/football_models.dart';
import 'package:foot_rdc/features/football/presentation/football_strings.dart';
import 'football_support.dart';

void main() {
  test(
    'standings always recheck Core and cannot fall back to offline approval',
    () async {
      final h = Harness();
      const q = FootballQuery('standings');
      await h.api.get(q);
      await h.api.get(q);
      expect(h.adapter.calls.length, 2);
      h.adapter.fail = true;
      await expectLater(h.api.get(q), throwsA(isA<FootballFailure>()));
    },
  );
  test('404 stays a curated unavailable failure', () async {
    final h = Harness();
    await expectLater(
      h.api.get(const FootballQuery('teams/999')),
      throwsA(
        isA<FootballFailure>().having((e) => e.code, 'code', 'unavailable'),
      ),
    );
  });
  test('domain quality is deeply immutable and query keys cannot collide', () {
    final quality = {'publishable': false};
    final row = FootballRecord({'id': 1, 'quality': quality});
    quality['publishable'] = true;
    expect(row.standingPublishable, false);
    expect(
      () => (row.data['quality'] as Map)['publishable'] = true,
      throwsUnsupportedError,
    );
    expect(
      const FootballQuery('teams', {'a': '1&b=2'}).key,
      isNot(const FootballQuery('teams', {'a': '1', 'b': '2'}).key),
    );
  });
  test(
    'legacy ignored page cannot cause 100 repeated directory requests',
    () async {
      final h = Harness();
      h.adapter.repeatPage = true;
      await expectLater(
        h.repository.directory(),
        throwsA(isA<FootballFailure>()),
      );
      expect(h.adapter.calls.length, 2);
    },
  );
  test('expired live detail never falls back to stale offline score', () async {
    var now = DateTime.utc(2026, 10, 5);
    final h = Harness(clock: () => now)..adapter.matchStatus = 'live';
    const q = FootballQuery('matches/446');
    await h.api.get(q);
    h.adapter.fail = true;
    now = now.add(const Duration(minutes: 3));
    await expectLater(h.api.get(q), throwsA(isA<FootballFailure>()));
  });
  test(
    'actual staging Core IDs, UTC kickoff, score and next-match empty array',
    () async {
      final h = Harness();
      final team = await h.repository.single(const FootballQuery('teams/12'));
      expect(team!.id, 12);
      expect(team.name, 'TP Mazembe');
      final match = await h.repository.single(
        const FootballQuery('matches/446'),
      );
      expect(match!.kickoff!.isUtc, true);
      expect(match.status, 'finished');
      expect(match.score(liveAllowed: false), '1 - 0');
      expect(
        await h.repository.single(const FootballQuery('teams/12/next-match')),
        isNull,
      );
    },
  );
  test(
    'actual staging squad has batched statistics and real available metrics',
    () async {
      final h = Harness();
      final squad = await h.repository.page(
        const FootballQuery('teams/12/squad'),
      );
      expect(squad.rows, isNotEmpty);
      final stats = await h.repository.page(
        const FootballQuery('teams/12/statistics'),
      );
      expect(stats.rows.first.metrics['goals_for'], 82);
      expect(stats.rows.first.metrics.containsKey('played'), false);
      expect(h.adapter.calls.length, 2);
    },
  );
  test('canonical French labels and English key parity', () {
    const s = FootballStrings(Locale('fr'));
    expect(FootballStrings.fr.keys.toSet(), FootballStrings.en.keys.toSet());
    expect(s.status('finished'), 'Terminé');
    expect(s.status('halftime'), 'Mi-temps');
    expect(s.status('postponed'), 'Reporté');
    expect(s.status('cancelled'), 'Annulé');
    expect(s.status('awarded'), 'Décision administrative');
    expect(s.status('teams'), 'Statut indisponible');
    expect(s.role('Attacker'), 'Attaquants');
  });
  test(
    'null scores absent, actual zero retained, live hidden and canonical values unchanged',
    () {
      final row = FootballRecord({
        'id': 1,
        'status': 'scheduled',
        'home_score': null,
        'away_score': null,
      });
      expect(row.score(liveAllowed: false), '\u2014');
      expect(row.status, 'scheduled');
      expect(
        FootballRecord({
          'id': 2,
          'home_score': 0,
          'away_score': 0,
        }).score(liveAllowed: false),
        '0 - 0',
      );
      expect(
        FootballRecord({
          'id': 3,
          'status': 'live',
          'home_score': 2,
          'away_score': 0,
        }).score(liveAllowed: false),
        '\u2014',
      );
      expect(() => FootballRecord({'id': 0}), throwsFormatException);
      expect(
        FootballRecord({
          'id': 1,
          'metrics': {'goals': 0, 'minutes': null},
        }).metrics,
        {'goals': 0},
      );
    },
  );
  test(
    'configuration rejects providers, credentials and staging production',
    () {
      for (final url in [
        'https://api.sportmonks.com',
        'https://v3.football.api-sports.io',
        'https://name:secret@staging.sportrdc.com',
        'https://staging.sportrdc.com?token=no',
      ]) {
        expect(
          () => FootballConfig(
            origin: Uri.parse(url),
            competitionId: 1,
            seasonId: 1,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => FootballConfig(
          origin: Uri.parse('https://staging.sportrdc.com'),
          competitionId: 1,
          seasonId: 1,
          environment: 'production',
        ),
        throwsArgumentError,
      );
      expect(FootballConfig.fromEnvironment(), isNull);
    },
  );
  test('live gate fails closed for unvalidated and degraded readiness', () {
    for (final r in [
      FootballReadiness.unvalidated,
      FootballReadiness.degraded,
    ]) {
      expect(FootballLiveGate(requested: true, readiness: r).enabled, false);
    }
    expect(
      const FootballLiveGate(readiness: FootballReadiness.validated).enabled,
      false,
    );
    expect(
      const FootballLiveGate(
        requested: true,
        readiness: FootballReadiness.validated,
      ).enabled,
      true,
    );
  });
  test('live/provider requests rejected before transport', () async {
    final h = Harness();
    expect(
      () => h.api.get(const FootballQuery('matches/live')),
      throwsA(isA<FootballFailure>()),
    );
    expect(
      () => h.api.get(const FootballQuery('https://api.sportmonks.com')),
      throwsA(isA<FootballFailure>()),
    );
    expect(h.adapter.calls, isEmpty);
  });
  test(
    '31 teams across bounded distinct pages; relationships use Core identities',
    () async {
      final h = Harness();
      final context = await h.repository.context();
      expect(context.teams.length, 31);
      expect(context.phases.map((p) => p.filters).toList(), [
        {'stage_id': 1, 'group_id': 1},
        {'stage_id': 1, 'group_id': 2},
        {'stage_id': 2},
      ]);
      expect(h.adapter.calls.where((u) => u.path.endsWith('/teams')).length, 2);
      expect(
        h.adapter.calls.every((u) => u.host == 'staging.sportrdc.com'),
        true,
      );
    },
  );
  test('team directory works with unavailable phase endpoint', () async {
    final h = Harness()..adapter.failPhases = true;
    expect((await h.repository.directory()).rows.length, 31);
    await expectLater(h.repository.context(), throwsA(isA<FootballFailure>()));
  });
  test(
    'standing publication is fail closed including quality absent',
    () async {
      final h = Harness();
      h.adapter.data['standings'] = [
        {'id': 1, 'points': 33},
        {
          'id': 2,
          'quality': {'publishable': false},
        },
        {
          'id': 3,
          'quality': {'publishable': true},
          'points': 0,
        },
      ];
      final result = await h.repository.page(const FootballQuery('standings'));
      expect(result.rows.map((r) => r.id), [3]);
      expect(result.rows.first.number('points'), 0);
    },
  );
  test(
    'cache deduplicates, expires, refreshes and bounds offline fallback',
    () async {
      var now = DateTime.utc(2026, 10, 5);
      final h = Harness(clock: () => now);
      const q = FootballQuery('teams/12');
      await Future.wait([h.api.get(q), h.api.get(q)]);
      expect(h.adapter.calls.length, 1);
      expect((await h.api.get(q)).cached, true);
      now = now.add(const Duration(hours: 2));
      h.adapter.fail = true;
      expect((await h.api.get(q)).cached, true);
      expect(h.adapter.calls.length, 2);
      now = now.add(const Duration(hours: 24));
      await expectLater(h.api.get(q), throwsA(isA<FootballFailure>()));
      h.adapter.fail = false;
      expect((await h.api.get(q, refresh: true)).cached, false);
    },
  );
  test('storage failure never discards healthy HTTP response', () async {
    final h = Harness();
    h.cache.failWrite = true;
    expect(
      (await h.api.get(const FootballQuery('teams/12'))).data['name'],
      'TP Mazembe',
    );
  });
  test('malformed cache ignored and error details hidden', () async {
    final h = Harness();
    const q = FootballQuery('teams/12');
    h.cache.values['${h.config.baseUrl}/${q.key}'] = {
      'at': DateTime.now().toIso8601String(),
      'data': {},
      'headers': null,
    };
    expect((await h.api.get(q)).cached, false);
    h.cache.values.clear();
    h.adapter.fail = true;
    try {
      await h.api.get(q, refresh: true);
      fail('Expected failure');
    } catch (e) {
      expect(e.toString(), 'FootballFailure(network)');
    }
  });
  test('historical events contract and shorter match cache', () async {
    var now = DateTime.utc(2026, 10, 5);
    final h = Harness(clock: () => now);
    expect(
      (await h.repository.page(const FootballQuery('matches/446/events'))).rows,
      isA<List<FootballRecord>>(),
    );
    await h.api.get(const FootballQuery('matches/finished'));
    now = now.add(const Duration(minutes: 3));
    expect(
      (await h.api.get(const FootballQuery('matches/finished'))).cached,
      false,
    );
  });
}
