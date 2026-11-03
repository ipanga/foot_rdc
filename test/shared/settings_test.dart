import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/more/settings_screens.dart';
import 'package:foot_rdc/shared/providers/notification_provider.dart';
import 'package:foot_rdc/shared/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A device without OneSignal: records what the app asks for.
class FakePush implements PushGateway {
  @override
  bool permission;
  @override
  bool optedIn;
  final bool grantOnRequest;
  final calls = <String>[];
  void Function()? listener;
  FakePush({this.permission = false, this.optedIn = false, this.grantOnRequest = true});

  @override
  Future<bool> requestPermission({required bool fallbackToSettings}) async {
    calls.add(fallbackToSettings ? 'settings' : 'request');
    if (grantOnRequest) permission = true;
    return permission;
  }

  @override
  Future<void> optIn() async {
    calls.add('optIn');
    optedIn = permission;
  }

  @override
  Future<void> optOut() async {
    calls.add('optOut');
    optedIn = false;
  }

  @override
  void onChange(void Function() listener) => this.listener = listener;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Notification preference', () {
    test('starting the app never opts in or out, and the preference is on by default', () async {
      final push = FakePush();
      final notifier = NotificationNotifier(push);
      await notifier.ready;
      expect(push.calls, isEmpty);
      expect(notifier.state.enabled, isTrue);
      expect(notifier.state.receiving, isFalse);
      expect(await NotificationNotifier.mayPromptAtLaunch(), isTrue);
    });

    test('turning off is saved, opts out, survives a restart and stops the launch prompt', () async {
      final push = FakePush(permission: true, optedIn: true);
      final notifier = NotificationNotifier(push);
      await notifier.setEnabled(false);
      expect(push.calls, ['optOut']);
      expect(notifier.state.receiving, isFalse);

      final again = FakePush(permission: true);
      final restarted = NotificationNotifier(again);
      await restarted.ready;
      expect(restarted.state.enabled, isFalse);
      expect(again.calls, isEmpty, reason: 'restart repeats nothing');
      expect(await NotificationNotifier.mayPromptAtLaunch(), isFalse);
    });

    test('turning on without permission asks the system once, then opts in', () async {
      final push = FakePush();
      final notifier = NotificationNotifier(push);
      await notifier.setEnabled(true);
      expect(push.calls, ['request', 'optIn']);
      expect(notifier.state.receiving, isTrue);
    });

    test('a refusal is shown as blocked by the device, and only the settings button asks for settings', () async {
      final push = FakePush(grantOnRequest: false);
      final notifier = NotificationNotifier(push);
      await notifier.setEnabled(true);
      expect(notifier.state.blockedByDevice, isTrue);
      expect(push.calls, isNot(contains('settings')));
      await notifier.openDeviceSettings();
      expect(push.calls.last, 'settings');
    });

    test('a permission granted in the system settings shows up when OneSignal reports it', () async {
      final push = FakePush(grantOnRequest: false);
      final notifier = NotificationNotifier(push);
      await notifier.setEnabled(true);
      push
        ..permission = true
        ..optedIn = true;
      push.listener!();
      expect(notifier.state.receiving, isTrue);
    });
  });

  group('Theme', () {
    test('the choice is saved and restored after a restart', () async {
      final notifier = ThemeNotifierCustom();
      await notifier.setTheme(ThemeModeCustom.dark);
      final restarted = ThemeNotifierCustom();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(restarted.state, ThemeModeCustom.dark);
    });

    testWidgets('automatic follows the device brightness', (tester) async {
      late ThemeMode mode;
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              ref.watch(themeCustomNotifierProvider);
              mode = ref.read(themeCustomNotifierProvider.notifier).getFlutterThemeMode(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(mode, ThemeMode.system);
    });

    testWidgets('the Thème screen shows three choices and marks the selected one', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ThemeSettingsScreen())));
      await tester.pumpAndSettle();
      expect(find.text('Automatique'), findsOneWidget);
      expect(find.text('Clair'), findsOneWidget);
      expect(find.text('Sombre'), findsOneWidget);
      await tester.tap(find.text('Sombre'));
      await tester.pumpAndSettle();
      expect(tester.widget<ListTile>(find.byKey(const ValueKey('theme-dark'))).selected, isTrue);
      expect((await SharedPreferences.getInstance()).getString('theme_mode'), 'ThemeModeCustom.dark');
    });
  });

  testWidgets('the Notifications screen separates the app preference from the device permission', (tester) async {
    final push = FakePush(grantOnRequest: false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [notificationNotifierProvider.overrideWith((ref) => NotificationNotifier(push))],
        child: const MaterialApp(home: NotificationSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Préférence FootRDC'), findsOneWidget);
    expect(find.text('Autorisation de l’appareil'), findsOneWidget);
    expect(find.text('Ouvrir les réglages de l’appareil'), findsOneWidget, reason: 'on by default, permission missing');
    await tester.tap(find.byKey(const ValueKey('notifications-switch')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Désactivées dans FootRDC'), findsOneWidget);
    expect(find.text('Ouvrir les réglages de l’appareil'), findsNothing);
    expect(push.calls, ['optOut']);
  });
}
