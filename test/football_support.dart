import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/network/dio_client.dart';
import 'package:foot_rdc/core/theme/app_theme.dart';
import 'package:foot_rdc/features/football/data/football_api.dart';
import 'package:foot_rdc/features/football/data/football_config.dart';
import 'package:foot_rdc/features/football/data/football_repository.dart';
import 'package:foot_rdc/features/football/domain/football_models.dart';
import 'package:foot_rdc/features/football/presentation/football_providers.dart';
import 'package:foot_rdc/features/football/presentation/football_screens.dart';
import 'package:foot_rdc/features/football/presentation/football_strings.dart';

Map<String, dynamic> contract() => Map<String, dynamic>.from(
  jsonDecode(
    File('test/fixtures/staging_core.json').readAsStringSync(),
  )['data'],
);

class MemoryCache implements FootballCache {
  final Map<String, Map<String, dynamic>> values = {};
  bool failWrite = false;
  @override
  Future<Map<String, dynamic>?> read(String key) async => values[key];
  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    if (failWrite) throw StateError('storage unavailable');
    values[key] = value;
  }
}

class CoreAdapter implements HttpClientAdapter {
  final List<Uri> calls = [];
  final Map<String, dynamic> data = contract();
  bool fail = false, failPhases = false, repeatPage = false;
  List<dynamic>? eventOverride;
  List<dynamic> fixtures = [];
  String? matchStatus;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    calls.add(options.uri);
    final path = options.uri.path.split('/rdcfootball/v1/').last;
    if (fail || (failPhases && ['stages', 'groups'].contains(path))) {
      return ResponseBody.fromString(
        '{"message":"SQL private provider failure"}',
        503,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    final dynamic body;
    switch (path) {
      case 'competitions':
        body = data['competitions'];
      case 'competitions/1':
        body = data['competitions'][0];
      case 'seasons':
        body = data['seasons'];
      case 'stages':
        body = data['stages'];
      case 'groups':
        body = data['groups'];
      case 'teams':
        final page = int.parse('${options.queryParameters['page'] ?? 1}');
        final limit = int.parse('${options.queryParameters['limit'] ?? 25}');
        body = (data['teams'] as List)
            .skip(repeatPage ? 0 : (page - 1) * limit)
            .take(limit)
            .toList();
      case 'teams/12':
        body = data['team'];
      case 'teams/12/next-match':
        body = data['next'];
      case 'teams/12/results':
        body = data['results'];
      case 'teams/12/matches':
        body = options.queryParameters['view'] == 'upcoming'
            ? []
            : data['schedule'];
      case 'teams/12/squad':
        body = data['squad'];
      case 'teams/12/statistics':
        body = data['statistics'];
      case 'standings' || 'teams/12/standings':
        body = data['standings'];
      case 'matches':
        body = options.queryParameters['view'] == 'fixtures'
            ? fixtures
            : data['${options.queryParameters['group_id'] ?? ''}' == '1'
                  ? 'group_a_results'
                  : '${options.queryParameters['group_id'] ?? ''}' == '2'
                  ? 'group_b_results'
                  : 'playoff_results'];
      case 'matches/finished':
        body = '${options.queryParameters['page'] ?? 1}' == '1'
            ? data['finished']
            : data['finished_page2'];
      case 'matches/today':
        body = data['today'];
      case 'matches/upcoming':
        body = data['upcoming'];
      case 'matches/446':
        body = {
          ...data['match'] as Map,
          if (matchStatus != null) 'status': matchStatus,
          if (eventOverride != null) 'events': eventOverride,
        };
      case 'matches/446/events':
        body = eventOverride ?? data['events'];
      default:
        return ResponseBody.fromString(
          '{}',
          404,
          headers: {
            'content-type': ['application/json'],
          },
        );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        'content-type': ['application/json'],
        if (path == 'teams') 'x-wp-totalpages': ['2'],
        if (path == 'matches/finished') 'x-wp-totalpages': ['2'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class Harness {
  final FootballConfig config;
  final adapter = CoreAdapter();
  final cache = MemoryCache();
  late final RdcFootballApiClient api;
  late final FootballRepository repository;
  Harness({
    DateTime Function()? clock,
    FootballLiveGate live = const FootballLiveGate(),
  }) : config = FootballConfig(
         origin: Uri.parse('https://staging.sportrdc.com'),
         competitionId: 1,
         seasonId: 1,
         live: live,
       ) {
    final client = DioClient(logResponses: false);
    client.dio.httpClientAdapter = adapter;
    api = RdcFootballApiClient(config, client, cache, clock: clock);
    repository = FootballRepository(api);
  }
  Widget app(Widget screen, {double textScale = 1}) => ProviderScope(
    overrides: [
      footballConfigProvider.overrideWithValue(config),
      footballRepositoryProvider.overrideWith((ref) async => repository),
    ],
    child: MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        FootballStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      onGenerateRoute: footballRoute,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: screen,
    ),
  );
}
