import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/network_exceptions.dart';

/// Why football data could not be shown. Screens turn this into plain French; raw HTTP never reaches the user.
enum FootballError { offline, timeout, server, notFound, malformed, cacheMiss }

class FootballFailure implements Exception {
  final FootballError kind;
  const FootballFailure(this.kind);
  @override
  String toString() => 'FootballFailure(${kind.name})';
}

/// How a read may be served.
enum CachePolicy { cacheOnly, preferCache, network }

class FootballRequest {
  final String path;
  final Map<String, dynamic> query;
  final Duration ttl;
  const FootballRequest(this.path, {this.query = const {}, this.ttl = const Duration(hours: 1)});

  String get key {
    final parts = query.keys.toList()..sort();
    return '$path?${parts.map((k) => '$k=${query[k]}').join('&')}';
  }
}

class FootballEnvelope {
  final dynamic data;
  final int? totalPages;
  const FootballEnvelope(this.data, this.totalPages);
}

abstract interface class FootballCache {
  Future<Map<String, dynamic>?> read(String key);
  Future<void> write(String key, Map<String, dynamic> value);
}

/// Bounded public-JSON cache. Nothing private ever enters it.
class PreferencesFootballCache implements FootballCache {
  final SharedPreferences preferences;
  static const _prefix = 'rdcf:v2:';
  static const _maxEntries = 120;
  static const _maxBytes = 400000;
  PreferencesFootballCache(this.preferences);

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    try {
      final value = preferences.getString('$_prefix$key');
      return value == null ? null : Map<String, dynamic>.from(jsonDecode(value) as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    final encoded = jsonEncode(value);
    if (encoded.length > _maxBytes) return;
    final keys = preferences.getKeys().where((k) => k.startsWith(_prefix)).toList();
    if (keys.length >= _maxEntries) {
      for (final old in keys.take(keys.length - _maxEntries + 1)) {
        await preferences.remove(old);
      }
    }
    await preferences.setString('$_prefix$key', encoded);
  }
}

class MemoryFootballCache implements FootballCache {
  final Map<String, Map<String, dynamic>> values = {};
  @override
  Future<Map<String, dynamic>?> read(String key) async => values[key];
  @override
  Future<void> write(String key, Map<String, dynamic> value) async => values[key] = value;
}

/// Read-only client of the public RDC Football API. Identical requests in flight share one call.
class FootballClient {
  static const baseUrl = String.fromEnvironment(
    'RDCF_API_BASE',
    defaultValue: 'https://footrdc.com/wp-json/rdcfootball/v1',
  );
  final DioClient http;
  final FootballCache cache;
  final DateTime Function() now;
  static const offlineLimit = Duration(hours: 24);
  final Map<String, Future<FootballEnvelope>> _pending = {};

  FootballClient(this.http, this.cache, {DateTime Function()? clock}) : now = clock ?? DateTime.now;

  Future<FootballEnvelope> read(FootballRequest request, CachePolicy policy) async {
    if (policy != CachePolicy.network) {
      final saved = await cache.read(request.key);
      final at = DateTime.tryParse('${saved?['at']}');
      if (saved != null && at != null) {
        final age = now().difference(at);
        final limit = policy == CachePolicy.cacheOnly ? offlineLimit : request.ttl;
        if (!age.isNegative && age < limit) return FootballEnvelope(saved['data'], saved['pages'] as int?);
      }
      if (policy == CachePolicy.cacheOnly) throw const FootballFailure(FootballError.cacheMiss);
    }
    return _pending.putIfAbsent(
      request.key,
      () => _fetch(request).whenComplete(() {
        // Block body: returning the removed future would make it wait on itself.
        _pending.remove(request.key);
      }),
    );
  }

  Future<FootballEnvelope> _fetch(FootballRequest request) async {
    try {
      final response = await http.get<dynamic>(
        '$baseUrl/${request.path}',
        queryParameters: request.query,
        options: Options(followRedirects: false),
      );
      if (response.statusCode == 404) throw const FootballFailure(FootballError.notFound);
      if (response.statusCode != 200) throw const FootballFailure(FootballError.server);
      if (response.data is! List && response.data is! Map) throw const FootballFailure(FootballError.malformed);
      final pages = int.tryParse(response.headers.value('x-wp-totalpages') ?? '');
      if (request.ttl > Duration.zero) {
        try {
          await cache.write(request.key, {
            'at': now().toUtc().toIso8601String(),
            'data': response.data,
            'pages': pages,
          });
        } catch (_) {
          // A full cache must not discard a good response.
        }
      }
      return FootballEnvelope(response.data, pages);
    } on FootballFailure {
      rethrow;
    } on NoInternetException {
      throw const FootballFailure(FootballError.offline);
    } on TimeoutException {
      throw const FootballFailure(FootballError.timeout);
    } on NotFoundException {
      throw const FootballFailure(FootballError.notFound);
    } catch (_) {
      throw const FootballFailure(FootballError.server);
    }
  }
}
