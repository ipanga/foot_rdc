import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:foot_rdc/core/network/dio_client.dart';
import 'package:foot_rdc/features/matches/domain/entities/match.dart';

part 'match_providers.g.dart';

/// Fetches matches from the SportsPress API
@riverpod
Future<List<Match>> fetchMatches(Ref ref, String input) async {
  final dioClient = ref.watch(dioClientProvider);

  // Parse the input string to extract query parameters
  final params = Uri.splitQueryString(input);
  final queryParams = <String, dynamic>{};

  for (final entry in params.entries) {
    // Convert numeric strings to integers for known numeric fields
    if (entry.key == 'page' ||
        entry.key == 'per_page' ||
        entry.key == 'leagues' ||
        entry.key == 'seasons') {
      queryParams[entry.key] = int.tryParse(entry.value) ?? entry.value;
    } else {
      queryParams[entry.key] = entry.value;
    }
  }

  final response = await dioClient.get<List<dynamic>>(
    '${ApiConstants.sportsApiPath}/events',
    queryParameters: queryParams,
  );

  final List<dynamic> jsonList = response.data ?? [];
  return jsonList.map((j) => Match.fromJson(j)).toList();
}

/// Fetches matches for a specific league group
@riverpod
Future<List<Match>> fetchMatchesByLeague(
  Ref ref, {
  required int leagueId,
  required int seasonId,
  required int page,
  required int perPage,
}) async {
  final dioClient = ref.watch(dioClientProvider);

  final response = await dioClient.get<List<dynamic>>(
    '${ApiConstants.sportsApiPath}/events',
    queryParameters: {
      'leagues': leagueId,
      'seasons': seasonId,
      'page': page,
      'per_page': perPage,
    },
  );

  final List<dynamic> jsonList = response.data ?? [];
  return jsonList.map((j) => Match.fromJson(j)).toList();
}
