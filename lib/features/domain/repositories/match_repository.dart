import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/domain/entities/match.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'match_repository.g.dart';

@riverpod
MatchRepository matchRepository(Ref ref) {
  return MatchRepository(ref);
}

class MatchRepository {
  final Ref ref;
  MatchRepository(this.ref);

  /// Fetch matches from the FootRDC API.
  ///
  Future<List<Match>> fetchMatchesData(String pagination) async {
    final url = 'https://footrdc.com/wp-json/sportspress/v2/events?$pagination';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load matches (status ${response.statusCode})');
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected response format: expected a JSON array');
    }

    return decoded
        .map<Match>((e) => Match.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
