import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/features/app_update/app_update.dart';
import 'package:foot_rdc/shared/widgets/auto_hide_bottom_bar.dart';

/// Scroll-aware tab bar: hides when reading further, returns when going back up, ignores tremors, stays at the
/// edges and on short content; slides without moving the page; instant with reduced motion; kept for screen readers.
void main() {
  ScrollUpdateNotification update(double pixels, double delta, {double max = 3000, Axis axis = Axis.vertical}) =>
      ScrollUpdateNotification(
        metrics: FixedScrollMetrics(
          minScrollExtent: 0,
          maxScrollExtent: max,
          pixels: pixels,
          viewportDimension: 700,
          axisDirection: axis == Axis.vertical ? AxisDirection.down : AxisDirection.right,
          devicePixelRatio: 3,
        ),
        context: _FakeContext(),
        scrollDelta: delta,
      );

  group('BottomBarVisibility', () {
    test('reading further hides, going back up shows', () {
      final v = BottomBarVisibility();
      for (var p = 100.0; p <= 140; p += 10) {
        v.onScroll(update(p, 10));
      }
      expect(v.value, isFalse);
      for (var p = 130.0; p >= 90; p -= 10) {
        v.onScroll(update(p, -10));
      }
      expect(v.value, isTrue);
    });

    test('small back-and-forth movements never toggle', () {
      final v = BottomBarVisibility();
      for (var i = 0; i < 40; i++) {
        v.onScroll(update(500 + (i.isEven ? 10 : 0), i.isEven ? 10 : -10));
      }
      expect(v.value, isTrue);
    });

    test('shows at the top, at the end and on short content; horizontal scrolls are ignored', () {
      final v = BottomBarVisibility();
      v.onScroll(update(600, 40));
      expect(v.value, isFalse);
      v.onScroll(update(2, -5));
      expect(v.value, isTrue, reason: 'top');
      v.onScroll(update(600, 40));
      v.onScroll(update(2996, 5));
      expect(v.value, isTrue, reason: 'end of content');
      v.onScroll(update(600, 40));
      v.onScroll(update(600, 400, axis: Axis.horizontal));
      expect(v.value, isFalse, reason: 'a carousel does not count');
      v.show();
      v.onScroll(update(60, 40, max: 120));
      expect(v.value, isTrue, reason: 'short content');
    });
  });

  group('AutoHideBottomBar', () {
    Widget shell(BottomBarVisibility v, {bool reduce = false, bool reader = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: const Size(390, 844), disableAnimations: reduce, accessibleNavigation: reader),
        child: Scaffold(
          body: const SizedBox.expand(key: ValueKey('body')),
          bottomNavigationBar: AutoHideBottomBar(
            visibility: v,
            child: const SizedBox(height: 64, child: Text('Barre')),
          ),
        ),
      ),
    );

    testWidgets('slides out, the page gains the room, slides back', (tester) async {
      final v = BottomBarVisibility();
      await tester.pumpWidget(shell(v));
      expect(tester.getSize(find.byKey(const ValueKey('body'))).height, 600 - 64);
      v.value = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 110));
      final mid = tester.getSize(find.byKey(const ValueKey('body'))).height;
      expect(mid, greaterThan(600 - 64));
      expect(mid, lessThan(600));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const ValueKey('body'))).height, 600);
      v.show();
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const ValueKey('body'))).height, 600 - 64);
    });

    testWidgets('reduced motion: no animation frames', (tester) async {
      final v = BottomBarVisibility();
      await tester.pumpWidget(shell(v, reduce: true));
      v.value = false;
      await tester.pump();
      expect(tester.getSize(find.byKey(const ValueKey('body'))).height, 600);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('screen reader on: the tabs never hide', (tester) async {
      final v = BottomBarVisibility();
      await tester.pumpWidget(shell(v, reader: true));
      v.value = false;
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const ValueKey('body'))).height, 600 - 64);
    });
  });

  test('update suggestion: dotted version comparison', () {
    expect(AppUpdate.isNewer('5.12.12', '5.12.11'), isTrue);
    expect(AppUpdate.isNewer('5.13', '5.12.11'), isTrue);
    expect(AppUpdate.isNewer('5.12.11', '5.12.11'), isFalse);
    expect(AppUpdate.isNewer('1.1.3', '5.12.11'), isFalse, reason: 'today’s public App Store version');
    expect(AppUpdate.isNewer('5.12.10', '5.12.11'), isFalse, reason: 'a TestFlight build ahead of the store');
  });
}

class _FakeContext extends Fake implements BuildContext {}
