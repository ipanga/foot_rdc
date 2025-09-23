import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/utils/date_utils.dart';

void main() {
  test('formatArticleDate returns HH:mm for same-day GMT input', () {
    final now = DateTime.now();
    // Use the UTC equivalent of now so the util, which expects GMT, will
    // convert it back to local and produce a same-day time string.
    final gmt = now.toUtc();
    final formatted = formatArticleDate(gmt);
    // Expect pattern like 09:05
    expect(RegExp(r'^\d{2}:\d{2}$').hasMatch(formatted), isTrue);
  });

  test('formatArticleDate returns dd-MMM-yy for older dates', () {
    final older = DateTime.utc(2020, 1, 5, 12, 0);
    final formatted = formatArticleDate(older);
    // Expect pattern like 05-Jan-20
    expect(RegExp(r'^\d{2}-[A-Za-z]{3}-\d{2}$').hasMatch(formatted), isTrue);
  });
}
