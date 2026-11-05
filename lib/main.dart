import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/errors/logger_riverpod.dart';
import 'package:foot_rdc/features/news/data/models/article_model.dart';
import 'package:foot_rdc/features/home/presentation/screens/home_screen.dart';
import 'package:foot_rdc/shared/providers/notification_provider.dart';
import 'package:foot_rdc/shared/providers/theme_provider.dart';
import 'package:foot_rdc/core/theme/app_theme.dart';
import 'package:foot_rdc/firebase_options.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:foot_rdc/core/navigation/deep_link_handler.dart';
import 'package:foot_rdc/core/notifications/push_messages.dart';
import 'package:foot_rdc/core/navigation/deep_links.dart';
import 'package:foot_rdc/features/football/presentation/providers.dart';
import 'package:foot_rdc/features/onboarding/club_onboarding.dart';
import 'package:foot_rdc/features/promotions/custom_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // OneSignal Initialization
  if (kDebugMode) {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  }

  OneSignal.initialize("e9096906-f601-4639-93a7-de95eb3c1db5");

  // Add subscription change listener to debug
  OneSignal.User.pushSubscription.addObserver((state) {
    if (kDebugMode) {
      print("OneSignal subscription changed:");
      print("  - ID: ${state.current.id}");
      print("  - Opted In: ${state.current.optedIn}");
    }
  });

  // Add permission change observer
  OneSignal.Notifications.addPermissionObserver((permission) {
    if (kDebugMode) {
      print("OneSignal permission changed: $permission");
    }
  });

  // Add foreground notification handler
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    if (kDebugMode) {
      print("OneSignal notification will display: ${event.notification.notificationId}");
    }
  });

  // Add click listener
  OneSignal.Notifications.addClickListener((event) {
    final link = notificationLink(event.notification.additionalData, event.notification.launchUrl);
    if (link != null) pushLinks.add(link);
    if (kDebugMode) {
      print("OneSignal notification clicked: ${event.notification.notificationId}");
    }
  });

  // No system permission dialog at launch: it is asked in context, when the user turns on alerts (club selection,
  // Plus › Notifications). OneSignal (kept during the transition) uses the same system permission.
  unawaited(setUpPushMessaging());

  await MobileAds.instance.initialize();

  // Initialize Hive for local storage
  await Hive.initFlutter((await getApplicationDocumentsDirectory()).path);
  // Register the adapter and open the box
  Hive.registerAdapter(ArticleModelAdapter());
  // Open box for storing articles
  await Hive.openBox<ArticleModel>('articles');

  runApp(ProviderScope(observers: [LoggerRiverpod()], child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeCustomNotifierProvider);
    // Starts notification registration (token, preferences, followed clubs) with the app.
    ref.listen(notificationNotifierProvider, (_, _) {});
    // FootRDC advertiser banners: fetched at start so they are known before the reader reaches a slot.
    ref.listen(customAdsProvider, (_, _) {});

    return MaterialApp(
      title: 'FootRDC',
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.read(themeCustomNotifierProvider.notifier).getFlutterThemeMode(context),
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appMessengerKey,
      home: const FootballLifecycle(
        child: DeepLinkHandler(child: ClubOnboardingGate(child: HomeScreen())),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
