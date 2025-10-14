import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core_error/logger_riverpod.dart';
import 'package:foot_rdc/features/data/models/article_model.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:foot_rdc/features/domain/entities/match.dart';
import 'package:foot_rdc/features/domain/repositories/article_web_repository.dart';
import 'package:foot_rdc/features/domain/repositories/article_search_repository.dart';
import 'package:foot_rdc/features/domain/repositories/match_repository.dart';
import 'package:foot_rdc/features/presentation/pages/home_page.dart';
import 'package:foot_rdc/features/presentation/providers/theme_provider.dart';
import 'package:foot_rdc/utils/app_theme.dart';
import 'package:foot_rdc/firebase_options.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main.g.dart';

// This function is no longer needed as OneSignal will handle background notifications.
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   if (kDebugMode) {
//     print("Handling a background message: ${message.messageId}");
//   }
// }

@riverpod
Future<List<Article>> fetchArticles(Ref ref, String input) {
  final articleRepository = ref.watch(articleRepositoryProvider);
  return articleRepository.fetchArticlesData(input);
}

@riverpod
Future<List<Article>> searchArticles(Ref ref, String searchName) {
  final articleSearchRepository = ref.watch(articleSearchRepositoryProvider);
  return articleSearchRepository.searchArticlesData(searchName);
}

@riverpod
Future<List<Match>> fetchMatches(Ref ref, String pagination) {
  final matchRepository = ref.watch(matchRepositoryProvider);
  return matchRepository.fetchMatchesData(pagination);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler); // OneSignal handles this now.

  // OneSignal Initialization
  if (kDebugMode) {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  }
  OneSignal.initialize("e9096906-f601-4639-93a7-de95eb3c1db5");

  // The promptForPushNotificationsWithUserResponse function will show the iOS or Android push notification prompt.
  // We recommend removing the following code and instead using an In-App Message to prompt for notification permission
  OneSignal.Notifications.requestPermission(true);

  // The Firebase Messaging listeners below are removed as OneSignal will handle notifications.
  /*
  // Request permission and handle foreground messages
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (kDebugMode) {
    print('Permission granted: ${settings.authorizationStatus}');
    final fcmToken = await messaging.getToken();
    print("FCM Token: $fcmToken");
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (kDebugMode) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
    }

    if (message.notification != null) {
      if (kDebugMode) {
        print('Message also contained a notification: ${message.notification}');
      }
    }
  });
  */

  await MobileAds.instance.initialize();

  // This is required to store and retrieve trip data locally
  await Hive.initFlutter((await getApplicationDocumentsDirectory()).path);
  // Register the adapter and open the box
  Hive.registerAdapter(ArticleModelAdapter());
  // Open box or create it if it doesn't exist
  await Hive.openBox<ArticleModel>(
    'articles',
  ); // Name of the box to store articles of type ArticleModel

  runApp(
    ProviderScope(
      // Wrap your app to keep track of all the providers
      observers: [LoggerRiverpod()], // To log provider changes
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeCustomNotifierProvider);

    return MaterialApp(
      title: 'FootRDC',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref
          .read(themeCustomNotifierProvider.notifier)
          .getFlutterThemeMode(context),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
