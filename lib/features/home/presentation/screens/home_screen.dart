import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/network/connectivity_service.dart';
import 'package:foot_rdc/features/news/presentation/screens/news_list_screen.dart';
import 'package:foot_rdc/features/news/presentation/providers/article_cache_provider.dart';
import 'package:foot_rdc/features/home/presentation/providers/home_providers.dart';
import 'package:foot_rdc/shared/providers/connectivity_provider.dart';
import 'package:foot_rdc/shared/widgets/connectivity_banner.dart';
import 'package:foot_rdc/shared/widgets/persistent_banner_ad.dart';
import 'package:foot_rdc/shared/widgets/premium_bottom_nav_bar.dart';
import 'package:foot_rdc/features/editorial/presentation/providers/editorial_providers.dart';
import 'package:foot_rdc/features/editorial/presentation/screens/editorial_list_screen.dart';
import 'package:foot_rdc/features/football/presentation/screens/linafoot_screen.dart';
import 'package:foot_rdc/features/football/presentation/screens/matches_screen.dart';
import 'package:foot_rdc/features/more/more_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

/// The five destinations. Football tabs refresh themselves through their providers.
class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  static const _edito = 3;
  final GlobalKey<EditorialListScreenState> _editoKey = GlobalKey<EditorialListScreenState>();

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
    if (state == AppLifecycleState.resumed) _refresh(ref.read(currentPageProvider));
  }

  void _refresh(int page) {
    if (page == 0) {
      final cache = ref.read(articleCacheProvider);
      if (cache.articles.isNotEmpty && !cache.isCacheValid(validDuration: const Duration(minutes: 2))) {
        ref.read(articleCacheProvider.notifier).clearCache();
      }
    } else if (page == _edito) {
      _editoKey.currentState?.checkAndRefreshIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(currentPageProvider);

    // Refresh once per offline to online transition, never in a loop.
    ref.listen<AsyncValue<ConnectivityStatus>>(connectivityStatusProvider, (prev, next) {
      if (prev?.valueOrNull == ConnectivityStatus.disconnected && next.valueOrNull == ConnectivityStatus.connected) {
        _refresh(ref.read(currentPageProvider));
      }
    });

    final pages = [
      const NewsListScreen(),
      const MatchesScreen(),
      const LinafootScreen(),
      EditorialListScreen(key: _editoKey, channel: EditorialChannel.edito),
      const MoreScreen(),
    ];

    return Scaffold(
      extendBody: false,
      body: pages[currentPage],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ConnectivityBanner(),
          const PersistentBannerAd(),
          PremiumBottomNavBar(
            currentIndex: currentPage,
            onTap: (index) {
              if (index != currentPage) _refresh(index);
              ref.read(currentPageProvider.notifier).state = index;
            },
            items: const [
              PremiumNavItem.svg(
                iconPath: 'assets/images/home-icon-v2-outlined.svg',
                activeIconPath: 'assets/images/home-icon-v2-filled.svg',
                label: 'Accueil',
              ),
              PremiumNavItem.svg(
                iconPath: 'assets/images/soccer-field-icon-outlined.svg',
                activeIconPath: 'assets/images/soccer-field-icon-filled.svg',
                label: 'Matchs',
              ),
              PremiumNavItem.svg(
                iconPath: 'assets/images/ranking-icon-outlined.svg',
                activeIconPath: 'assets/images/ranking-icon-filled.svg',
                label: 'Linafoot',
              ),
              PremiumNavItem.icon(icon: Icons.edit_note_outlined, activeIcon: Icons.edit_note, label: 'Édito'),
              PremiumNavItem.icon(icon: Icons.menu_rounded, activeIcon: Icons.menu_rounded, label: 'Plus'),
            ],
          ),
        ],
      ),
    );
  }
}
