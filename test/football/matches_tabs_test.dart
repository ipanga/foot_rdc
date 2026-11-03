import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/football/presentation/screens/matches_screen.dart';
import 'package:foot_rdc/features/football/presentation/widgets/football_widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

/// The Matchs tab labels stay whole on a 320 px screen with large text.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    ClubCrest.loadImages = false;
    await initializeDateFormatting('fr');
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('labels fit their tab at $width px and 1.3× text', (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final (repo, _, _) = contractRepository();
      await tester.pumpWidget(app(const MatchesScreen(), repo, scale: 1.3, size: Size(width, 700)));
      await settle(tester);
      for (final label in ["Aujourd'hui", 'Calendrier', 'Résultats']) {
        final text = tester.renderObject<RenderBox>(find.text(label));
        final tab = tester.renderObject<RenderBox>(find.ancestor(of: find.text(label), matching: find.byType(Tab)));
        final shown = text.localToGlobal(Offset.zero) & (text.size * _scale(tester, label));
        final slot = tab.localToGlobal(Offset.zero) & tab.size;
        expect(shown.right, lessThanOrEqualTo(slot.right + 0.5), reason: '$label fits');
        expect(shown.left, greaterThanOrEqualTo(slot.left - 0.5), reason: '$label fits');
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await settle(tester);
    });
  }
}

/// The scale a FittedBox applied to the label (1 when it fits as is).
double _scale(WidgetTester tester, String label) {
  final fitted = find.ancestor(of: find.text(label), matching: find.byType(FittedBox));
  final box = tester.renderObject<RenderBox>(fitted);
  final child = tester.renderObject<RenderBox>(find.text(label));
  return child.size.width == 0 ? 1 : (box.size.width / child.size.width).clamp(0, 1).toDouble();
}
