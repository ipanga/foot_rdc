import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/utils/date_utils.dart';

/// Article dates in French, in the device's time zone.
void main() {
  // Local times, so the result does not depend on the machine's zone.
  final now = DateTime(2026, 11, 3, 18);
  String at(DateTime local) => formatArticleDate(local.toUtc(), now: now);

  test('today shows the time', () => expect(at(DateTime(2026, 11, 3, 9, 5)), '09:05'));
  test('yesterday', () => expect(at(DateTime(2026, 11, 2, 23, 59)), 'Hier'));
  test('this year: day and French month', () {
    expect(at(DateTime(2026, 11, 1, 10)), '1 nov.');
    expect(at(DateTime(2026, 2, 14, 10)), '14 févr.');
    expect(at(DateTime(2026, 8, 3, 10)), '3 août');
  });
  test('an earlier year adds the year', () => expect(at(DateTime(2025, 12, 31, 10)), '31 déc. 2025'));
}
