import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:foot_rdc/core/errors/failures.dart';
import 'package:foot_rdc/core/network/network_exceptions.dart' as network;
import 'package:foot_rdc/features/rankings/data/datasources/ranking_remote_datasource.dart';
import 'package:foot_rdc/features/rankings/domain/entities/ranking.dart';
import 'package:foot_rdc/features/rankings/domain/repositories/ranking_repository.dart';

class RankingRepositoryImpl implements RankingRepository {
  final RankingRemoteDataSource remoteDataSource;

  RankingRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, Ranking>> getRanking({
    required int leagueId,
    required int seasonId,
  }) async {
    try {
      final ranking = await remoteDataSource.getRanking(
        leagueId: leagueId,
        seasonId: seasonId,
      );
      return Right(ranking);
    } on network.NetworkException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('RankingRepository.getRanking failed: $e\n$st');
      }
      return Left(ServerFailure('Impossible de charger le classement.'));
    }
  }
}
