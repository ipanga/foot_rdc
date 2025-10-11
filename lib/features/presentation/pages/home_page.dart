import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foot_rdc/features/presentation/pages/article_web_list.dart';
import 'package:foot_rdc/features/presentation/pages/article_saved_list.dart';
import 'package:foot_rdc/features/presentation/pages/article_search_list.dart';
import 'package:foot_rdc/features/presentation/pages/matchs_list.dart';
import 'package:foot_rdc/features/presentation/pages/table_league.dart';
import 'package:foot_rdc/features/presentation/providers/theme_provider.dart';
import 'package:foot_rdc/features/presentation/providers/article_cache_provider.dart';

final currentPageProvider = StateProvider<int>((ref) => 0);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add lifecycle observer to detect app foreground/background
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app comes back to foreground, check if articles cache needs refresh
    if (state == AppLifecycleState.resumed) {
      final currentPage = ref.read(currentPageProvider);

      // Only check cache if user is currently on articles tab (index 0)
      if (currentPage == 0) {
        _checkAndRefreshArticlesIfNeeded();
      }
    }
  }

  void _changeTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeModeCustom themeModeCustom,
  ) {
    ref.read(themeCustomNotifierProvider.notifier).setTheme(themeModeCustom);
    Navigator.pop(context);

    String message;
    switch (themeModeCustom) {
      case ThemeModeCustom.light:
        message = 'Thème clair activé';
        break;
      case ThemeModeCustom.dark:
        message = 'Thème sombre activé';
        break;
      case ThemeModeCustom.system:
        message = 'Thème système activé';
        break;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _checkAndRefreshArticlesIfNeeded() {
    final cacheState = ref.read(articleCacheProvider);

    // Check if cache has expired (2 minutes)
    if (cacheState.articles.isNotEmpty &&
        !cacheState.isCacheValid(validDuration: const Duration(minutes: 2))) {
      // Trigger a refresh by clearing the cache
      // The ArticleWebList will automatically reload when it detects empty cache
      ref.read(articleCacheProvider.notifier).clearCache();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(currentPageProvider);
    final theme = Theme.of(context);

    List<Widget> pages = const [
      ArticleWebList(),
      MatchsList(),
      TableLeague(),
      ArticleSavedList(),
      ArticleSearchList(),
    ];

    return Scaffold(
      body: pages[currentPage],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          border: const Border(top: BorderSide(color: Colors.grey, width: 0.2)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 9,
          unselectedFontSize: 9,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w300),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w300),
          elevation: 0,
          currentIndex: currentPage,
          onTap: (value) {
            // Check if user is switching to articles tab (index 0)
            if (value == 0 && currentPage != 0) {
              _checkAndRefreshArticlesIfNeeded();
            }

            ref.read(currentPageProvider.notifier).state = value;
          },
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/home-icon-v2-outlined.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  theme.bottomNavigationBarTheme.unselectedItemColor ??
                      Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/home-icon-v2-filled.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  theme.bottomNavigationBarTheme.selectedItemColor ??
                      theme.primaryColor,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/soccer-field-icon-outlined.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  theme.bottomNavigationBarTheme.unselectedItemColor ??
                      Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/soccer-field-icon-filled.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  theme.bottomNavigationBarTheme.selectedItemColor ??
                      theme.primaryColor,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Matchs',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/ranking-icon-outlined.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  theme.bottomNavigationBarTheme.unselectedItemColor ??
                      Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/ranking-icon-filled.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  theme.bottomNavigationBarTheme.selectedItemColor ??
                      theme.primaryColor,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Classement',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/save-icon-outlined.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  theme.bottomNavigationBarTheme.unselectedItemColor ??
                      Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/save-icon-filled.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  theme.bottomNavigationBarTheme.selectedItemColor ??
                      theme.primaryColor,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Enregistrés',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/search-icon-outlined.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  theme.bottomNavigationBarTheme.unselectedItemColor ??
                      Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              activeIcon: SvgPicture.asset(
                'assets/images/search-icon-outlined.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  theme.bottomNavigationBarTheme.selectedItemColor ??
                      theme.primaryColor,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Recherche',
            ),
          ],
        ),
      ),
    );
  }
}
