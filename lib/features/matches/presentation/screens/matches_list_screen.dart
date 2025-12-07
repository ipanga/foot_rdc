import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:foot_rdc/features/matches/presentation/widgets/matches_tab_content.dart';
import 'package:foot_rdc/features/matches/presentation/providers/match_cache_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:foot_rdc/core/constants/ad_constants.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '|  RESULTATS MATCHS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Oswald',
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
        elevation: 4.0,
        shadowColor: theme.brightness == Brightness.light
            ? const Color.fromARGB(66, 63, 56, 56)
            : Colors.white24,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(102),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: colorScheme.primary.withAlpha(128),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(51),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onSurface.withAlpha(166),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'Oswald',
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Oswald',
                letterSpacing: 0.3,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              tabs: const [
                Tab(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group, size: 18),
                      SizedBox(width: 6),
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
                      SizedBox(width: 6),
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
                      SizedBox(width: 6),
                      Text('Play-off'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: colorScheme.surface,
      body: TabBarView(
        controller: _tabController,
        children: [
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
          ? SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : const SizedBox.shrink(),
    );
  }
}
