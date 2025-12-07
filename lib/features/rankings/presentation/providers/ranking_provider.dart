import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/network/dio_client.dart';
import 'package:foot_rdc/features/rankings/data/datasources/ranking_remote_datasource.dart';
import 'package:foot_rdc/features/rankings/data/repositories/ranking_repository_impl.dart';
import 'package:foot_rdc/features/rankings/domain/entities/ranking.dart';
import 'package:foot_rdc/features/rankings/domain/repositories/ranking_repository.dart';
import 'package:foot_rdc/features/rankings/domain/usecases/get_ranking.dart';
import 'package:foot_rdc/features/rankings/presentation/providers/ranking_cache_provider.dart';

// Provider for ranking remote data source
final rankingRemoteDataSourceProvider = Provider<RankingRemoteDataSource>((
  ref,
) {
  final dioClient = ref.watch(dioClientProvider);
  return RankingRemoteDataSourceImpl(dioClient);
});

// Provider for ranking repository
final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  final remoteDataSource = ref.read(rankingRemoteDataSourceProvider);
  return RankingRepositoryImpl(remoteDataSource);
});

// Provider for get ranking use case
final getRankingProvider = Provider<GetRanking>((ref) {
  final repository = ref.read(rankingRepositoryProvider);
  return GetRanking(repository);
});

// State notifier for managing rankings with caching
class RankingNotifier extends StateNotifier<RankingState> {
  final GetRanking getRanking;
  final Ref ref;

  RankingNotifier(this.getRanking, this.ref)
    : super(const RankingState.initial());

  Future<void> fetchRanking({
    required int leagueId,
    required int seasonId,
    bool forceRefresh = false,
  }) async {
    final cacheState = ref.read(rankingCacheProvider);

    // Check if we have valid cached data and no force refresh
    if (!forceRefresh &&
        cacheState.isCacheValid(leagueId, seasonId) &&
        cacheState.hasCachedData(leagueId, seasonId)) {
      final cachedRanking = cacheState.getCachedRanking(leagueId, seasonId);
      if (cachedRanking != null) {
        state = RankingState.loaded(cachedRanking);
        return;
      }
    }

    state = const RankingState.loading();

    final result = await getRanking(leagueId: leagueId, seasonId: seasonId);

    result.fold((failure) => state = RankingState.error(failure.message), (
      ranking,
    ) {
      // Cache the successful result
      ref
          .read(rankingCacheProvider.notifier)
          .cacheRanking(leagueId, seasonId, ranking);
      state = RankingState.loaded(ranking);
    });
  }

  void loadFromCacheIfAvailable({
    required int leagueId,
    required int seasonId,
  }) {
    final cacheState = ref.read(rankingCacheProvider);
    final cachedRanking = cacheState.getCachedRanking(leagueId, seasonId);

    if (cachedRanking != null) {
      state = RankingState.loaded(cachedRanking);
    }
  }
}

// Provider for ranking notifier
final rankingNotifierProvider =
    StateNotifierProvider<RankingNotifier, RankingState>((ref) {
      final getRanking = ref.read(getRankingProvider);
      return RankingNotifier(getRanking, ref);
    });

// Ranking state classes
abstract class RankingState {
  const RankingState();

  const factory RankingState.initial() = RankingInitial;
  const factory RankingState.loading() = RankingLoading;
  const factory RankingState.loaded(Ranking ranking) = RankingLoaded;
  const factory RankingState.error(String message) = RankingError;
}

class RankingInitial extends RankingState {
  const RankingInitial();
}

class RankingLoading extends RankingState {
  const RankingLoading();
}

class RankingLoaded extends RankingState {
  final Ranking ranking;
  const RankingLoaded(this.ranking);
}

class RankingError extends RankingState {
  final String message;
  const RankingError(this.message);
}
