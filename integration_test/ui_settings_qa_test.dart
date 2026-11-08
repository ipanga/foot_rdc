import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:integration_test/integration_test.dart';

import 'qa_support.dart';

/// Home without drawer, Plus › Thème and Plus › Notifications on a device. Restores the automatic theme at the end.
/// The notification switch is exercised by widget tests: on a device it would change the real push subscription.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('home bar and settings', (tester) async {
    final qa = Qa(tester, binding, 'settings');
    await qa.launch();
    await qa.wait(find.byType(ArticleListItem));
    expect(find.byType(Drawer), findsNothing);
    expect(find.byTooltip('Rechercher'), findsOneWidget);
    expect(find.bySemanticsLabel('FootRDC'), findsWidgets);
    await qa.shot('accueil-barre');

    await qa.nav('Plus');
    await qa.wait(find.text('Thème'));
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('À propos'), findsOneWidget);
    await qa.shot('plus');

    await tester.tap(find.text('Thème'));
    await qa.wait(find.text('Automatique'));
    await qa.shot('theme');
    await tester.tap(find.text('Sombre'));
    await qa.pumpFor(const Duration(seconds: 1));
    await qa.shot('theme-sombre');
    await qa.back();
    await qa.nav('Accueil');
    await qa.pumpFor(const Duration(seconds: 2));
    await qa.shot('accueil-sombre');

    await qa.nav('Plus');
    await tester.tap(find.text('Notifications'));
    await qa.wait(find.text('Articles à la Une'));
    await qa.shot('notifications-sombre');
    await qa.back();

    await tester.tap(find.text('À propos'));
    await qa.pumpFor(const Duration(seconds: 1));
    await qa.shot('a-propos');
    await tester.tap(find.byType(TextButton).last); // "Fermer"
    await qa.pumpFor(const Duration(milliseconds: 600));

    await tester.tap(find.text('Thème'));
    await qa.wait(find.text('Automatique'));
    await tester.tap(find.text('Automatique'));
    await qa.pumpFor(const Duration(seconds: 1));
    await qa.back();
    await tester.tap(find.text('Notifications'));
    await qa.wait(find.text('Articles à la Une'));
    await qa.shot('notifications');
    await qa.back();
  });
}
