import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/editorial/presentation/screens/editorial_list_screen.dart';
import 'package:foot_rdc/features/news/presentation/screens/news_list_screen.dart';
import 'package:foot_rdc/features/matches/presentation/screens/matches_list_screen.dart';
import 'package:foot_rdc/features/rankings/presentation/screens/rankings_screen.dart';
import 'package:foot_rdc/features/saved_articles/presentation/screens/saved_articles_screen.dart';
import 'package:foot_rdc/features/news/presentation/providers/article_cache_provider.dart';
import 'package:foot_rdc/features/home/presentation/providers/home_providers.dart';
import 'package:foot_rdc/shared/widgets/persistent_banner_ad.dart';
import 'package:foot_rdc/shared/widgets/premium_bottom_nav_bar.dart';

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
  final GlobalKey<EditorialListScreenState> _editorialScreenKey =
      GlobalKey<EditorialListScreenState>();

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

      // Tab order: 0 Accueil · 1 À Savoir · 2 Matchs · 3 Classement · 4 Enregistrés.
      switch (currentPage) {
        case 0:
          _checkAndRefreshArticlesIfNeeded();
          break;
        case 1:
          _checkAndRefreshEditorialIfNeeded();
          break;
        case 2:
          _checkAndRefreshMatchesIfNeeded();
          break;
        case 3:
          _checkAndRefreshRankingsIfNeeded();
          break;
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

  void _checkAndRefreshEditorialIfNeeded() {
    _editorialScreenKey.currentState?.checkAndRefreshIfNeeded();
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

    final pages = [
      const NewsListScreen(),
      EditorialListScreen(key: _editorialScreenKey),
      MatchesListScreen(key: _matchesScreenKey),
      RankingsScreen(key: _rankingsScreenKey),
      const SavedArticlesScreen(),
    ];

    return Scaffold(
      extendBody: false,
      body: pages[currentPage],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PersistentBannerAd(),
          PremiumBottomNavBar(
            currentIndex: currentPage,
            onTap: (index) {
              if (index != currentPage) {
                switch (index) {
                  case 0:
                    _checkAndRefreshArticlesIfNeeded();
                    break;
                  case 1:
                    _checkAndRefreshEditorialIfNeeded();
                    break;
                  case 2:
                    _checkAndRefreshMatchesIfNeeded();
                    break;
                  case 3:
                    _checkAndRefreshRankingsIfNeeded();
                    break;
                }
              }
              ref.read(currentPageProvider.notifier).state = index;
            },
            items: const [
              PremiumNavItem.svg(
                iconPath: 'assets/images/home-icon-v2-outlined.svg',
                activeIconPath: 'assets/images/home-icon-v2-filled.svg',
                label: 'Accueil',
              ),
              PremiumNavItem.icon(
                icon: Icons.lightbulb_outline_rounded,
                activeIcon: Icons.lightbulb_rounded,
                label: 'À Savoir',
              ),
              PremiumNavItem.svg(
                iconPath: 'assets/images/soccer-field-icon-outlined.svg',
                activeIconPath: 'assets/images/soccer-field-icon-filled.svg',
                label: 'Matchs',
              ),
              PremiumNavItem.svg(
                iconPath: 'assets/images/ranking-icon-outlined.svg',
                activeIconPath: 'assets/images/ranking-icon-filled.svg',
                label: 'Classement',
              ),
              PremiumNavItem.svg(
                iconPath: 'assets/images/save-icon-outlined.svg',
                activeIconPath: 'assets/images/save-icon-filled.svg',
                label: 'Enregistrés',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
