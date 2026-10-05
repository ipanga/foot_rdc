import '../domain/football_models.dart';
import 'football_api.dart';

class FootballRepository {
  final RdcFootballApiClient api;
  FootballRepository(this.api);

  Future<FootballPage> all(FootballQuery query, {bool refresh = false}) async {
    final rows = <FootballRecord>[];
    var cached = false;
    for (var index = 1; index <= 100; index++) {
      final result = await page(
        FootballQuery(query.path, {
          ...query.filters,
          'page': index,
          'limit': 25,
        }),
        refresh: refresh,
      );
      final known = rows.map((row) => row.id).toSet();
      if (result.rows.any((row) => known.contains(row.id))) {
        throw const FootballFailure('unavailable');
      }
      rows.addAll(result.rows);
      cached = cached || result.cached;
      if (!result.hasMore) return FootballPage(rows, cached: cached);
    }
    throw const FootballFailure('unavailable');
  }

  Future<FootballPage> directory({bool refresh = false}) => all(
    FootballQuery('teams', {'season_id': api.config.seasonId}),
    refresh: refresh,
  );

  Future<FootballPage> page(FootballQuery query, {bool refresh = false}) async {
    final response = await api.get(query, refresh: refresh);
    if (response.data is! List) throw const FootballFailure('unavailable');
    var rows = (response.data as List)
        .map((row) => FootballRecord(Map<String, dynamic>.from(row as Map)))
        .toList();
    if (query.filters['view'] == 'upcoming' &&
        rows.any((row) => row.status != 'scheduled')) {
      throw const FootballFailure('unavailable');
    }
    if (query.path == 'standings' || query.path.endsWith('/standings')) {
      rows = rows.where((row) => row.standingPublishable).toList();
    }
    final page = coreInt(query.filters['page']) ?? 1;
    final limit = coreInt(query.filters['limit']) ?? 25;
    final pages = coreInt(response.headers.value('x-wp-totalpages'));
    return FootballPage(
      rows,
      hasMore: pages == null
          ? (response.data as List).length == limit
          : page < pages,
      cached: response.cached,
    );
  }

  Future<FootballRecord?> single(
    FootballQuery query, {
    bool refresh = false,
  }) async {
    final response = await api.get(query, refresh: refresh);
    if (response.data is List && (response.data as List).isEmpty) return null;
    if (response.data is! Map) throw const FootballFailure('unavailable');
    return FootballRecord(Map<String, dynamic>.from(response.data as Map));
  }

  Future<FootballContext> context({bool refresh = false}) async {
    final competition = await single(
      FootballQuery('competitions/${api.config.competitionId}'),
      refresh: refresh,
    );
    final seasons = await all(
      FootballQuery('seasons', {
        'competition_id': api.config.competitionId,
        'limit': 25,
      }),
      refresh: refresh,
    );
    final season = seasons.rows
        .where((row) => row.id == api.config.seasonId)
        .firstOrNull;
    if (competition == null || season == null) {
      throw const FootballFailure('unavailable');
    }
    final stages = await all(
      FootballQuery('stages', {'season_id': season.id, 'limit': 25}),
      refresh: refresh,
    );
    final groups = await all(
      FootballQuery('groups', {'season_id': season.id, 'limit': 25}),
      refresh: refresh,
    );
    final phases = <FootballPhase>[];
    for (final stage in stages.rows) {
      final children = groups.rows
          .where((row) => row.number('stage_id') == stage.id)
          .toList();
      if (children.isEmpty) {
        phases.add(
          FootballPhase(stage.id, null, stage.name, stage.text('type')),
        );
      }
      for (final group in children) {
        phases.add(
          FootballPhase(stage.id, group.id, group.name, stage.text('type')),
        );
      }
    }
    final teams = <int, FootballRecord>{};
    try {
      final result = await directory(refresh: refresh);
      for (final row in result.rows) {
        teams[row.id] = row;
      }
    } catch (_) {
      /* Competition phases remain usable if the directory fails. */
    }
    return FootballContext(competition, season, phases, teams);
  }
}
