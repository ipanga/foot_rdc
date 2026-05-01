import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';
import 'package:foot_rdc/features/matches/presentation/widgets/matches_tab_content.dart';
import 'package:foot_rdc/features/matches/presentation/providers/match_cache_provider.dart';
import 'package:foot_rdc/shared/widgets/premium_tab_bar.dart';

class MatchesListScreen extends ConsumerStatefulWidget {
  const MatchesListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      MatchesListScreenState();
}

class MatchesListScreenState extends ConsumerState<MatchesListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Tab order: Play-Off (active phase) first, then Groupe A, Groupe B.
  /// See ApiConstants.currentPhaseLeagueId.
  static const _tabLeagueIds = <int>[
    ApiConstants.playOffLeagueId,
    ApiConstants.groupeALeagueId,
    ApiConstants.groupeBLeagueId,
  ];

  int _leagueIdForTab(int index) =>
      _tabLeagueIds[index.clamp(0, _tabLeagueIds.length - 1)];

  /// Check and refresh cache if needed (called from HomePage)
  void checkAndRefreshIfNeeded() {
    final leagueId = _leagueIdForTab(_tabController.index);
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
          child: PremiumTabBar(
            controller: _tabController,
            height: 44,
            tabs: const [
              PremiumTabItem(icon: Icons.emoji_events_outlined, label: 'Play-off'),
              PremiumTabItem(label: 'Groupe A'),
              PremiumTabItem(label: 'Groupe B'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MatchesTabContent(
            leagueId: ApiConstants.playOffLeagueId,
            tabName: 'Play-off',
          ),
          MatchesTabContent(
            leagueId: ApiConstants.groupeALeagueId,
            tabName: 'Groupe A',
          ),
          MatchesTabContent(
            leagueId: ApiConstants.groupeBLeagueId,
            tabName: 'Groupe B',
          ),
        ],
      ),
    );
  }
}
