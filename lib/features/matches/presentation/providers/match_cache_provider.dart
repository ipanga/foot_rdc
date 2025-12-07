import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/matches/domain/entities/match.dart';

/// Cache state for a single league's matches
class LeagueMatchCacheState {
  final List<Match> matches;
  final DateTime? lastFetchTime;
  final int currentPage;
  final bool hasReachedEnd;

  const LeagueMatchCacheState({
    this.matches = const [],
    this.lastFetchTime,
    this.currentPage = 1,
    this.hasReachedEnd = false,
  });

  LeagueMatchCacheState copyWith({
    List<Match>? matches,
    DateTime? lastFetchTime,
    int? currentPage,
    bool? hasReachedEnd,
  }) {
    return LeagueMatchCacheState(
      matches: matches ?? this.matches,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
      currentPage: currentPage ?? this.currentPage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
    );
  }

  bool isCacheValid({Duration validDuration = const Duration(minutes: 2)}) {
    if (lastFetchTime == null) return false;
    return DateTime.now().difference(lastFetchTime!) < validDuration;
  }

  bool get isEmpty => matches.isEmpty;
  bool get isNotEmpty => matches.isNotEmpty;
}

/// Cache state for all leagues' matches
class MatchCacheState {
  final Map<int, LeagueMatchCacheState> _leagueCaches;

  const MatchCacheState({Map<int, LeagueMatchCacheState>? leagueCaches})
      : _leagueCaches = leagueCaches ?? const {};

  /// Get cache for a specific league
  LeagueMatchCacheState getLeagueCache(int leagueId) {
    return _leagueCaches[leagueId] ?? const LeagueMatchCacheState();
  }

  /// Check if a league has cached data
  bool hasCachedData(int leagueId) {
    return _leagueCaches.containsKey(leagueId) &&
        _leagueCaches[leagueId]!.isNotEmpty;
  }

  /// Check if cache is valid for a specific league
  bool isCacheValid(int leagueId,
      {Duration validDuration = const Duration(minutes: 2)}) {
    final cache = _leagueCaches[leagueId];
    if (cache == null) return false;
    return cache.isCacheValid(validDuration: validDuration);
  }

  /// Get matches for a specific league
  List<Match> getMatches(int leagueId) {
    return _leagueCaches[leagueId]?.matches ?? [];
  }

  MatchCacheState copyWithLeague(int leagueId, LeagueMatchCacheState cache) {
    final newCaches = Map<int, LeagueMatchCacheState>.from(_leagueCaches);
    newCaches[leagueId] = cache;
    return MatchCacheState(leagueCaches: newCaches);
  }

  // Legacy getters for backwards compatibility
  List<Match> get matches =>
      _leagueCaches.values.expand((c) => c.matches).toList();
  bool get isEmpty => _leagueCaches.isEmpty ||
      _leagueCaches.values.every((c) => c.isEmpty);
  bool get isNotEmpty => !isEmpty;
  int get currentPage => 1;
  bool get hasReachedEnd => false;

  bool legacyIsCacheValid({Duration validDuration = const Duration(minutes: 2)}) {
    if (_leagueCaches.isEmpty) return false;
    return _leagueCaches.values.any((c) => c.isCacheValid(validDuration: validDuration));
  }
}

class MatchCacheNotifier extends StateNotifier<MatchCacheState> {
  MatchCacheNotifier() : super(const MatchCacheState());

  /// Update matches for a specific league
  void updateMatchesForLeague(
    int leagueId,
    List<Match> matches, {
    bool isLoadMore = false,
  }) {
    final currentCache = state.getLeagueCache(leagueId);

    LeagueMatchCacheState newCache;
    if (isLoadMore) {
      newCache = currentCache.copyWith(
        matches: [...currentCache.matches, ...matches],
        lastFetchTime: DateTime.now(),
        currentPage: currentCache.currentPage + 1,
        hasReachedEnd: matches.isEmpty || matches.length < 10,
      );
    } else {
      newCache = currentCache.copyWith(
        matches: matches,
        lastFetchTime: DateTime.now(),
        currentPage: 1,
        hasReachedEnd: matches.isEmpty || matches.length < 10,
      );
    }

    state = state.copyWithLeague(leagueId, newCache);
  }

  /// Clear cache for a specific league
  void clearCacheForLeague(int leagueId) {
    state = state.copyWithLeague(leagueId, const LeagueMatchCacheState());
  }

  /// Clear all caches
  void clearCache() {
    state = const MatchCacheState();
  }

  /// Legacy method for backwards compatibility
  void updateMatches(List<Match> matches, {bool isLoadMore = false}) {
    // Default to Groupe A league ID for legacy calls
    updateMatchesForLeague(546, matches, isLoadMore: isLoadMore);
  }

  void setHasReachedEnd(int leagueId, bool hasReachedEnd) {
    final currentCache = state.getLeagueCache(leagueId);
    state = state.copyWithLeague(
      leagueId,
      currentCache.copyWith(hasReachedEnd: hasReachedEnd),
    );
  }
}

final matchCacheProvider =
    StateNotifierProvider<MatchCacheNotifier, MatchCacheState>((ref) {
      return MatchCacheNotifier();
    });
