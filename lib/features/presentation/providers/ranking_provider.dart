import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/data/datasources/ranking_remote_datasource.dart';
import 'package:foot_rdc/features/data/repositories/ranking_repository_impl.dart';
import 'package:foot_rdc/features/domain/entities/ranking.dart';
import 'package:foot_rdc/features/domain/repositories/ranking_repository.dart';
import 'package:foot_rdc/features/domain/usecases/get_ranking.dart';
import 'package:http/http.dart' as http;

// Provider for HTTP client
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

// Provider for ranking remote data source
final rankingRemoteDataSourceProvider = Provider<RankingRemoteDataSource>((
  ref,
) {
  final client = ref.read(httpClientProvider);
  return RankingRemoteDataSourceImpl(client);
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

// State notifier for managing rankings
class RankingNotifier extends StateNotifier<RankingState> {
  final GetRanking getRanking;

  RankingNotifier(this.getRanking) : super(const RankingState.initial());

  Future<void> fetchRanking({
    required int leagueId,
    required int seasonId,
  }) async {
    state = const RankingState.loading();

    final result = await getRanking(leagueId: leagueId, seasonId: seasonId);

    result.fold(
      (failure) => state = RankingState.error(failure.message),
      (ranking) => state = RankingState.loaded(ranking),
    );
  }
}

// Provider for ranking notifier
final rankingNotifierProvider =
    StateNotifierProvider<RankingNotifier, RankingState>((ref) {
      final getRanking = ref.read(getRankingProvider);
      return RankingNotifier(getRanking);
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
