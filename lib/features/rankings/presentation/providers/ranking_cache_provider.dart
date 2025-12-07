import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/rankings/domain/entities/ranking.dart';

class RankingCacheState {
  final Map<String, Ranking> rankings;
  final Map<String, DateTime> lastFetchTimes;

  const RankingCacheState({
    this.rankings = const {},
    this.lastFetchTimes = const {},
  });

  RankingCacheState copyWith({
    Map<String, Ranking>? rankings,
    Map<String, DateTime>? lastFetchTimes,
  }) {
    return RankingCacheState(
      rankings: rankings ?? this.rankings,
      lastFetchTimes: lastFetchTimes ?? this.lastFetchTimes,
    );
  }

  String _getCacheKey(int leagueId, int seasonId) => '${leagueId}_$seasonId';

  bool isCacheValid(
    int leagueId,
    int seasonId, {
    Duration validDuration = const Duration(minutes: 2),
  }) {
    final key = _getCacheKey(leagueId, seasonId);
    final lastFetch = lastFetchTimes[key];
    if (lastFetch == null) return false;

    return DateTime.now().difference(lastFetch) < validDuration;
  }

  Ranking? getCachedRanking(int leagueId, int seasonId) {
    final key = _getCacheKey(leagueId, seasonId);
    return rankings[key];
  }

  bool hasCachedData(int leagueId, int seasonId) {
    final key = _getCacheKey(leagueId, seasonId);
    return rankings.containsKey(key);
  }
}

class RankingCacheNotifier extends StateNotifier<RankingCacheState> {
  RankingCacheNotifier() : super(const RankingCacheState());

  void cacheRanking(int leagueId, int seasonId, Ranking ranking) {
    final key = '${leagueId}_$seasonId';
    state = state.copyWith(
      rankings: {...state.rankings, key: ranking},
      lastFetchTimes: {...state.lastFetchTimes, key: DateTime.now()},
    );
  }

  void clearCache() {
    state = const RankingCacheState();
  }

  void clearCacheForLeague(int leagueId, int seasonId) {
    final key = '${leagueId}_$seasonId';
    final newRankings = Map<String, Ranking>.from(state.rankings)..remove(key);
    final newLastFetchTimes = Map<String, DateTime>.from(state.lastFetchTimes)
      ..remove(key);

    state = state.copyWith(
      rankings: newRankings,
      lastFetchTimes: newLastFetchTimes,
    );
  }
}

final rankingCacheProvider =
    StateNotifierProvider<RankingCacheNotifier, RankingCacheState>((ref) {
      return RankingCacheNotifier();
    });
