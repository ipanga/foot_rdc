import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core_error/logger_riverpod.dart';
import 'package:foot_rdc/features/data/models/article_model.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:foot_rdc/features/domain/repositories/article_web_repository.dart';
import 'package:foot_rdc/features/domain/repositories/article_search_repository.dart';
import 'package:foot_rdc/features/presentation/pages/home_page.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'main.g.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // Start from a red seed, then force all background/surface colors to white
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red).copyWith(
          surface: Colors.white,
          primary: Colors.red,
          secondary: Colors.red,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,

        // App bar (top) white
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.red),
          titleTextStyle: TextStyle(
            color: Colors.red,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Bottom app bar & BottomNavigation white
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          elevation: 0,
        ),

        // Material 3 NavigationBar (if used) white
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Colors.red.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Colors.red),
          ),
        ),
        cardColor: Colors.white,
        popupMenuTheme: const PopupMenuThemeData(color: Colors.white),

        // SnackBar on white background (floating to keep contrast)
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.white,
          contentTextStyle: TextStyle(color: Colors.black),
          behavior: SnackBarBehavior.floating,
        ),

        // Controls keep red as primary accent
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.red,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
        dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      ),
      home: const HomePage(),
    );
  }
}
