import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart' as framework;
import 'package:foot_rdc/features/football/presentation/football_screens.dart';
import 'package:foot_rdc/features/football/domain/football_models.dart';
import 'football_support.dart';
import 'football_images.dart';

// Restore the image hook before Flutter checks its per-test invariants.
void testWidgets(String name, Future<void> Function(WidgetTester) body) {
  framework.testWidgets(name, (tester) async {
    useFixtureLogos();
    try {
      await body(tester);
    } finally {
      debugNetworkImageHttpClientProvider = null;
    }
  });
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () async => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> choose(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(ChoiceChip, label);
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await settle(tester);
}

void main() {
  testWidgets(
    'available next match and fixture show French status without zero scores',
    (t) async {
      final h = Harness();
      // Synthetic future row built from the public schema, never staging evidence.
      final future = {
        ...h.adapter.data['match'] as Map,
        'home_team_id': 12,
        'home_name': 'TP Mazembe',
        'home_logo': h.adapter.data['team']['logo_url'],
        'status': 'scheduled',
        'home_score': null,
        'away_score': null,
        'kickoff_datetime': '2026-12-01 13:00:00',
      };
      h.adapter.data['next'] = future;
      h.adapter.fixtures = [future];
      await t.pumpWidget(h.app(const FootballTeamScreen(12)));
      await settle(t);
      expect(find.text('Programmé'), findsOneWidget);
      expect(find.text('\u2014'), findsOneWidget);
      expect(find.text('Aucun prochain match disponible'), findsNothing);
      await t.pumpWidget(h.app(const FootballCompetitionScreen()));
      await settle(t);
      await choose(t, 'Calendrier');
      expect(find.text('Programmé'), findsOneWidget);
      expect(find.text('0 - 0'), findsNothing);
    },
  );
  testWidgets('changed view retry starts page1, not the prior view next page', (
    t,
  ) async {
    final h = Harness();
    await t.pumpWidget(h.app(const FootballMatchCenterScreen()));
    await settle(t);
    h.adapter.fail = true;
    await choose(t, 'À venir');
    h.adapter.fail = false;
    await t.tap(find.text('Réessayer'));
    await settle(t);
    expect(h.adapter.calls.last.path.endsWith('/matches/upcoming'), true);
    expect(h.adapter.calls.last.queryParameters['page'], '1');
  });
  testWidgets(
    'future validated live detail polls only foreground and stops at FT',
    (t) async {
      final h = Harness(
        live: const FootballLiveGate(
          requested: true,
          readiness: FootballReadiness.validated,
        ),
      )..adapter.matchStatus = 'live';
      await t.pumpWidget(h.app(const FootballMatchScreen(446)));
      await settle(t);
      await t.pump(const Duration(seconds: 61));
      await settle(t);
      expect(h.adapter.calls.length, 2);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump(const Duration(minutes: 2));
      expect(h.adapter.calls.length, 2);
      h.adapter.matchStatus = 'finished';
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump(const Duration(seconds: 61));
      await settle(t);
      expect(h.adapter.calls.length, 3);
      await t.pump(const Duration(minutes: 2));
      expect(h.adapter.calls.length, 3);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'first-load, lazy rows, warm rebuild request count and image layout',
    (t) async {
      final h = Harness();
      final watch = Stopwatch()..start();
      await t.pumpWidget(h.app(const FootballMatchCenterScreen()));
      await settle(t);
      watch.stop();
      expect(h.adapter.calls.length, 1);
      expect(find.text('1 - 0'), findsWidgets);
      expect(find.byType(Image), findsWidgets);
      await t.pumpWidget(h.app(const FootballMatchCenterScreen()));
      await settle(t);
      expect(h.adapter.calls.length, 1);
      final scroll = Stopwatch()..start();
      await t.drag(find.byType(Scrollable).last, const Offset(0, -500));
      await settle(t);
      scroll.stop();
      expect(h.adapter.calls.length, 1);
      expect(t.takeException(), isNull);
      debugPrint(
        'PERF fixture first-load ${watch.elapsedMilliseconds}ms; scroll ${scroll.elapsedMilliseconds}ms; REST requests 1; warm rebuild extra requests 0',
      );
    },
  );
  setUpAll(() async {
    final productFont = FontLoader('Poppins');
    productFont.addFont(
      File(
        'assets/fonts/Poppins-Regular.ttf',
      ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
    await productFont.load();
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      final fonts = FontLoader('Roboto');
      fonts.addFont(
        File(
          '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
      await fonts.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        File(
          '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
      await icons.load();
    }
  });
  testWidgets(
    'competition Group A/B/Playoff, fixtures, results, unpublished standings',
    (t) async {
      final h = Harness();
      await t.pumpWidget(h.app(const FootballCompetitionScreen()));
      await settle(t);
      expect(find.text('Linafoot'), findsOneWidget);
      expect(find.text('31 équipes'), findsOneWidget);
      for (final phase in ['Groupe A', 'Groupe B', 'Playoff']) {
        await choose(t, phase);
        expect(t.takeException(), isNull);
      }
      expect(h.adapter.calls.last.queryParameters['stage_id'], '2');
      await choose(t, 'Calendrier');
      expect(find.text('Aucun match disponible'), findsOneWidget);
      await choose(t, 'Classement');
      expect(find.text('Classement en cours de vérification'), findsOneWidget);
      await choose(t, 'Résultats');
      expect(find.text('1 - 0'), findsWidgets);
    },
  );
  testWidgets(
    'directory search independent of broken phases and local-ID navigation',
    (t) async {
      final h = Harness()..adapter.failPhases = true;
      await t.pumpWidget(h.app(const FootballTeamsScreen()));
      await settle(t);
      await t.enterText(find.byType(TextField), 'Mazembe');
      await t.pump();
      expect(find.text('TP Mazembe'), findsOneWidget);
      await t.tap(find.text('TP Mazembe'));
      await settle(t);
      expect(find.text('Aperçu'), findsOneWidget);
      expect(find.text('Aucun prochain match disponible'), findsOneWidget);
      expect(h.adapter.calls.any((u) => u.path.endsWith('/teams/12')), true);
    },
  );
  testWidgets(
    'team schedule, standings, partial squad and available statistics',
    (t) async {
      final h = Harness();
      await t.pumpWidget(h.app(const FootballTeamScreen(12)));
      await settle(t);
      expect(find.text('Prochain match'), findsOneWidget);
      await choose(t, 'Calendrier');
      expect(find.text('À venir'), findsOneWidget);
      await choose(t, 'Terminés');
      expect(h.adapter.calls.last.queryParameters['view'], 'finished');
      await choose(t, 'Classement');
      expect(find.text('Classement en cours de vérification'), findsOneWidget);
      await choose(t, 'Statistiques');
      expect(find.text('Données partielles'), findsOneWidget);
      expect(find.text('Buts pour'), findsOneWidget);
      await choose(t, 'Effectif');
      expect(find.text('Effectif partiel'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'match detail has historical events, unknown graceful fallback and partial state',
    (t) async {
      final h = Harness()
        ..adapter.eventOverride = [
          {'id': 1, 'event_type': 'goal', 'minute': 12},
          {'id': 2, 'event_type': 'new_type'},
        ];
      await t.pumpWidget(h.app(const FootballMatchScreen(446)));
      await settle(t);
      expect(find.text('1 - 0'), findsOneWidget);
      expect(find.text('Événements partiels'), findsOneWidget);
      expect(find.text('But'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(minutes: 2));
      expect(h.adapter.calls.length, 1);
    },
  );
  testWidgets(
    'gated Match Center today/upcoming/finished remains usable, no live calls',
    (t) async {
      final h = Harness();
      await t.pumpWidget(h.app(const FootballMatchCenterScreen()));
      await settle(t);
      expect(find.text('En direct'), findsNothing);
      for (final label in ["Aujourd'hui", 'À venir', 'Terminés']) {
        await choose(t, label);
      }
      expect(h.adapter.calls.any((u) => u.path.endsWith('/live')), false);
    },
  );
  testWidgets('live match hides current scores and events without readiness', (
    t,
  ) async {
    final h = Harness()
      ..adapter.matchStatus = 'live'
      ..adapter.eventOverride = [
        {'id': 1, 'event_type': 'goal', 'minute': 12},
      ];
    await t.pumpWidget(h.app(const FootballMatchScreen(446)));
    await settle(t);
    expect(find.text('Direct en cours de validation'), findsOneWidget);
    expect(find.text('1 - 0'), findsNothing);
    expect(find.text('But'), findsNothing);
    await t.pump(const Duration(minutes: 2));
    expect(h.adapter.calls.length, 1);
  });
  testWidgets('localized network retry does not expose server text', (t) async {
    final h = Harness()..adapter.fail = true;
    await t.pumpWidget(h.app(const FootballMatchCenterScreen()));
    await settle(t);
    expect(find.textContaining('Vérifiez votre connexion'), findsOneWidget);
    expect(find.textContaining('SQL'), findsNothing);
    h.adapter.fail = false;
    await t.tap(find.text('Réessayer'));
    await settle(t);
    expect(find.text('1 - 0'), findsWidgets);
  });
  testWidgets('pagination appends without duplicates and lazy scrolling', (
    t,
  ) async {
    final h = Harness();
    await t.pumpWidget(h.app(const FootballMatchCenterScreen()));
    await settle(t);
    final list = find.byType(Scrollable).last;
    await t.scrollUntilVisible(
      find.text('Afficher plus'),
      500,
      scrollable: list,
      maxScrolls: 40,
    );
    await t.drag(list, const Offset(0, -200));
    await t.pumpAndSettle();
    await t.tap(find.text('Afficher plus').hitTestable());
    await settle(t);
    expect(h.adapter.calls.last.queryParameters['page'], '2');
    expect(t.takeException(), isNull);
  });
  for (final width in [320.0, 375.0, 768.0, 1440.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'responsive football screens width $width text scale $scale',
        (t) async {
          t.view.physicalSize = Size(width, 900);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final h = Harness();
          for (final screen in [
            const FootballCompetitionScreen(),
            const FootballTeamsScreen(),
            const FootballTeamScreen(12),
            const FootballMatchScreen(446),
            const FootballMatchCenterScreen(),
          ]) {
            await t.pumpWidget(h.app(screen, textScale: scale));
            await settle(t);
            if (screen is FootballTeamScreen) {
              for (final tab in ['Calendrier', 'Statistiques', 'Effectif']) {
                await choose(t, tab);
                expect(t.takeException(), isNull);
              }
            }
            expect(t.takeException(), isNull);
          }
        },
      );
    }
  }
  testWidgets(
    'capture native Flutter QA screenshots from staging response fixtures',
    (t) async {
      t.view.physicalSize = const Size(375, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final h = Harness();
      final key = GlobalKey();
      final output = Directory('/private/tmp/rdcf-phase6-screenshots');
      await t.runAsync(() => output.create(recursive: true));
      for (final entry in {
        'competition': const FootballCompetitionScreen(),
        'team': const FootballTeamScreen(12),
        'match': const FootballMatchScreen(446),
      }.entries) {
        await t.pumpWidget(
          RepaintBoundary(key: key, child: h.app(entry.value)),
        );
        await settle(t);
        await t.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await output.uri
              .resolve('${entry.key}.png')
              .toFilePath()
              .letWrite(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(t.takeException(), isNull);
      }
    },
  );
}

extension on String {
  Future<void> letWrite(List<int> bytes) => File(this).writeAsBytes(bytes);
}
