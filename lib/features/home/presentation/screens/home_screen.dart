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

    List<Widget> pages = [
      const NewsListScreen(),
      MatchesListScreen(key: _matchesScreenKey),
      RankingsScreen(key: _rankingsScreenKey),
      const SavedArticlesScreen(),
      const SearchScreen(),
    ];

    return Scaffold(
      body: pages[currentPage],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 0, left: 0, right: 0),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      (Theme.of(
                                context,
                              ).bottomNavigationBarTheme.backgroundColor ??
                              theme.scaffoldBackgroundColor)
                          .withAlpha(217),
                  border: const Border(
                    top: BorderSide(color: Colors.grey, width: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(
                        theme.brightness == Brightness.dark ? 51 : 15,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor:
                      theme.bottomNavigationBarTheme.selectedItemColor ??
                      theme.colorScheme.primary,
                  unselectedItemColor:
                      theme.bottomNavigationBarTheme.unselectedItemColor ??
                      Colors.grey,
                  selectedFontSize: 11,
                  unselectedFontSize: 10,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w400,
                  ),
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
                    BottomNavigationBarItem(
                      icon: SvgPicture.asset(
                        'assets/images/home-icon-v2-outlined.svg',
                        height: 26,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          theme.bottomNavigationBarTheme.unselectedItemColor ??
                              Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                      activeIcon: SvgPicture.asset(
                        'assets/images/home-icon-v2-filled.svg',
                        height: 26,
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
                        height: 26,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          theme.bottomNavigationBarTheme.unselectedItemColor ??
                              Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                      activeIcon: SvgPicture.asset(
                        'assets/images/soccer-field-icon-filled.svg',
                        height: 26,
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
                        height: 26,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          theme.bottomNavigationBarTheme.unselectedItemColor ??
                              Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                      activeIcon: SvgPicture.asset(
                        'assets/images/ranking-icon-filled.svg',
                        height: 26,
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
                        height: 26,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          theme.bottomNavigationBarTheme.unselectedItemColor ??
                              Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                      activeIcon: SvgPicture.asset(
                        'assets/images/save-icon-filled.svg',
                        height: 26,
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
                        height: 26,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          theme.bottomNavigationBarTheme.unselectedItemColor ??
                              Colors.grey,
                          BlendMode.srcIn,
                        ),
                      ),
                      activeIcon: SvgPicture.asset(
                        'assets/images/search-icon-outlined.svg',
                        height: 26,
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
            ),
          ),
        ),
      ),
    );
  }
}
