import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'qa_support.dart';

/// iOS update suggestion against the real public App Store lookup. Run with
/// `QA_FLUTTER_ARGS=--dart-define=APP_UPDATE_INSTALLED=1.0.0` so today's public version (1.1.3) counts as newer.
/// Shows the line on Accueil only, then « Plus tard » hides it and remembers the choice. Cleans its keys at the end.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('update suggestion: shown on Accueil, « Plus tard » remembered', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    Future<void> clear() async {
      for (final k in prefs.getKeys().where((k) => k.startsWith('app_update_')).toList()) {
        await prefs.remove(k);
      }
    }

    await clear();
    final qa = Qa(tester, binding, 'update');
    await qa.launch();
    await qa.wait(find.byType(ArticleListItem), seconds: 60);
    await qa.wait(find.byKey(const ValueKey('app-update-banner')), seconds: 20);
    await qa.shot('suggestion-accueil');

    await qa.nav('Matchs');
    await qa.pumpFor(const Duration(seconds: 2));
    // ignore: avoid_print
    print('QA-UPDATE on-matchs=${find.byKey(const ValueKey('app-update-banner')).evaluate().length}');
    await qa.shot('pas-sur-matchs');
    await qa.nav('Accueil');
    await qa.pumpFor(const Duration(seconds: 1));

    await tester.tap(find.text('Plus tard'));
    await qa.pumpFor(const Duration(seconds: 1));
    // ignore: avoid_print
    print('QA-UPDATE after-later=${find.byKey(const ValueKey('app-update-banner')).evaluate().length} '
        'remembered=${prefs.getString('app_update_dismissed_version')}');
    await qa.shot('apres-plus-tard');
    await clear();
  });
}
