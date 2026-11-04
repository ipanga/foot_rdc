import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foot_rdc/core/notifications/push_messages.dart';
import 'package:foot_rdc/features/news/presentation/widgets/article_list_item.dart';
import 'package:foot_rdc/firebase_options.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'qa_support.dart';

/// Starts the app as main() does and writes its FCM token to `Documents/push_qa_token` (never printed), then leaves
/// the app installed and running (`--keep-app-running`) for background / closed-app checks of REAL remote pushes.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('push token for background checks', (tester) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final qa = Qa(tester, binding, 'token');
    await qa.launch();
    unawaited(setUpPushMessaging());
    await qa.wait(find.byType(ArticleListItem));
    final token = await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 30));
    expect(token, isNotNull);
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/push_qa_token').writeAsString(token!, flush: true);
    // ignore: avoid_print
    print('QA-INFO token-file ready (${token.length} chars)');
  });
}
