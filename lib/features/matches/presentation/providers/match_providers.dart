import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:foot_rdc/features/matches/domain/entities/match.dart';

part 'match_providers.g.dart';

/// Fetches matches from the SportsPress API
@riverpod
Future<List<Match>> fetchMatches(Ref ref, String input) async {
  final uri = Uri.parse('${ApiConstants.eventsEndpoint}?$input');
  final response = await http.get(uri, headers: {'Accept': 'application/json'});

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((j) => Match.fromJson(j)).toList();
  } else {
    throw Exception('Failed to load matches');
  }
}
