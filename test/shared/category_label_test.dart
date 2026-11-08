import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_theme.dart';
import 'package:foot_rdc/core/utils/string_utils.dart';
import 'package:foot_rdc/shared/widgets/category_label.dart';

/// Article categories are a small-capitals kicker without a box, in the same colour as the publication date beside it.
void main() {
  test('the home category reads « À la Une »', () {
    expect(formatCategory('a-la-une'), 'À la Une');
    expect(formatCategory('category-rdc'), 'Rdc');
    expect(formatCategory('internationale'), 'Internationale');
  });

  for (final dark in [false, true]) {
    testWidgets('no box, the date colour, 4.5:1 contrast (dark $dark)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: const Scaffold(body: Center(child: CategoryLabel('À la Une', fontSize: 12))),
        ),
      );
      expect(find.text('À LA UNE'), findsOneWidget);
      expect(
        find.ancestor(of: find.text('À LA UNE'), matching: find.byType(DecoratedBox)),
        findsNothing,
      );
      expect(
        tester.widget<Text>(find.text('À LA UNE')).style?.color,
        dark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
      );
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  }
}
