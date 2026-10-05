import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/network/dio_client.dart';
import 'package:foot_rdc/features/football/data/football_api.dart';
import 'package:foot_rdc/features/football/data/football_config.dart';
import 'package:foot_rdc/features/football/data/football_repository.dart';
import 'package:foot_rdc/features/football/domain/football_models.dart';
import 'football_support.dart' show MemoryCache;

FootballRepository staging() {
  final config = FootballConfig(
    origin: Uri.parse('https://staging.sportrdc.com'),
    competitionId: 1,
    seasonId: 1,
  );
  return FootballRepository(
    RdcFootballApiClient(
      config,
      DioClient(baseUrl: config.baseUrl, logResponses: false),
      MemoryCache(),
    ),
  );
}

void main() {
  test(
    'real Flutter Dio public staging non-live decoding',
    () async {
      final repo = staging();
      expect(
        (await repo.single(const FootballQuery('competitions/1')))!.name,
        'Super Ligue',
      );
      expect(
        (await repo.page(
          const FootballQuery('seasons', {'competition_id': 1, 'limit': 25}),
        )).rows.single.id,
        1,
      );
      // Baseline count only: not a substitute for the paginated directory gate.
      expect(
        (await repo.page(
          const FootballQuery('teams', {'limit': 50}),
        )).rows.length,
        31,
      );
      expect(
        (await repo.single(const FootballQuery('teams/12')))!.name,
        'TP Mazembe',
      );
      expect(
        await repo.single(
          const FootballQuery('teams/12/next-match', {'season_id': 1}),
        ),
        isNull,
      );
      expect(
        (await repo.page(
          const FootballQuery('teams/12/matches', {
            'season_id': 1,
            'limit': 25,
          }),
        )).rows,
        isNotEmpty,
      );
      expect(
        (await repo.page(
          const FootballQuery('teams/12/results', {'season_id': 1, 'limit': 5}),
        )).rows.length,
        5,
      );
      expect(
        (await repo.page(
          const FootballQuery('teams/12/squad', {'season_id': 1, 'limit': 25}),
        )).rows,
        isNotEmpty,
      );
      expect(
        (await repo.page(
          const FootballQuery('teams/12/statistics', {
            'season_id': 1,
            'limit': 25,
          }),
        )).rows.single.metrics,
        isNotEmpty,
      );
      expect(
        (await repo.page(
          const FootballQuery('teams/12/standings', {
            'season_id': 1,
            'limit': 25,
          }),
        )).rows,
        isEmpty,
      );
      final first = await repo.page(
        const FootballQuery('matches/finished', {
          'competition_id': 1,
          'season_id': 1,
          'limit': 25,
          'page': 1,
        }),
      );
      final second = await repo.page(
        const FootballQuery('matches/finished', {
          'competition_id': 1,
          'season_id': 1,
          'limit': 25,
          'page': 2,
        }),
      );
      expect(first.rows.length, 25);
      expect(second.rows.length, 25);
      expect(
        first.rows
            .map((r) => r.id)
            .toSet()
            .intersection(second.rows.map((r) => r.id).toSet()),
        isEmpty,
      );
      final detail = await repo.single(
        FootballQuery('matches/${first.rows.first.id}'),
      );
      expect(detail!.status, 'finished');
      expect(detail.kickoff!.isUtc, true);
      await repo.page(FootballQuery('matches/${detail.id}/events'));
      for (final view in ['today', 'upcoming']) {
        await repo.page(
          FootballQuery('matches/$view', {
            'competition_id': 1,
            'season_id': 1,
            'limit': 25,
          }),
        );
      }
      expect(repo.api.config.live.enabled, false);
      expect(repo.api.requestCount, 16);
    },
    skip: !const bool.fromEnvironment('RDCF_STAGING_SMOKE'),
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'deployed staging phases and fully paginated scoped directory acceptance',
    () async {
      final repo = staging();
      final context = await repo.context();
      expect(context.teams.length, 31);
      expect(context.phases.where((p) => p.name == 'Group A').length, 1);
      expect(context.phases.where((p) => p.name == 'Group B').length, 1);
      expect(context.phases.where((p) => p.type == 'playoff').length, 1);
      final page1 = await repo.page(
        const FootballQuery('teams', {'season_id': 1, 'limit': 25, 'page': 1}),
      );
      final page2 = await repo.page(
        const FootballQuery('teams', {'season_id': 1, 'limit': 25, 'page': 2}),
      );
      expect(page1.rows.length, 25);
      expect(page1.hasMore, true);
      expect(page2.rows.length, 6);
      expect(page2.hasMore, false);
    },
    skip: !const bool.fromEnvironment('RDCF_STAGING_ACCEPTANCE'),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
