import 'package:foot_rdc/features/rankings/data/models/ranking_model.dart';
import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:foot_rdc/core/network/dio_client.dart';

abstract class RankingRemoteDataSource {
  Future<RankingModel> getRanking({
    required int leagueId,
    required int seasonId,
  });
}

class RankingRemoteDataSourceImpl implements RankingRemoteDataSource {
  final DioClient _dioClient;

  RankingRemoteDataSourceImpl(this._dioClient);

  @override
  Future<RankingModel> getRanking({
    required int leagueId,
    required int seasonId,
  }) async {
    final response = await _dioClient.get<List<dynamic>>(
      '${ApiConstants.sportsApiPath}/tables',
      queryParameters: {
        'leagues': leagueId,
        'seasons': seasonId,
      },
    );

    final List<dynamic> jsonList = response.data ?? [];
    if (jsonList.isNotEmpty) {
      return RankingModel.fromJson(jsonList[0] as Map<String, dynamic>);
    } else {
      throw Exception('No ranking data found');
    }
  }
}
