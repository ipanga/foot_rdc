import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/navigation/deep_link_handler.dart';
import 'package:foot_rdc/core/notifications/push.dart';
import 'package:foot_rdc/core/notifications/push_messages.dart';
import 'package:foot_rdc/features/more/settings_screens.dart';
import 'package:foot_rdc/shared/providers/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A device without Firebase: records what the app asks for.
class FakeGateway implements PushGateway {
  PushPermission perm;
  final PushPermission onRequest;
  String? tok;
  final refresh = StreamController<String>.broadcast();
  final calls = <String>[];
  FakeGateway({this.perm = PushPermission.granted, this.onRequest = PushPermission.granted, this.tok = 'tok-1'});

  @override
  Future<PushPermission> permission() async => perm;
  @override
  Future<PushPermission> requestPermission() async {
    calls.add('request');
    return perm = onRequest;
  }

  @override
  Future<String?> token() async => tok;
  @override
  Stream<String> get tokenRefresh => refresh.stream;
  @override
  Future<void> openSettings() async => calls.add('settings');
  @override
  Future<void> leaveOneSignal() async => calls.add('leave-onesignal');
  @override
  Future<void> setOneSignal(bool enabled) async => calls.add('onesignal-$enabled');
  @override
  String get platform => 'android';
}

/// The FootRDC server: records registrations.
class FakeBackend extends PushBackend {
  final bodies = <Map<String, dynamic>>[];
  final secrets = <String>[];
  bool offline = false;
  PushConfig cfg = const PushConfig(enabled: true);

  @override
  Future<String?> register(Map<String, dynamic> body, String secret) async {
    if (offline) throw Exception('offline');
    bodies.add(body);
    secrets.add(secret);
    return 'AB12CD34';
  }

  @override
  Future<PushConfig> config() async {
    if (offline) throw Exception('offline');
    return cfg;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<(NotificationNotifier, FakeGateway, FakeBackend)> start({
    FakeGateway? gateway,
    FakeBackend? backend,
    Set<int> clubs = const {},
  }) async {
    final g = gateway ?? FakeGateway();
    final b = backend ?? FakeBackend();
    final n = NotificationNotifier(g, b, PushStore(), debounce: Duration.zero, appVersion: () async => '5.12.11 (35)');
    n.followsChanged(clubs);
    await n.ready;
    await n.sync();
    return (n, g, b);
  }

  group('Registration', () {
    test('first start registers an installation, without an account and without touching OneSignal', () async {
      final (n, g, b) = await start();
      final body = b.bodies.last;
      expect(
        body['install_id'],
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
      );
      expect(b.secrets.last.length, greaterThanOrEqualTo(43));
      expect(body.containsKey('secret'), isFalse, reason: 'the secret travels in a header only');
      expect(body['token'], 'tok-1');
      expect(body['prefs'], containsPair('news', true));
      expect(body['follows'], isEmpty, reason: 'no match alerts until the user turns them on');
      expect(g.calls.where((c) => c.startsWith('onesignal') || c == 'leave-onesignal'), isEmpty);
      expect(n.state.code, 'AB12CD34');
      expect(n.state.registered && n.state.hasToken, isTrue);
    });

    test('the installation survives restarts; token refreshes update the same installation', () async {
      final (n, g, b) = await start();
      final id = b.bodies.last['install_id'];
      final secret = b.secrets.last;
      g.tok = 'tok-2';
      g.refresh.add('tok-2');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await n.sync();
      expect(b.bodies.last['install_id'], id);
      expect(b.bodies.last['token'], 'tok-2');
      n.dispose();
      final (_, _, b2) = await start();
      expect(b2.bodies.last['install_id'], id);
      expect(b2.secrets.last, secret);
    });

    test('without permission no token is sent, and the screen state says the device refuses', () async {
      final (n, _, b) = await start(
        gateway: FakeGateway(perm: PushPermission.denied, onRequest: PushPermission.denied),
      );
      expect(b.bodies.last.containsKey('token'), isFalse);
      expect(n.state.blockedByDevice, isTrue);
    });

    test('offline: choices are kept on the device and the failure is visible; the next sync sends them', () async {
      final backend = FakeBackend()..offline = true;
      final (n, _, b) = await start(backend: backend);
      expect(n.state.syncFailed, isTrue);
      await n.setPrefs(n.state.prefs.copyWith(news: false));
      backend.offline = false;
      await n.sync();
      expect(n.state.syncFailed, isFalse);
      expect(b.bodies.last['prefs']['news'], false);
      n.dispose();
      final (n2, _, _) = await start();
      expect(n2.state.prefs.news, isFalse, reason: 'persisted across restarts');
    });
  });

  group('Preferences', () {
    test('followed clubs get only the chosen alerts, and none while match alerts are off', () async {
      final (n, _, b) = await start(clubs: {4, 7});
      expect(b.bodies.last['follows'], isEmpty);
      await n.setPrefs(n.state.prefs.copyWith(matchAlerts: true));
      await n.sync();
      final follows = (b.bodies.last['follows'] as List).cast<Map<String, dynamic>>();
      expect(follows.map((f) => f['team_id']).toSet(), {4, 7});
      expect(follows.first, containsPair('result', 1));
      expect(follows.first, containsPair('changes', 1));
      expect(follows.first, containsPair('goals', 0), reason: 'goals stay off unless chosen');
      n.followsChanged({4});
      await n.sync();
      expect((b.bodies.last['follows'] as List).length, 1, reason: 'unfollowing a club stops its alerts');
    });

    test('turning everything off is saved as the user\'s choice and honoured by OneSignal during the transition', () async {
      final (n, g, b) = await start();
      await n.setEnabled(false);
      await n.sync();
      expect(g.calls, contains('onesignal-false'));
      expect(b.bodies.last['prefs']['enabled'], false);
      n.dispose();
      final (n2, _, _) = await start();
      expect(n2.state.prefs.enabled, isFalse, reason: 'kept across restarts');
    });

    test('turning notifications on asks for the permission when it was never asked', () async {
      final g = FakeGateway(perm: PushPermission.notDetermined);
      final (n, _, _) = await start(gateway: g);
      await n.setEnabled(false);
      await n.setEnabled(true);
      expect(g.calls, contains('request'));
      expect(n.state.hasPermission, isTrue);
    });

    test('quiet hours are sent in UTC, so the server needs no time-zone database', () async {
      final (n, _, b) = await start();
      await n.setPrefs(n.state.prefs.copyWith(quietStart: () => 22 * 60, quietEnd: () => 7 * 60));
      await n.sync();
      final offset = DateTime.now().timeZoneOffset.inMinutes;
      expect(b.bodies.last['prefs']['quiet_start'], (22 * 60 - offset) % 1440);
      expect(b.bodies.last['prefs']['quiet_end'], (7 * 60 - offset) % 1440);
      expect(b.bodies.last['timezone'], 'UTC');
    });

    test('when the server takes over, the app leaves OneSignal once and no longer drives it', () async {
      final backend = FakeBackend()..cfg = const PushConfig(enabled: true, leaveOneSignal: true);
      final (n, g, _) = await start(backend: backend);
      expect(g.calls.where((c) => c == 'leave-onesignal').length, 1);
      await n.sync();
      await n.setEnabled(false);
      expect(g.calls.where((c) => c == 'leave-onesignal').length, 1);
      expect(g.calls, isNot(contains('onesignal-false')));
    });
  });

  group('Defaults and explicit choices (6 Nov 2026)', () {
    test('new installation: kickoff, result and changes on; goals and reminder off; club alerts off until chosen', () {
      const p = NotificationPrefs();
      expect([p.kickoff, p.result, p.changes, p.goals, p.prematch, p.matchAlerts, p.news], [
        true,
        true,
        true,
        false,
        false,
        false,
        true,
      ]);
      expect(p.clubFlags().values.every((v) => v == 0), isTrue, reason: 'nothing for clubs until alerts are on');
      expect(p.copyWith(matchAlerts: true).clubFlags(), {
        'prematch': 0,
        'kickoff': 1,
        'goals': 0,
        'result': 1,
        'changes': 1,
      });
    });

    test('preferences saved by 5.12.11 (34) are all kept: a disabled alert is never re-enabled', () async {
      SharedPreferences.setMockInitialValues({
        PushStore.prefsKey: '{"enabled":true,"news":true,"match_alerts":true,"prematch":false,"kickoff":false,'
            '"goals":false,"result":true,"changes":true,"quiet_start":null,"quiet_end":null}',
      });
      final p = await PushStore().loadPrefs();
      expect(p.kickoff, isFalse);
      expect(p.matchAlerts, isTrue);
    });

    test('only explicit choices are kept; untouched settings follow the current defaults', () async {
      SharedPreferences.setMockInitialValues({
        PushStore.prefsKey: '{"enabled":true,"news":false,"kickoff":false,"goals":true}',
        PushStore.explicitKey: ['goals', 'news'],
      });
      final p = await PushStore().loadPrefs();
      expect(p.news, isFalse);
      expect(p.goals, isTrue);
      expect(p.kickoff, isTrue, reason: 'kickoff was never chosen: the current default applies');
    });

    test('a change records only the keys the user changed', () async {
      final (n, _, _) = await start();
      await n.setPrefs(n.state.prefs.copyWith(goals: true));
      final p = await SharedPreferences.getInstance();
      expect(p.getStringList(PushStore.explicitKey), ['goals']);
    });

    test('notifications turned off with the OneSignal-era switch stay off after a later change', () async {
      SharedPreferences.setMockInitialValues({PushStore.legacyEnabledKey: false});
      final (n, _, _) = await start();
      expect(n.state.prefs.enabled, isFalse);
      await n.setPrefs(n.state.prefs.copyWith(news: false));
      n.dispose();
      final (n2, _, _) = await start();
      expect(n2.state.prefs.enabled, isFalse);
    });
  });

  group('Permission and registration (6 Nov 2026)', () {
    test('the registration carries the app version and the device permission', () async {
      final (_, _, b) = await start();
      expect(b.bodies.last['app_version'], '5.12.11 (35)');
      expect(b.bodies.last['permission'], 'granted');
    });

    test('a refusal in the system settings reaches the server as « disabled » when the app resumes', () async {
      final (n, g, b) = await start();
      expect(b.bodies.last['prefs']['enabled'], isTrue);
      g.perm = PushPermission.denied;
      await n.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await n.sync();
      expect(b.bodies.last['prefs']['enabled'], isFalse);
      expect(b.bodies.last['permission'], 'denied');
      expect(b.bodies.last.containsKey('token'), isFalse);
      expect(n.state.prefs.enabled, isTrue, reason: 'the user\'s own switch is untouched');
      g.perm = PushPermission.granted;
      await n.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await n.sync();
      expect(b.bodies.last['prefs']['enabled'], isTrue);
      expect(b.bodies.last['token'], 'tok-1');
    });

    test('nothing asks for the permission at start; turning on club alerts asks once, in context', () async {
      final g = FakeGateway(perm: PushPermission.notDetermined);
      final (n, _, _) = await start(gateway: g);
      expect(g.calls, isNot(contains('request')));
      await n.setPrefs(n.state.prefs.copyWith(goals: true));
      expect(g.calls, isNot(contains('request')), reason: 'a sub-setting is not a reason to ask');
      final permission = await n.enableClubAlerts();
      expect(g.calls.where((c) => c == 'request').length, 1);
      expect(permission, PushPermission.granted);
      expect(n.state.prefs.matchAlerts && n.state.prefs.enabled, isTrue);
    });

    test('club alerts from the club selection keep the user\'s earlier per-type choices', () async {
      final (n, _, _) = await start();
      await n.setPrefs(n.state.prefs.copyWith(kickoff: false));
      await n.enableClubAlerts();
      expect(n.state.prefs.kickoff, isFalse);
      expect(n.state.prefs.result, isTrue);
    });
  });

  group('Messages', () {
    RemoteMessage msg(String link) => RemoteMessage(
      data: {'link': link},
      notification: const RemoteNotification(title: 'FootRDC — À la Une', body: 'Un titre'),
    );

    testWidgets('an open article or match is marked as on screen, and released when it closes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ContentLinkScope(link: 'footrdc://match/7', child: SizedBox()),
        ),
      );
      expect(currentContentLink.value, 'footrdc://match/7');
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(currentContentLink.value, isNull);
    });

    test('only FootRDC links are followed', () {
      expect(pushLink(msg('footrdc://article/12')), 'footrdc://article/12');
      expect(pushLink(msg('https://evil.example/')), isNull);
    });

    testWidgets('a foreground notification shows an in-app banner, not when the same content is open', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: appMessengerKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      final release = showingContent('footrdc://article/12');
      showForegroundNotification(msg('footrdc://article/12'));
      await tester.pump();
      expect(find.byKey(const ValueKey('push-banner')), findsNothing);
      release();
      final opened = <String>[];
      final sub = pushLinks.stream.listen(opened.add);
      addTearDown(sub.cancel);
      showForegroundNotification(msg('footrdc://article/12'));
      await tester.pumpAndSettle();
      expect(find.text('FootRDC — À la Une'), findsOneWidget);
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(opened, ['footrdc://article/12']);
    });

    testWidgets('no banner while notifications are refused or switched off, nor for a late message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: appMessengerKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      addTearDown(() => inAppBannersAllowed.value = true);
      inAppBannersAllowed.value = false;
      showForegroundNotification(msg('footrdc://article/1'));
      await tester.pump();
      expect(find.byKey(const ValueKey('push-banner')), findsNothing);

      inAppBannersAllowed.value = true;
      final now = DateTime(2026, 11, 6, 12);
      RemoteMessage at(DateTime sent) => RemoteMessage(
        data: const {'link': 'footrdc://article/2'},
        sentTime: sent,
        notification: const RemoteNotification(title: 'FootRDC — test', body: 'x'),
      );
      showForegroundNotification(at(now.subtract(const Duration(minutes: 3))), now: now);
      await tester.pump();
      expect(find.byKey(const ValueKey('push-banner')), findsNothing, reason: 'delivered 3 minutes late');
      showForegroundNotification(at(now.subtract(const Duration(seconds: 5))), now: now);
      await tester.pump();
      expect(find.byKey(const ValueKey('push-banner')), findsOneWidget);
    });

    test('the in-app banner switch follows the device state', () async {
      final g = FakeGateway(perm: PushPermission.granted);
      final (n, _, _) = await start(gateway: g);
      expect(inAppBannersAllowed.value, isTrue);
      g.perm = PushPermission.denied;
      await n.refresh();
      expect(inAppBannersAllowed.value, isFalse);
      await n.setEnabled(false);
      g.perm = PushPermission.granted;
      await n.refresh();
      expect(inAppBannersAllowed.value, isFalse, reason: 'switched off by the user');
      await n.setEnabled(true);
      expect(inAppBannersAllowed.value, isTrue);
    });
  });

  group('Plus › Notifications', () {
    Future<FakeGateway> pump(
      WidgetTester tester, {
      double width = 390,
      double scale = 1,
      PushPermission perm = PushPermission.granted,
    }) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final g = FakeGateway(perm: perm, onRequest: perm);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationNotifierProvider.overrideWith(
              (ref) => NotificationNotifier(
                g,
                FakeBackend(),
                PushStore(),
                debounce: Duration.zero,
                appVersion: () async => '5.12.11 (35)',
              ),
            ),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const NotificationSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return g;
    }

    testWidgets('three sections in French, and match alert types wait for « Alertes de mes clubs »', (tester) async {
      await pump(tester);
      for (final t in ['Actualités', 'Matchs Linafoot', 'Articles à la Une', 'Alertes de mes clubs', 'Clubs suivis']) {
        expect(find.text(t), findsOneWidget);
      }
      SwitchListTile s(String key) =>
          tester.widget<SwitchListTile>(find.byKey(ValueKey('notif-$key'), skipOffstage: false));
      expect(s('result').onChanged, isNull);
      await tester.tap(find.byKey(const ValueKey('notif-match')));
      await tester.pumpAndSettle();
      expect(s('result').onChanged, isNotNull);
      expect(s('result').value, isTrue, reason: 'final results on by default once club alerts are on');
      expect(s('goals').value, isFalse);
      await tester.scrollUntilVisible(find.text('Autorisation de l’appareil'), 200);
      expect(find.text('Général'), findsOneWidget);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('notif-diagnostic')), 200);
      expect(find.text('Code de l’appareil : AB12CD34'), findsOneWidget);
    });

    testWidgets('permission refused: the status says so and offers the device settings', (tester) async {
      final g = await pump(tester, perm: PushPermission.denied);
      expect(find.textContaining('Non autorisées par l’appareil'), findsOneWidget);
      await tester.tap(find.text('Autoriser les notifications'));
      await tester.pumpAndSettle();
      expect(g.calls, containsAllInOrder(['request', 'settings']), reason: 'ask the system first, then the settings');
    });

    testWidgets('the master switch disables every choice', (tester) async {
      await pump(tester);
      await tester.scrollUntilVisible(find.byKey(const ValueKey('notif-all')), 200);
      await tester.tap(find.byKey(const ValueKey('notif-all')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(const ValueKey('notif-news')), -200);
      expect(
        tester.widget<SwitchListTile>(find.byKey(const ValueKey('notif-news'), skipOffstage: false)).onChanged,
        isNull,
      );
      expect(find.textContaining('sont désactivées', skipOffstage: false), findsOneWidget);
    });

    for (final (width, scale) in [(320.0, 1.0), (320.0, 2.0), (768.0, 1.3)]) {
      testWidgets('fits at $width px with text ×$scale', (tester) async {
        await pump(tester, width: width, scale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
