import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/navigation/deep_link_handler.dart';
import 'package:foot_rdc/core/notifications/push.dart';
import 'package:foot_rdc/features/football/data/football_repository.dart';
import 'package:foot_rdc/features/football/presentation/providers.dart';
import 'package:foot_rdc/features/football/presentation/widgets/football_widgets.dart';
import 'package:foot_rdc/features/more/settings_screens.dart';
import 'package:foot_rdc/features/onboarding/club_onboarding.dart';
import 'package:foot_rdc/shared/providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../football/support.dart';
import '../shared/notifications_test.dart' show FakeBackend, FakeGateway;

/// First-launch club selection: offered once, never blocking, choices kept, alerts asked in context.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ClubCrest.loadImages = false;
  });

  test('offered only before any answer and only without followed clubs', () {
    expect(ClubOnboarding.shouldOffer(state: null, followed: const {}), isTrue);
    expect(ClubOnboarding.shouldOffer(state: null, followed: const {4}), isFalse);
    for (final s in ['later', 'done', 'followed']) {
      expect(ClubOnboarding.shouldOffer(state: s, followed: const {}), isFalse, reason: s);
    }
  });

  late FakeGateway gateway;

  Widget shell(FootballRepository repo, Widget home, {Size size = const Size(390, 844), double scale = 1}) {
    gateway = FakeGateway(perm: PushPermission.notDetermined);
    return ProviderScope(
      overrides: [
        footballRepositoryProvider.overrideWith((ref) async => repo),
        notificationNotifierProvider.overrideWith(
          (ref) => NotificationNotifier(
            gateway,
            FakeBackend(),
            PushStore(),
            debounce: Duration.zero,
            appVersion: () async => 'test',
          ),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
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
  }

  const home = ClubOnboardingGate(child: Scaffold(body: Text('Accueil')));

  testWidgets('fresh install: offered over Home; choose, search, Continuer saves clubs and turns on alerts', (
    tester,
  ) async {
    final (repo, _, _) = contractRepository();
    await tester.pumpWidget(shell(repo, home));
    await settle(tester);
    expect(find.text('Suivez vos clubs'), findsOneWidget);
    expect(find.text('AC Rangers'), findsOneWidget);
    final cont = find.byKey(const ValueKey('onboarding-continue'));
    expect(tester.widget<FilledButton>(cont).onPressed, isNull, reason: 'nothing chosen yet');
    expect(gateway.calls, isNot(contains('request')), reason: 'no permission dialog before a choice');

    await tester.enterText(find.byKey(const ValueKey('club-search')), 'kivu');
    await settle(tester);
    expect(find.text('Etoile de Kivu'), findsOneWidget);
    expect(find.text('AC Rangers'), findsNothing);
    await tester.tap(find.text('Etoile de Kivu'));
    await tester.enterText(find.byKey(const ValueKey('club-search')), '');
    await settle(tester);
    await tester.tap(find.text('AS Vita Club'));
    await settle(tester);
    expect(find.text('Continuer (2)'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byKey(const ValueKey('onboarding-alerts'))).value, isTrue);

    await tester.tap(cont);
    await settle(tester);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Suivez vos clubs'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(FavoriteClubs.key)?.toSet(), {'2', '2221'});
    expect(prefs.getString(ClubOnboarding.stateKey), 'done');
    expect(gateway.calls.where((c) => c == 'request').length, 1, reason: 'asked once, after the user chose alerts');
    final saved = await PushStore().loadPrefs();
    expect(saved.matchAlerts && saved.kickoff && saved.result && saved.changes, isTrue);
    expect(saved.goals || saved.prematch, isFalse);
  });

  testWidgets('Plus tard: nothing saved, no permission asked, and not offered again', (tester) async {
    final (repo, _, _) = contractRepository();
    await tester.pumpWidget(shell(repo, home));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('onboarding-later')));
    await settle(tester);
    expect(find.text('Accueil'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ClubOnboarding.stateKey), 'later');
    expect(prefs.getStringList(FavoriteClubs.key), isNull);
    expect(gateway.calls, isEmpty);

    // Next launch.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(shell(repo, home));
    await settle(tester);
    expect(find.text('Suivez vos clubs'), findsNothing);
  });

  testWidgets('alerts left off by the user: the switch starts off and Continuer keeps them off', (tester) async {
    SharedPreferences.setMockInitialValues({
      PushStore.prefsKey: '{"enabled":true,"news":true,"match_alerts":false}',
      PushStore.explicitKey: ['match_alerts'],
    });
    final (repo, _, _) = contractRepository();
    await tester.pumpWidget(shell(repo, home));
    await settle(tester);
    expect(tester.widget<SwitchListTile>(find.byKey(const ValueKey('onboarding-alerts'))).value, isFalse);
    await tester.tap(find.text('AC Rangers'));
    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    await settle(tester);
    expect((await PushStore().loadPrefs()).matchAlerts, isFalse);
    expect(gateway.calls, isNot(contains('request')));
  });

  testWidgets('existing user with followed clubs (upgrade): Home opens normally, never offered', (tester) async {
    SharedPreferences.setMockInitialValues({
      FavoriteClubs.key: ['4'],
    });
    final (repo, _, _) = contractRepository();
    await tester.pumpWidget(shell(repo, home));
    await settle(tester);
    expect(find.text('Suivez vos clubs'), findsNothing);
    expect((await SharedPreferences.getInstance()).getString(ClubOnboarding.stateKey), 'followed');
  });

  testWidgets('offline or API failure: Home opens, the offer waits for a later launch', (tester) async {
    final (repo, adapter, _) = contractRepository();
    adapter.offline = true;
    await tester.pumpWidget(shell(repo, home));
    await settle(tester);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Suivez vos clubs'), findsNothing);
    expect((await SharedPreferences.getInstance()).getString(ClubOnboarding.stateKey), isNull);
  });

  testWidgets('a club followed outside the current season stays listed and can be removed', (tester) async {
    SharedPreferences.setMockInitialValues({
      FavoriteClubs.key: ['4', '99999'],
    });
    final (repo, _, _) = contractRepository();
    await tester.pumpWidget(shell(repo, const FollowClubsScreen()));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Autres clubs suivis'),
      300,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('Hors de la saison en cours'), findsOneWidget);
    await tester.tap(find.text('Hors de la saison en cours'));
    await settle(tester);
    expect((await SharedPreferences.getInstance()).getStringList(FavoriteClubs.key), ['4']);
  });

  for (final (width, scale) in [(320.0, 1.0), (320.0, 2.0), (768.0, 1.3)]) {
    testWidgets('selection fits at $width px with text ×$scale', (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final (repo, _, _) = contractRepository();
      await tester.pumpWidget(shell(repo, const ClubOnboardingScreen(), size: Size(width, 700), scale: scale));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Suivez vos clubs'), findsOneWidget);
    });
  }

}
