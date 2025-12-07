import 'dart:convert';
import 'package:foot_rdc/features/rankings/data/models/ranking_model.dart';
import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;

abstract class RankingRemoteDataSource {
  Future<RankingModel> getRanking({
    required int leagueId,
    required int seasonId,
  });
}

class RankingRemoteDataSourceImpl implements RankingRemoteDataSource {
  final http.Client client;

  RankingRemoteDataSourceImpl(this.client);

  @override
  Future<RankingModel> getRanking({
    required int leagueId,
    required int seasonId,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.tablesEndpoint}?leagues=$leagueId&seasons=$seasonId',
    );

    final response = await client.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      if (jsonList.isNotEmpty) {
        // Take the first element from the array response
        return RankingModel.fromJson(jsonList[0] as Map<String, dynamic>);
      } else {
        throw Exception('No ranking data found');
      }
    } else {
      throw Exception('Failed to fetch ranking: ${response.statusCode}');
    }
  }
}
