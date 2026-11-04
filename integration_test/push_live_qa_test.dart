import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/notifications/push_messages.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:foot_rdc/firebase_options.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'qa_support.dart';

/// REAL remote push (Staging FCM test, 4 Nov 2026). The app's FCM token is written to a file inside the app sandbox
/// (`Documents/push_qa_token`, never printed); the operator registers it on Staging as a test device and sends real
/// messages through FCM. The test waits for each one to arrive as the in-app banner and opens it:
///   1. « FootRDC — test » (admin test message), 2. « FootRDC — À la Une » → article, 3. a match alert → match.
/// Matching QA-INFO lines tell the operator when to send the next message.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('live push through FCM', (tester) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final fm = FirebaseMessaging.instance;
    final before = await fm.getNotificationSettings();
    // ignore: avoid_print
    print('QA-INFO permission before: ${before.authorizationStatus.name}');
    // The simulator has no window to answer a system dialog: iOS provisional authorisation is granted without one
    // (delivery is real; alerts go quietly to Notification Center). Android: the operator grants POST_NOTIFICATIONS.
    if (Platform.isIOS && before.authorizationStatus == AuthorizationStatus.notDetermined) {
      await fm.requestPermission(provisional: true);
    }
    final qa = Qa(tester, binding, 'live');
    await qa.launch();
    unawaited(setUpPushMessaging()); // as main() does (the QA harness builds the app widget directly)
    await qa.wait(find.byType(ArticleListItem));
    final after = await fm.getNotificationSettings();
    // ignore: avoid_print
    print('QA-INFO permission: ${after.authorizationStatus.name}');
    final token = await fm.getToken().timeout(const Duration(seconds: 30));
    expect(token, isNotNull);
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/push_qa_token').writeAsString(token!, flush: true);
    // ignore: avoid_print
    print('QA-INFO token-file ready (${token.length} chars)');

    Future<String> waitBanner(String step, String expected, {int minutes = 8}) async {
      final end = DateTime.now().add(Duration(minutes: minutes));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 400));
        final banner = find.byKey(const ValueKey('push-banner'));
        if (banner.evaluate().isNotEmpty) {
          final all = find
              .descendant(of: banner, matching: find.byType(Text))
              .evaluate()
              .map((e) => (e.widget as Text).data ?? '')
              .where((t) => t.isNotEmpty)
              .toList();
          if (!all.any((t) => t.contains(expected))) continue; // an earlier banner still fading out
          final texts = all;
          // ignore: avoid_print
          print('QA-INFO received $step: ${texts.join(' | ')} at ${DateTime.now().toUtc().toIso8601String()}');
          await qa.shot('recu-$step');
          return texts.join(' | ');
        }
      }
      fail('no remote notification for $step within $minutes min');
    }

    // ignore: avoid_print
    print('QA-INFO waiting test');
    final t1 = await waitBanner('test', 'FootRDC — test');
    expect(t1, contains('FootRDC — test'));
    await qa.pumpFor(const Duration(seconds: 7)); // let the banner go

    // ignore: avoid_print
    print('QA-INFO waiting article');
    final t2 = await waitBanner('article', 'À la Une');
    expect(t2, contains('À la Une'));
    await tester.tap(find.text('Ouvrir'));
    await qa.wait(find.byType(ArticleDetailScreen), seconds: 40);
    await qa.pumpFor(const Duration(seconds: 2));
    // ignore: avoid_print
    print('QA-INFO opened ${currentContentLink.value}');
    await qa.shot('article-ouvert');
    await qa.back();

    // ignore: avoid_print
    print('QA-INFO waiting match');
    final t3 = await waitBanner('match', 'Résultat');
    await tester.tap(find.text('Ouvrir'));
    await qa.pumpFor(const Duration(seconds: 4));
    // ignore: avoid_print
    print('QA-INFO opened ${currentContentLink.value} after "$t3"');
    expect(currentContentLink.value, startsWith('footrdc://match/'));
    await qa.shot('match-ouvert');
    await qa.back();
  });
}
