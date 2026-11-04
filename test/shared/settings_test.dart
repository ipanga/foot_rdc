import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/more/settings_screens.dart';
import 'package:foot_rdc/shared/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme choices. Notification tests: test/shared/notifications_test.dart.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
}
