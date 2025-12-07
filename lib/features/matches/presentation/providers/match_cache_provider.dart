import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/matches/domain/entities/match.dart';

class MatchCacheState {
  final List<Match> matches;
  final DateTime? lastFetchTime;
  final int currentPage;
  final bool hasReachedEnd;

  const MatchCacheState({
    this.matches = const [],
    this.lastFetchTime,
    this.currentPage = 1,
    this.hasReachedEnd = false,
  });

  MatchCacheState copyWith({
    List<Match>? matches,
    DateTime? lastFetchTime,
    int? currentPage,
    bool? hasReachedEnd,
  }) {
    return MatchCacheState(
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

class MatchCacheNotifier extends StateNotifier<MatchCacheState> {
  MatchCacheNotifier() : super(const MatchCacheState());

  void updateMatches(List<Match> matches, {bool isLoadMore = false}) {
    if (isLoadMore) {
      state = state.copyWith(
        matches: [...state.matches, ...matches],
        lastFetchTime: DateTime.now(),
        currentPage: state.currentPage + 1,
        hasReachedEnd: matches.isEmpty || matches.length < 10,
      );
    } else {
      state = state.copyWith(
        matches: matches,
        lastFetchTime: DateTime.now(),
        currentPage: 1,
        hasReachedEnd: matches.isEmpty || matches.length < 10,
      );
    }
  }

  void clearCache() {
    state = const MatchCacheState();
  }

  void setHasReachedEnd(bool hasReachedEnd) {
    state = state.copyWith(hasReachedEnd: hasReachedEnd);
  }
}

final matchCacheProvider =
    StateNotifierProvider<MatchCacheNotifier, MatchCacheState>((ref) {
      return MatchCacheNotifier();
    });
