import 'package:dartz/dartz.dart';
import 'package:foot_rdc/core/errors/failures.dart';
import 'package:foot_rdc/features/rankings/domain/entities/ranking.dart';
import 'package:foot_rdc/features/rankings/domain/repositories/ranking_repository.dart';

class GetRanking {
  final RankingRepository repository;

  GetRanking(this.repository);

  Future<Either<Failure, Ranking>> call({
    required int leagueId,
    required int seasonId,
  }) {
    return repository.getRanking(leagueId: leagueId, seasonId: seasonId);
  }
}
