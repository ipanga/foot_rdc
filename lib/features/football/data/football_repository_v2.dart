import '../domain/models.dart';
import 'football_client.dart';
import 'football_mappers.dart';

const _matchTtl = Duration(minutes: 2);
const _tableTtl = Duration(minutes: 2);

/// The only door to football data. Returns domain types, keeps seasons apart, computes nothing.
class FootballRepository {
  final FootballClient client;
  static const competitionId = 1;
  FootballRepository(this.client);

  Future<T> _one<T>(FootballRequest request, CachePolicy policy, T Function(Map<String, dynamic>) map) async {
    final data = (await client.read(request, policy)).data;
    if (data is! Map) throw const FootballFailure(FootballError.malformed);
    try {
      return map(Map<String, dynamic>.from(data));
    } on FormatException {
      throw const FootballFailure(FootballError.malformed);
    }
  }

  Future<List<T>> _list<T>(FootballRequest request, CachePolicy policy, T Function(Map<String, dynamic>) map) async {
    final data = (await client.read(request, policy)).data;
    try {
      return mapRows(data, map);
    } on FormatException {
      throw const FootballFailure(FootballError.malformed);
    }
  }

  Future<PageResult<Match>> _matches(FootballRequest request, CachePolicy policy, int page) async {
    final envelope = await client.read(request, policy);
    final List<Match> rows;
    try {
      rows = mapRows(envelope.data, matchFrom);
    } on FormatException {
      throw const FootballFailure(FootballError.malformed);
    }
    return PageResult(rows, hasMore: page < (envelope.totalPages ?? 1));
  }

  Future<Competition> competition({CachePolicy policy = CachePolicy.preferCache}) =>
      _one(const FootballRequest('competitions/$competitionId'), policy, competitionFrom);

  /// Newest first; the current season comes from the API, never from a constant.
  Future<List<Season>> seasons({CachePolicy policy = CachePolicy.preferCache}) async {
    final rows = await _list(const FootballRequest('competitions/$competitionId/seasons'), policy, seasonFrom);
    return rows..sort((a, b) => b.name.compareTo(a.name));
  }

  Future<List<Stage>> stages(int season, {CachePolicy policy = CachePolicy.preferCache}) async {
    final rows = await _list(FootballRequest('stages', query: {'season_id': season}), policy, stageFrom);
    return rows..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<List<Group>> groups(int season, {CachePolicy policy = CachePolicy.preferCache}) =>
      _list(FootballRequest('groups', query: {'season_id': season}), policy, groupFrom);

  Future<List<Club>> clubs(int season, {CachePolicy policy = CachePolicy.preferCache}) async {
    final rows = await _list(FootballRequest('teams', query: {'season_id': season, 'limit': 100}), policy, clubFrom);
    return rows..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<Club> club(int id, {CachePolicy policy = CachePolicy.preferCache}) =>
      _one(FootballRequest('teams/$id'), policy, clubFrom);

  Future<ClubProfile?> clubProfile(int id, {CachePolicy policy = CachePolicy.preferCache}) =>
      _one(FootballRequest('teams/$id/profile'), policy, clubProfileFrom);

  Future<List<ClubNewsItem>> clubNews(int id, {CachePolicy policy = CachePolicy.preferCache}) => _list(
    FootballRequest('teams/$id/news', query: const {'limit': 10}, ttl: const Duration(minutes: 15)),
    policy,
    clubNewsFrom,
  );

  /// All tables of a season, in stage order, each sorted as the server positioned it.
  Future<List<StandingTable>> standings(int season, {CachePolicy policy = CachePolicy.preferCache}) async {
    final stageRows = await stages(season, policy: policy);
    final groupRows = await groups(season, policy: policy);
    final clubRows = {for (final club in await clubs(season, policy: policy)) club.id: club};
    final rows = await _list(
      FootballRequest('standings', query: {'season_id': season, 'limit': 100}, ttl: _tableTtl),
      policy,
      (json) => standingFrom(json, clubRows),
    );
    final tables = <StandingTable>[];
    for (final stage in stageRows) {
      final inStage = rows.where((row) => row.stageId == stage.id).toList();
      final stageGroups = groupRows.where((group) => group.stageId == stage.id).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (stageGroups.isEmpty && inStage.isNotEmpty) {
        tables.add(StandingTable(stage: stage, rows: inStage..sort((a, b) => a.position.compareTo(b.position))));
      }
      for (final group in stageGroups) {
        final table = inStage.where((row) => row.groupId == group.id).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
        if (table.isNotEmpty) tables.add(StandingTable(stage: stage, group: group, rows: table));
      }
      final loose = inStage.where((row) => row.groupId == null).toList();
      if (stageGroups.isNotEmpty && loose.isNotEmpty) {
        tables.add(StandingTable(stage: stage, rows: loose..sort((a, b) => a.position.compareTo(b.position))));
      }
    }
    return tables;
  }

  static const pageSize = 30;

  /// [view] is `fixtures` (next first) or `results` (latest first).
  Future<PageResult<Match>> seasonMatches(
    int season,
    String view, {
    int page = 1,
    int? group,
    int? stage,
    CachePolicy policy = CachePolicy.preferCache,
  }) => _matches(
    FootballRequest(
      'matches',
      query: {
        'season_id': season,
        'view': view,
        'limit': pageSize,
        'page': page,
        if (group != null) 'group_id': group,
        if (stage != null) 'stage_id': stage,
      },
      ttl: _matchTtl,
    ),
    policy,
    page,
  );

  /// `today`, `upcoming`, `finished` or `live`. Live is never cached.
  Future<PageResult<Match>> window(
    String name,
    int season, {
    int page = 1,
    int limit = pageSize,
    CachePolicy policy = CachePolicy.preferCache,
  }) => _matches(
    FootballRequest(
      'matches/$name',
      query: {'season_id': season, 'limit': limit, 'page': page},
      ttl: name == 'live' ? Duration.zero : _matchTtl,
    ),
    name == 'live' ? CachePolicy.network : policy,
    page,
  );

  Future<Match> match(int id, {CachePolicy policy = CachePolicy.preferCache, bool live = false}) => _one(
    FootballRequest('matches/$id', ttl: live ? Duration.zero : _matchTtl),
    live ? CachePolicy.network : policy,
    matchFrom,
  );

  /// Oldest event first, as a timeline reads.
  Future<List<MatchEvent>> events(int id, {CachePolicy policy = CachePolicy.preferCache, bool live = false}) async {
    final rows = await _list(
      FootballRequest('matches/$id/events', ttl: live ? Duration.zero : _matchTtl),
      live ? CachePolicy.network : policy,
      eventFrom,
    );
    return rows..sort((a, b) => (a.minute ?? 0).compareTo(b.minute ?? 0));
  }

  Future<PageResult<Match>> clubMatches(
    int team,
    int season,
    String view, {
    int page = 1,
    CachePolicy policy = CachePolicy.preferCache,
  }) => _matches(
    FootballRequest(
      view == 'results' ? 'teams/$team/results' : 'teams/$team/matches',
      query: {'season_id': season, 'limit': pageSize, 'page': page, if (view != 'results') 'view': 'upcoming'},
      ttl: _matchTtl,
    ),
    policy,
    page,
  );

  Future<List<SquadMember>> squad(int team, int season, {CachePolicy policy = CachePolicy.preferCache}) =>
      _list(FootballRequest('teams/$team/squad', query: {'season_id': season, 'limit': 100}), policy, squadMemberFrom);

  Future<Player> player(int id, {CachePolicy policy = CachePolicy.preferCache}) =>
      _one(FootballRequest('players/$id'), policy, playerFrom);

  Future<List<Player>> searchPlayers(String text, {CachePolicy policy = CachePolicy.preferCache}) => _list(
    FootballRequest('players', query: {'search': text, 'limit': 20}, ttl: const Duration(minutes: 10)),
    policy,
    playerFrom,
  );
}

/// Shows the saved copy first, then the fresh one. A failed refresh keeps what is on screen and marks it stale.
Stream<Loaded<T>> staleWhileRevalidate<T>(Future<T> Function(CachePolicy policy) load) async* {
  T? shown;
  var has = false;
  try {
    shown = await load(CachePolicy.cacheOnly);
    has = true;
    yield Loaded(shown as T);
  } on FootballFailure {
    // Nothing saved: wait for the network.
  }
  try {
    yield Loaded(await load(CachePolicy.preferCache));
  } on FootballFailure {
    if (!has) rethrow;
    yield Loaded(shown as T, stale: true);
  }
}
