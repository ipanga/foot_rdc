import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/shared/widgets/ads.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ad frames follow Google's sizes and are never clipped or pinned next to navigation.
void main() {
  // Created but never loaded: no plugin call in widget tests.
  final ad = NativeAd(
    adUnitId: 'test',
    listener: NativeAdListener(),
    request: const AdRequest(),
    nativeTemplateStyle: NativeTemplateStyle(templateType: TemplateType.medium),
  );

  Future<Size> frameAt(WidgetTester tester, double width, {bool? loaded = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: ListView(
                children: [NativeAdSlot(ad: ad, loaded: loaded)],
              ),
            ),
          ),
        ),
      ),
    );
    final frame = find.byKey(const ValueKey('native-ad-frame'));
    return frame.evaluate().isEmpty ? Size.zero : tester.getSize(frame);
  }

  testWidgets('native frame stays within 320–400 on phones and tablets', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final width in [320.0, 358.0, 390.0, 768.0, 1100.0]) {
      final size = await frameAt(tester, width);
      expect(size.width, inInclusiveRange(320, 400), reason: 'width at $width');
      expect(size.height, inInclusiveRange(320, 400), reason: 'height at $width');
    }
  });

  testWidgets('nothing clips the ad and the label sits outside its frame', (tester) async {
    await frameAt(tester, 390);
    final frame = find.byKey(const ValueKey('native-ad-frame'));
    expect(find.descendant(of: find.byType(NativeAdSlot), matching: find.byType(ClipRRect)), findsNothing);
    expect(find.descendant(of: find.byType(NativeAdSlot), matching: find.byType(ClipRect)), findsNothing);
    expect(find.descendant(of: find.byType(NativeAdSlot), matching: find.byType(ClipPath)), findsNothing);
    // The list's own viewport clips while scrolling, like any list; nothing inside the slot may clip the ad.
    final containers = tester.widgetList<Container>(
      find.descendant(of: find.byType(NativeAdSlot), matching: find.byType(Container)),
    );
    expect(containers.where((c) => c.clipBehavior != Clip.none), isEmpty);
    expect(find.text('PUBLICITÉ'), findsOneWidget);
    expect(find.descendant(of: frame, matching: find.text('PUBLICITÉ')), findsNothing);
  });

  testWidgets('a failed ad or a screen narrower than the template takes no space', (tester) async {
    expect(await frameAt(tester, 390, loaded: null), Size.zero);
    expect(find.text('PUBLICITÉ'), findsNothing);
    expect(await frameAt(tester, 300), Size.zero);
  });

  testWidgets('the inline banner takes no space before an ad has loaded', (tester) async {
    disableInlineBannerAdsForTests();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Column(children: [InlineBannerAd(), Text('fin')])),
      ),
    );
    expect(find.text('PUBLICITÉ'), findsNothing);
    expect(tester.getTopLeft(find.text('fin')).dy, 0);
  });

  test('ads live only in ads.dart, and no banner is anchored to the navigation', () {
    final offenders = <String>[];
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final text = file.readAsStringSync();
      if (file.path.endsWith('shared/widgets/ads.dart')) {
        continue;
      }
      if (RegExp(r'(?<![A-Za-z])(BannerAd|NativeAd|AdWidget)\(|AnchoredAdaptive').hasMatch(text)) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
    expect(File('lib/shared/widgets/ads.dart').readAsStringSync().contains('AnchoredAdaptive'), isFalse);
  });
}
