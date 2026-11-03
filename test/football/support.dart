import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/network/dio_client.dart';
import 'package:foot_rdc/features/football/data/football_client.dart';
import 'package:foot_rdc/features/football/data/football_repository.dart';
import 'package:foot_rdc/features/football/presentation/providers.dart';

Map<String, dynamic> productionContract() => Map<String, dynamic>.from(
  jsonDecode(File('test/fixtures/production_contract.json').readAsStringSync())['data'] as Map,
);

/// Serves the captured Production responses. No network is touched in tests.
class ContractAdapter implements HttpClientAdapter {
  final Map<String, dynamic> data;
  final List<Uri> calls = [];
  int? failWith;
  bool offline = false;
  bool timeout = false;
  ContractAdapter([Map<String, dynamic>? data]) : data = data ?? productionContract();

  dynamic route(Uri uri) {
    final path = uri.path.split('/rdcfootball/v1/').last;
    final q = uri.queryParameters;
    final past = q['season_id'] == '325';
    return switch (path) {
      'competitions/1' => data['competition'],
      'competitions/1/seasons' => data['seasons'],
      'stages' => past ? data['stages_past'] : data['stages_current'],
      'groups' => past ? data['groups_past'] : data['groups_current'],
      'teams' => past ? data['teams_past'] : data['teams_current'],
      'standings' => past ? data['standings_past'] : data['standings_current'],
      'matches/upcoming' => data['upcoming'],
      'matches/finished' => past ? data['finished_past'] : data['finished'],
      'matches/today' => data['today'],
      'matches/live' => data['live'],
      'matches' => q['view'] == 'results' ? (past ? data['finished_past'] : data['finished']) : data['upcoming'],
      'matches/6476' => data['match'],
      'matches/6476/events' => data['events'],
      'teams/4' => data['team'],
      'teams/4/profile' => data['profile'],
      'teams/4/news' => data['team_news'],
      'teams/4/next-match' => data['next_match'],
      'teams/4/results' => data['team_results'],
      'teams/4/matches' => data['team_matches'],
      'teams/4/squad' => past ? data['squad_past'] : data['squad'],
      'players' => data['players'],
      _ when path.startsWith('players/') => data['player'],
      _ => null,
    };
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options.uri);
    if (timeout) throw DioException.connectionTimeout(requestOptions: options, timeout: const Duration(seconds: 1));
    if (offline) throw DioException.connectionError(requestOptions: options, reason: 'offline');
    if (failWith != null) return ResponseBody.fromString('{}', failWith!, headers: _json);
    final body = route(options.uri);
    if (body == null) return ResponseBody.fromString('{"code":"rdcf_not_found"}', 404, headers: _json);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        ..._json,
        'x-wp-totalpages': ['1'],
      },
    );
  }

  static const _json = {
    'content-type': ['application/json'],
  };
  @override
  void close({bool force = false}) {}
}

(FootballRepository, ContractAdapter, MemoryFootballCache) contractRepository({
  DateTime Function()? clock,
  Map<String, dynamic>? data,
}) {
  final http = DioClient(baseUrl: FootballClient.baseUrl, logResponses: false);
  http.dio.interceptors.clear();
  final adapter = ContractAdapter(data);
  http.dio.httpClientAdapter = adapter;
  final cache = MemoryFootballCache();
  return (FootballRepository(FootballClient(http, cache, clock: clock)), adapter, cache);
}

/// A screen inside the app shell's providers, French, at a phone size.
Widget app(
  Widget home,
  FootballRepository repo, {
  double scale = 1,
  Size size = const Size(390, 844),
  List<Override> extra = const [],
}) => ProviderScope(
  overrides: [footballRepositoryProvider.overrideWith((ref) async => repo), ...extra],
  child: MediaQuery(
    data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
    child: MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    ),
  ),
);

/// Lets streams, timers and frames settle without waiting on real time.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}
