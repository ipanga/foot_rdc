import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:integration_test/integration_test.dart';

import 'qa_support.dart';

/// Before/after screens of the 6 Nov refinements: home header and tabs, an article's category, Plus › Notifications
/// and Clubs suivis, in light then dark theme (Plus › Thème, restored to Automatique at the end). Read-only.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('header, tabs, category, notification screens', (tester) async {
    final qa = Qa(tester, binding, 'redesign');
    await qa.launch();
    await qa.wait(find.byType(ArticleListItem), seconds: 60);

    for (final dark in [false, true]) {
      final mode = dark ? 'sombre' : 'clair';
      if (dark) {
        await qa.nav('Plus');
        await tester.tap(find.text('Thème'));
        await qa.wait(find.text('Sombre'));
        await tester.tap(find.text('Sombre'));
        await qa.pumpFor(const Duration(seconds: 1));
        await qa.back();
        await qa.nav('Accueil');
        await qa.pumpFor(const Duration(seconds: 2));
      }
      await qa.shot('accueil-$mode');

      await tester.tap(find.byType(ArticleListItem).first);
      await qa.wait(find.byType(ArticleDetailScreen));
      await qa.pumpFor(const Duration(seconds: 3));
      await qa.shot('article-$mode');
      await qa.back();

      await qa.nav('Matchs');
      await qa.pumpFor(const Duration(seconds: 2));
      await qa.shot('onglet-matchs-$mode');

      await qa.nav('Plus');
      await qa.wait(find.text('Notifications'));
      await qa.shot('plus-$mode');
      await tester.tap(find.text('Notifications'));
      await qa.wait(find.text('Articles à la Une'));
      await qa.shot('notifications-$mode');
      await tester.tap(find.text('Clubs suivis'));
      await qa.pumpFor(const Duration(seconds: 4));
      await qa.shot('clubs-suivis-$mode');
      await qa.back();
      await qa.back();
      await qa.nav('Accueil');
      await qa.pumpFor(const Duration(seconds: 1));
    }

    await qa.nav('Plus');
    await tester.tap(find.text('Thème'));
    await qa.wait(find.text('Automatique'));
    await tester.tap(find.text('Automatique'));
    await qa.pumpFor(const Duration(seconds: 1));
    await qa.back();
  });
}
