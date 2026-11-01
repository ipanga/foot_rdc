import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/network/connectivity_service.dart';
import 'package:foot_rdc/features/news/presentation/screens/news_list_screen.dart';
import 'package:foot_rdc/features/news/presentation/providers/article_cache_provider.dart';
import 'package:foot_rdc/features/home/presentation/app_tabs.dart';
import 'package:foot_rdc/shared/providers/connectivity_provider.dart';
import 'package:foot_rdc/shared/widgets/connectivity_banner.dart';
import 'package:foot_rdc/shared/widgets/persistent_banner_ad.dart';
import 'package:foot_rdc/shared/widgets/premium_bottom_nav_bar.dart';
import 'package:foot_rdc/features/editorial/presentation/providers/editorial_providers.dart';
import 'package:foot_rdc/features/editorial/presentation/screens/editorial_list_screen.dart';
import 'package:foot_rdc/features/football/presentation/providers.dart';
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
    if (state == AppLifecycleState.resumed) _refresh(ref.read(currentTabProvider));
  }

  void _refresh(AppTab tab) {
    if (tab.showsFootball) ref.read(footballRefreshProvider.notifier).state++;
    if (tab == AppTab.home) {
      final cache = ref.read(articleCacheProvider);
      if (cache.articles.isNotEmpty && !cache.isCacheValid(validDuration: const Duration(minutes: 2))) {
        ref.read(articleCacheProvider.notifier).clearCache();
      }
    } else if (tab == AppTab.edito) {
      _editoKey.currentState?.checkAndRefreshIfNeeded();
    }
  }

  Widget _page(AppTab tab) => switch (tab) {
    AppTab.home => const NewsListScreen(),
    AppTab.edito => EditorialListScreen(key: _editoKey, channel: EditorialChannel.edito),
    AppTab.matches => const MatchesScreen(),
    AppTab.linafoot => const LinafootScreen(),
    AppTab.more => const MoreScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);

    ref.listen<AppTab>(currentTabProvider, (_, next) => _refresh(next));

    // Refresh once per offline to online transition, never in a loop.
    ref.listen<AsyncValue<ConnectivityStatus>>(connectivityStatusProvider, (prev, next) {
      if (prev?.valueOrNull == ConnectivityStatus.disconnected && next.valueOrNull == ConnectivityStatus.connected) {
        _refresh(ref.read(currentTabProvider));
      }
    });

    // Each tab has its own Scaffold that handles the keyboard. Resizing here too would count it twice.
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      extendBody: false,
      resizeToAvoidBottomInset: false,
      body: TabPages(current: currentTab, builder: _page),
      bottomNavigationBar: Offstage(
        offstage: typing,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ConnectivityBanner(),
            const PersistentBannerAd(),
            // Tab labels have a fixed height, so they do not grow with system text size, as on native tab bars.
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.0,
              child: PremiumBottomNavBar(
                currentIndex: currentTab.index,
                onTap: (index) => ref.read(currentTabProvider.notifier).state = AppTab.values[index],
                items: [for (final tab in AppTab.values) appTabNavItem(tab)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
