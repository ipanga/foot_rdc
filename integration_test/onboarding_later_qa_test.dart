import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/football/presentation/widgets/club_picker.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'qa_support.dart';

/// Fresh install, « Plus tard »: Home opens, nothing is followed and the answer is remembered. Read-only.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('club onboarding: later', (tester) async {
    final qa = Qa(tester, binding, 'onboarding-later');
    await qa.launch(clubOnboarding: true, resetClubs: true);
    await qa.wait(find.byType(ClubChoiceTile), seconds: 60);
    await tester.tap(find.byKey(const ValueKey('onboarding-later')));
    await qa.gone(find.text('Suivez vos clubs'));
    await qa.wait(find.byType(ArticleListItem), seconds: 60);
    await qa.shot('accueil');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('rdcf_club_onboarding'), 'later');
    expect(prefs.getStringList('rdcf_favorite_clubs'), isNull);
  });
}
