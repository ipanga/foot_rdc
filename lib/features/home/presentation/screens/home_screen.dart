import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foot_rdc/features/news/presentation/screens/news_list_screen.dart';
import 'package:foot_rdc/features/matches/presentation/screens/matches_list_screen.dart';
import 'package:foot_rdc/features/rankings/presentation/screens/rankings_screen.dart';
import 'package:foot_rdc/features/saved_articles/presentation/screens/saved_articles_screen.dart';
import 'package:foot_rdc/features/search/presentation/screens/search_screen.dart';
import 'package:foot_rdc/features/news/presentation/providers/article_cache_provider.dart';
import 'package:foot_rdc/features/home/presentation/providers/home_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final GlobalKey<RankingsScreenState> _rankingsScreenKey =
      GlobalKey<RankingsScreenState>();
  final GlobalKey<MatchesListScreenState> _matchesScreenKey =
      GlobalKey<MatchesListScreenState>();

  @override
  void initState() {
    super.initState();
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

    if (state == AppLifecycleState.resumed) {
      final currentPage = ref.read(currentPageProvider);

      if (currentPage == 0) {
        _checkAndRefreshArticlesIfNeeded();
      } else if (currentPage == 1) {
        _checkAndRefreshMatchesIfNeeded();
      } else if (currentPage == 2) {
        _checkAndRefreshRankingsIfNeeded();
      }
    }
  }

  void _checkAndRefreshArticlesIfNeeded() {
    final cacheState = ref.read(articleCacheProvider);

    if (cacheState.articles.isNotEmpty &&
        !cacheState.isCacheValid(validDuration: const Duration(minutes: 2))) {
      ref.read(articleCacheProvider.notifier).clearCache();
    }
  }

  void _checkAndRefreshMatchesIfNeeded() {
    _matchesScreenKey.currentState?.checkAndRefreshIfNeeded();
  }

  void _checkAndRefreshRankingsIfNeeded() {
    _rankingsScreenKey.currentState?.checkAndRefreshIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(currentPageProvider);
    final theme = Theme.of(context);
    final navTheme = theme.bottomNavigationBarTheme;

    List<Widget> pages = [
      const NewsListScreen(),
      MatchesListScreen(key: _matchesScreenKey),
      RankingsScreen(key: _rankingsScreenKey),
      const SavedArticlesScreen(),
      const SearchScreen(),
    ];

    return Scaffold(
      extendBody: true, // Allow body to extend behind the bottom nav
      body: pages[currentPage],
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: navTheme.backgroundColor,
              border: Border(
                top: BorderSide(
                  color: theme.dividerTheme.color ?? Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent, // Handled by Container
              type: BottomNavigationBarType.fixed,
              selectedItemColor: navTheme.selectedItemColor,
              unselectedItemColor: navTheme.unselectedItemColor,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              selectedLabelStyle: navTheme.selectedLabelStyle,
              unselectedLabelStyle: navTheme.unselectedLabelStyle,
              showUnselectedLabels: true,
              elevation: 0,
              currentIndex: currentPage,
              onTap: (value) {
                HapticFeedback.selectionClick();
                if (value == 0 && currentPage != 0) {
                  _checkAndRefreshArticlesIfNeeded();
                } else if (value == 1 && currentPage != 1) {
                  _checkAndRefreshMatchesIfNeeded();
                } else if (value == 2 && currentPage != 2) {
                  _checkAndRefreshRankingsIfNeeded();
                }
                ref.read(currentPageProvider.notifier).state = value;
              },
              items: [
                _buildNavItem(
                  'assets/images/home-icon-v2-outlined.svg',
                  'assets/images/home-icon-v2-filled.svg',
                  'Accueil',
                  theme,
                ),
                _buildNavItem(
                  'assets/images/soccer-field-icon-outlined.svg',
                  'assets/images/soccer-field-icon-filled.svg',
                  'Matchs',
                  theme,
                ),
                _buildNavItem(
                  'assets/images/ranking-icon-outlined.svg',
                  'assets/images/ranking-icon-filled.svg',
                  'Classement',
                  theme,
                ),
                _buildNavItem(
                  'assets/images/save-icon-outlined.svg',
                  'assets/images/save-icon-filled.svg',
                  'Enregistrés',
                  theme,
                ),
                _buildNavItem(
                  'assets/images/search-icon-outlined.svg',
                  'assets/images/search-icon-outlined.svg', // Assuming search doesn't have a filled variant or using same
                  'Recherche',
                  theme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    String iconPath,
    String activeIconPath,
    String label,
    ThemeData theme,
  ) {
    final navTheme = theme.bottomNavigationBarTheme;
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        iconPath,
        height: 24,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
          navTheme.unselectedItemColor ?? Colors.grey,
          BlendMode.srcIn,
        ),
      ),
      activeIcon: SvgPicture.asset(
        activeIconPath,
        height: 24,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
          navTheme.selectedItemColor ?? theme.primaryColor,
          BlendMode.srcIn,
        ),
      ),
      label: label,
    );
  }
}
