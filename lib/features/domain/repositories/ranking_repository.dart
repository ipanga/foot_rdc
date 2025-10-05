import 'package:dartz/dartz.dart';
import 'package:foot_rdc/core_error/failures.dart';
import 'package:foot_rdc/features/domain/entities/ranking.dart';

abstract class RankingRepository {
  Future<Either<Failure, Ranking>> getRanking({
    required int leagueId,
    required int seasonId,
  });
}
