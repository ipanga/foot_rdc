import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/theme/app_theme.dart';
import 'package:foot_rdc/features/home/presentation/app_tabs.dart';
import 'package:foot_rdc/shared/widgets/premium_bottom_nav_bar.dart';

/// Bottom tabs: order, screen reader, contrast and fit on small screens with large text.
void main() {
  void small(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget bar({required int index, required ThemeData theme, double scale = 1, ValueChanged<int>? onTap}) => MaterialApp(
    theme: theme,
    home: MediaQuery(
      data: MediaQueryData(size: const Size(320, 640), textScaler: TextScaler.linear(scale)),
      child: Scaffold(
        bottomNavigationBar: PremiumBottomNavBar(
          currentIndex: index,
          onTap: onTap ?? (_) {},
          items: [for (final tab in AppTab.values) appTabNavItem(tab)],
          enableHaptics: false,
        ),
      ),
    ),
  );

  test('final order: Accueil, Édito, Matchs, Classement, Plus', () {
    expect(AppTab.values.map((t) => t.label), ['Accueil', 'Édito', 'Matchs', 'Classement', 'Plus']);
  });

  testWidgets('each tab is a button, the current one announced as selected', (tester) async {
    small(tester);
    final handle = tester.ensureSemantics();
    final taps = <int>[];
    await tester.pumpWidget(bar(index: 3, theme: AppTheme.lightTheme, onTap: taps.add));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Classement')),
      matchesSemantics(
        label: 'Classement',
        hint: 'Onglet 4 sur 5',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Matchs')),
      matchesSemantics(
        label: 'Matchs',
        hint: 'Onglet 3 sur 5',
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.text('Matchs'));
    expect(taps, [2]);
    handle.dispose();
  });

  for (final dark in [false, true]) {
    testWidgets('labels meet 4.5:1 contrast and fit at 320 px with 2× text (dark $dark)', (tester) async {
      small(tester);
      final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
      await tester.pumpWidget(bar(index: 0, theme: theme, scale: 2));
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }

  testWidgets('selected tab: no filled shape behind the icon, one short red rule, bold red label', (tester) async {
    small(tester);
    await tester.pumpWidget(bar(index: 2, theme: AppTheme.lightTheme));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-indicator')), findsOneWidget);
    final filled = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.decoration is BoxDecoration && (c.decoration as BoxDecoration).color != null)
        .where((c) => c.constraints?.maxHeight != 3); // the rule (0 wide on the other tabs)
    expect(filled, isEmpty, reason: 'the pill background is gone');
    final label = tester.widget<Text>(find.text('Matchs'));
    expect(label.style?.fontWeight, FontWeight.w700);
    expect(tester.widget<Text>(find.text('Accueil')).style?.fontWeight, FontWeight.w500);
  });
}
