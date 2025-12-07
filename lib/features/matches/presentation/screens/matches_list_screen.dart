import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:foot_rdc/core/constants/ad_constants.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';
import 'package:foot_rdc/features/matches/presentation/widgets/matches_tab_content.dart';
import 'package:foot_rdc/features/matches/presentation/providers/match_cache_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MatchesListScreen extends ConsumerStatefulWidget {
  const MatchesListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      MatchesListScreenState();
}

class MatchesListScreenState extends ConsumerState<MatchesListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBannerAd();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdConstants.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  /// Check and refresh cache if needed (called from HomePage)
  void checkAndRefreshIfNeeded() {
    final currentTabIndex = _tabController.index;
    int leagueId;
    switch (currentTabIndex) {
      case 0:
        leagueId = ApiConstants.groupeALeagueId;
        break;
      case 1:
        leagueId = ApiConstants.groupeBLeagueId;
        break;
      case 2:
        leagueId = ApiConstants.playOffLeagueId;
        break;
      default:
        leagueId = ApiConstants.groupeALeagueId;
    }

    final cacheState = ref.read(matchCacheProvider);
    final leagueCache = cacheState.getLeagueCache(leagueId);

    // If cache is invalid and we have cached data, clear it
    if (leagueCache.isNotEmpty &&
        !leagueCache.isCacheValid(validDuration: const Duration(minutes: 2))) {
      ref.read(matchCacheProvider.notifier).clearCacheForLeague(leagueId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: AppDesignSystem.borderRadiusFull,
              ),
            ),
            const SizedBox(width: AppDesignSystem.space10),
            Text(
              'RÉSULTATS MATCHS',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFamily: 'Oswald',
                letterSpacing: 1.2,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: isDark ? Colors.black45 : Colors.black12,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.space12,
              vertical: AppDesignSystem.space8,
            ),
            padding: const EdgeInsets.all(AppDesignSystem.space4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceContainerLight,
              borderRadius: AppDesignSystem.borderRadiusLg,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: AppDesignSystem.borderRadiusMd,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                fontFamily: 'Oswald',
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                fontFamily: 'Oswald',
                letterSpacing: 0.3,
              ),
              labelPadding:
                  const EdgeInsets.symmetric(horizontal: AppDesignSystem.space8),
              tabs: const [
                Tab(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group, size: 18),
                      SizedBox(width: AppDesignSystem.space6),
                      Text('Groupe A'),
                    ],
                  ),
                ),
                Tab(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.groups, size: 18),
                      SizedBox(width: AppDesignSystem.space6),
                      Text('Groupe B'),
                    ],
                  ),
                ),
                Tab(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, size: 18),
                      SizedBox(width: AppDesignSystem.space6),
                      Text('Play-off'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MatchesTabContent(
            leagueId: ApiConstants.groupeALeagueId,
            tabName: 'Groupe A',
          ),
          MatchesTabContent(
            leagueId: ApiConstants.groupeBLeagueId,
            tabName: 'Groupe B',
          ),
          MatchesTabContent(
            leagueId: ApiConstants.playOffLeagueId,
            tabName: 'Play-off',
          ),
        ],
      ),
      bottomNavigationBar: _isAdLoaded && _bannerAd != null
          ? Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
