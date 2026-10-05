import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../domain/football_models.dart';
import 'football_config.dart';

class FootballFailure implements Exception {
  final String code;
  const FootballFailure([this.code = 'network']);
  @override
  String toString() => 'FootballFailure($code)';
}

class FootballResponse {
  final dynamic data;
  final Headers headers;
  final bool cached;
  const FootballResponse(this.data, this.headers, {this.cached = false});
}

abstract interface class FootballCache {
  Future<Map<String, dynamic>?> read(String key);
  Future<void> write(String key, Map<String, dynamic> value);
}

class PreferencesFootballCache implements FootballCache {
  final SharedPreferences preferences;
  PreferencesFootballCache(this.preferences);
  String _key(String key) => 'rdcf:v1:${Uri.encodeComponent(key)}';
  @override
  Future<Map<String, dynamic>?> read(String key) async {
    try {
      final value = preferences.getString(_key(key));
      return value == null
          ? null
          : Map<String, dynamic>.from(jsonDecode(value));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    final keys = preferences
        .getKeys()
        .where((key) => key.startsWith('rdcf:v1:'))
        .toList();
    if (keys.length >= 100 && !keys.contains(_key(key))) {
      for (final old in keys.take(keys.length - 99)) {
        await preferences.remove(old);
      }
    }
    await preferences.setString(_key(key), jsonEncode(value));
  }
}

class RdcFootballApiClient {
  final FootballConfig config;
  final DioClient client;
  final FootballCache cache;
  final DateTime Function() now;
  int requestCount = 0;
  final Map<String, Future<FootballResponse>> _pending = {};
  RdcFootballApiClient(
    this.config,
    this.client,
    this.cache, {
    DateTime Function()? clock,
  }) : now = clock ?? DateTime.now;

  Future<FootballResponse> get(FootballQuery query, {bool refresh = false}) {
    if (!_allowed(query.path) ||
        (query.path == 'matches/live' && !config.live.enabled)) {
      throw const FootballFailure('unavailable');
    }
    final key = '${config.baseUrl}/${query.key}';
    return _pending.putIfAbsent(
      key,
      () => _get(query, key, refresh).whenComplete(() {
        _pending.remove(key);
      }),
    );
  }

  bool _allowed(String path) => RegExp(
    r'^(competitions(?:/\d+)?|seasons|stages|groups|teams(?:/\d+(?:/(?:matches|next-match|results|standings|squad|statistics))?)?|standings|matches(?:/(?:live|today|upcoming|finished|\d+(?:/events)?))?)$',
  ).hasMatch(path);

  Future<FootballResponse> _get(
    FootballQuery query,
    String key,
    bool refresh,
  ) async {
    Map<String, dynamic>? saved;
    FootballResponse? cached;
    try {
      saved = await cache.read(key);
      if (saved != null && (saved['data'] is List || saved['data'] is Map)) {
        cached = FootballResponse(
          saved['data'],
          Headers.fromMap(
            (saved['headers'] as Map).map(
              (key, value) =>
                  MapEntry('$key', List<String>.from(value as List)),
            ),
          ),
          cached: true,
        );
      }
    } catch (_) {
      saved = null;
    }
    final stamp = DateTime.tryParse('${saved?['at']}');
    final age = stamp == null
        ? const Duration(days: 99)
        : now().difference(stamp);
    final short =
        query.path.startsWith('matches') ||
        query.path.endsWith('/matches') ||
        query.path.endsWith('/next-match');
    final standings =
        query.path == 'standings' || query.path.endsWith('/standings');
    final ttl = standings
        ? Duration.zero
        : short
        ? const Duration(minutes: 2)
        : const Duration(hours: 1);
    final validAge = !age.isNegative;
    if (!refresh && cached != null && validAge && age < ttl) {
      return cached;
    }
    try {
      requestCount++;
      final response = await client.get<dynamic>(
        '${config.baseUrl}/${query.path}',
        queryParameters: query.filters,
        options: Options(followRedirects: false),
      );
      if (response.statusCode != 200 ||
          (response.data is! List && response.data is! Map)) {
        throw FootballFailure(
          response.statusCode == 404 ? 'unavailable' : 'network',
        );
      }
      final result = FootballResponse(response.data, response.headers);
      try {
        if (!standings) {
          await cache.write(key, {
            'at': now().toUtc().toIso8601String(),
            'data': response.data,
            'headers': response.headers.map,
          });
        }
      } catch (_) {
        /* Storage failure must not discard a successful response. */
      }
      return result;
    } catch (error) {
      if (cached != null &&
          validAge &&
          age < const Duration(hours: 24) &&
          !standings &&
          query.path != 'matches/live' &&
          !_containsLive(cached.data)) {
        return cached;
      }
      if (error is FootballFailure) rethrow;
      throw const FootballFailure();
    }
  }

  bool _containsLive(dynamic data) => data is List
      ? data.any(_containsLive)
      : data is Map && ['live', 'halftime'].contains(data['status']);
}
