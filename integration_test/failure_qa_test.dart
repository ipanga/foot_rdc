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
import 'package:foot_rdc/features/football/presentation/screens/classement_screen.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Mode { online, offline, timeout, serverError, malformed }

/// Real HTTP while online; the failure states are injected at the HTTP layer so each one can be shown on purpose.
class SwitchAdapter implements HttpClientAdapter {
  final HttpClientAdapter real;
  Mode mode = Mode.online;
  SwitchAdapter(this.real);

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async => switch (mode) {
    Mode.online => real.fetch(o, body, cancel),
    Mode.offline => throw DioException.connectionError(requestOptions: o, reason: 'QA offline'),
    Mode.timeout => throw DioException.connectionTimeout(requestOptions: o, timeout: const Duration(seconds: 1)),
    Mode.serverError => ResponseBody.fromString('Internal Server Error', 500),
    Mode.malformed => ResponseBody.fromString('<html>not json</html>', 200),
  };

  @override
  void close({bool force = false}) => real.close(force: force);
}

/// On-device failure states with a real cache: read-only against Production while online.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('failure states', (tester) async {
    await initializeDateFormatting('fr');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final http = DioClient(baseUrl: FootballClient.baseUrl, logResponses: false);
    final adapter = SwitchAdapter(http.dio.httpClientAdapter);
    http.dio.httpClientAdapter = adapter;
    var offset = Duration.zero;
    final repo = FootballRepository(
      FootballClient(http, PreferencesFootballCache(prefs), clock: () => DateTime.now().add(offset)),
    );
    final os = Platform.operatingSystem;
    var converted = false;

    Future<void> scenario(String name, Mode mode, Duration age, Finder expected) async {
      adapter.mode = mode;
      offset = age;
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [footballRepositoryProvider.overrideWith((ref) async => repo)],
          child: const MaterialApp(
            locale: Locale('fr'),
            supportedLocales: [Locale('fr')],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: ClassementScreen(),
          ),
        ),
      );
      if (Platform.isAndroid && !converted) {
        await binding.convertFlutterSurfaceToImage();
        converted = true;
      }
      for (var i = 0; i < 200 && expected.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pump(const Duration(milliseconds: 300));
      await binding.takeScreenshot('$os-etat-$name');
      // ignore: avoid_print
      print('QA-STATE $name found=${expected.evaluate().isNotEmpty}');
      expect(expected, findsWidgets, reason: name);
      for (final raw in ['Exception', 'Dio', 'HTTP', '500', 'html']) {
        expect(find.textContaining(raw), findsNothing, reason: '$name shows raw text $raw');
      }
    }

    await scenario('en-ligne', Mode.online, Duration.zero, find.text('Blessing'));
    await scenario('cache-ancien', Mode.offline, const Duration(hours: 1), find.textContaining('Données enregistrées'));
    expect(find.text('Blessing'), findsOneWidget);
    await scenario('hors-ligne', Mode.offline, const Duration(days: 3), find.textContaining('Pas de connexion'));
    await prefs.clear();
    await scenario('delai', Mode.timeout, Duration.zero, find.textContaining('trop de temps'));
    await scenario('erreur-serveur', Mode.serverError, Duration.zero, find.textContaining('indisponibles'));
    await scenario('reponse-invalide', Mode.malformed, Duration.zero, find.textContaining('indisponibles'));
    await tester.pumpWidget(const SizedBox());
    await prefs.clear();
  });
}
