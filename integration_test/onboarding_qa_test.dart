import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/football/presentation/widgets/club_picker.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:integration_test/integration_test.dart';

import 'qa_support.dart';

/// First-launch club selection on a device, against the real season's clubs (read-only):
/// fresh install → offered → search → choose 3 → Continuer → Home; Plus › Clubs suivis lists them; remove one;
/// « Modifier » adds it back. « Plus tard » is onboarding_later_qa_test; real restarts are checked with adb.
/// « Alertes de match » is turned off here: with it on, the system permission dialog opens, which this harness cannot
/// answer; that path is checked by hand with adb (see TEST_MATRIX.md) and by widget tests.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('club onboarding', (tester) async {
    final qa = Qa(tester, binding, 'onboarding');
    await qa.launch(clubOnboarding: true, resetClubs: true);
    await qa.wait(find.text('Suivez vos clubs'), seconds: 60);
    await qa.wait(find.byType(ClubChoiceTile));
    await qa.shot('propose');

    await tester.enterText(find.byKey(const ValueKey('club-search')), 'vita');
    await qa.pumpFor(const Duration(seconds: 1));
    await qa.shot('recherche');
    await tester.tap(find.text('AS Vita Club'));
    await tester.enterText(find.byKey(const ValueKey('club-search')), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await qa.pumpFor(const Duration(seconds: 1));
    await tester.tap(find.byType(ClubChoiceTile).at(0));
    await tester.tap(find.byType(ClubChoiceTile).at(2));
    await qa.pumpFor(const Duration(milliseconds: 600));
    expect(find.text('Continuer (3)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-alerts')));
    await qa.pumpFor(const Duration(milliseconds: 400));
    await qa.shot('trois-clubs');
    await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
    await qa.gone(find.text('Suivez vos clubs'));
    await qa.wait(find.byType(ArticleListItem), seconds: 60);
    await qa.shot('accueil-apres');

    await qa.nav('Plus');
    await qa.wait(find.text('3 clubs'));
    await tester.tap(find.text('Clubs suivis'));
    await qa.wait(find.text('AS Vita Club'));
    await qa.shot('clubs-suivis');
    await tester.tap(find.byTooltip('Ne plus suivre AS Vita Club'));
    await qa.pumpFor(const Duration(seconds: 1));
    expect(find.text('AS Vita Club'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('followed-edit')));
    await qa.wait(find.byType(ClubChoiceTile));
    await tester.enterText(find.byKey(const ValueKey('club-search')), 'vita');
    await qa.pumpFor(const Duration(seconds: 1));
    await tester.tap(find.text('AS Vita Club'));
    await qa.pumpFor(const Duration(milliseconds: 600));
    await qa.shot('modifier');
    await qa.back();
    await qa.wait(find.text('AS Vita Club'));
    await qa.back();
    await qa.wait(find.text('3 clubs'));

    await tester.tap(find.text('Notifications'));
    await qa.wait(find.text('Articles à la Une'));
    await qa.shot('notifications');
    await qa.back();
    await qa.nav('Accueil');
  });
}
