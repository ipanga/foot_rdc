import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/navigation/deep_link_handler.dart';
import 'package:foot_rdc/core/notifications/push_messages.dart';
import 'package:foot_rdc/features/news/presentation/screens/article_detail_screen.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:foot_rdc/firebase_options.dart';
import 'package:integration_test/integration_test.dart';

import 'qa_support.dart';

/// Plus › Notifications on a device, the club picker, quiet hours, and a SIMULATED foreground banner (no remote
/// push: the banner is drawn locally). Firebase is initialised for real to check that an FCM token can be obtained.
/// Never taps the permission button (a system dialog would block the run).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('notifications settings and banner', (tester) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    String token = 'none';
    try {
      final t = await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 20));
      token = t == null ? 'null' : 'obtained (${t.length} chars)';
    } catch (e) {
      token = 'unavailable: ${e.toString().split('\n').first.replaceAll(RegExp(r'[A-Za-z0-9_-]{60,}'), '…')}';
    }
    // ignore: avoid_print
    print('QA-INFO FCM token: $token');
    final qa = Qa(tester, binding, 'notif');
    await qa.launch();
    await qa.wait(find.byType(ArticleListItem));
    await qa.nav('Plus');
    await qa.wait(find.text('Notifications'));
    await tester.tap(find.text('Notifications'));
    await qa.wait(find.text('Articles à la Une'));
    await qa.pumpFor(const Duration(seconds: 3));
    await qa.shot('reglages');

    await tester.tap(find.byKey(const ValueKey('notif-match')));
    await qa.pumpFor(const Duration(seconds: 1));
    await qa.shot('alertes-clubs');
    await tester.tap(find.byKey(const ValueKey('notif-clubs')));
    await qa.wait(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile).first);
    await qa.pumpFor(const Duration(seconds: 1));
    await qa.shot('choix-clubs');
    await tester.tap(find.byType(CheckboxListTile).first); // leave the club list as it was
    await qa.back();
    await qa.wait(find.text('Articles à la Une'));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('notif-quiet')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('notif-quiet')));
    await qa.pumpFor(const Duration(seconds: 1));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('notif-diagnostic')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await qa.pumpFor(const Duration(seconds: 2));
    await qa.shot('general');
    // Leave the preferences as they were.
    await tester.tap(find.byKey(const ValueKey('notif-quiet')));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('notif-match')),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('notif-match')));
    await qa.pumpFor(const Duration(seconds: 1));
    await qa.back();
    await qa.nav('Accueil');
    await qa.wait(find.byType(ArticleListItem));

    // SIMULATED foreground notification: the same banner a remote message produces; its button opens the article.
    final article = tester.widget<ArticleListItem>(find.byType(ArticleListItem).first).article;
    showNotificationBanner(title: 'FootRDC — À la Une', body: article.title, link: 'footrdc://article/${article.id}');
    await qa.pumpFor(const Duration(seconds: 1));
    await qa.shot('banniere-simulee');
    await tester.tap(find.text('Ouvrir'));
    await qa.wait(find.byType(ArticleDetailScreen), seconds: 40);
    await qa.pumpFor(const Duration(seconds: 2));
    expect(currentContentLink.value, 'footrdc://article/${article.id}');
    await qa.shot('article-depuis-notification');
    // A notification about the open article is not shown again.
    showForegroundNotificationForTest(article.id);
    await qa.pumpFor(const Duration(milliseconds: 800));
    expect(find.byKey(const ValueKey('push-banner')), findsNothing);
    await qa.back();
    expect(find.byType(ArticleDetailScreen), findsNothing);
    pushLinks.add('footrdc://article/${article.id}');
    await qa.wait(find.byType(ArticleDetailScreen), seconds: 40);
    await qa.back();
  });
}

void showForegroundNotificationForTest(int articleId) => showForegroundNotification(
  RemoteMessage(
    data: {'link': 'footrdc://article/$articleId'},
    notification: const RemoteNotification(title: 'FootRDC — À la Une', body: 'déjà ouvert'),
  ),
);
