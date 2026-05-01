import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:foot_rdc/features/rankings/presentation/providers/ranking_provider.dart';
import 'package:foot_rdc/features/rankings/presentation/providers/ranking_cache_provider.dart';
import 'package:foot_rdc/features/rankings/domain/entities/ranking.dart';
import 'package:foot_rdc/features/rankings/presentation/widgets/ranking_widgets.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';
import 'package:foot_rdc/shared/widgets/premium_tab_bar.dart';

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => RankingsScreenState();
}

class RankingsScreenState extends ConsumerState<RankingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Tab order: Play-Off (active phase) first, then Groupe A, Groupe B.
  // See ApiConstants.currentPhaseLeagueId.
  static const _tabLeagueIds = <int>[
    ApiConstants.playOffLeagueId,
    ApiConstants.groupeALeagueId,
    ApiConstants.groupeBLeagueId,
  ];

  static const int seasonId = ApiConstants.currentSeasonId;

  int _leagueIdForTab(int index) =>
      _tabLeagueIds[index.clamp(0, _tabLeagueIds.length - 1)];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load initial data for the first (default) tab — Play-Off.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRankingForTab(0);
    });

    // Ensure data loads when user changes tab via swipe or programmatically
    _tabController.addListener(() {
      // When the tab change animation completes, indexIsChanging becomes false
      if (!_tabController.indexIsChanging) {
        _loadRankingForTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadRankingForTab(int tabIndex) {
    final leagueId = _leagueIdForTab(tabIndex);

    final cacheState = ref.read(rankingCacheProvider);

    // Check if we have valid cached data
    if (cacheState.isCacheValid(leagueId, seasonId) &&
        cacheState.hasCachedData(leagueId, seasonId)) {
      // Load from cache immediately
      ref
          .read(rankingNotifierProvider.notifier)
          .loadFromCacheIfAvailable(leagueId: leagueId, seasonId: seasonId);
    } else {
      // Fetch from network
      ref
          .read(rankingNotifierProvider.notifier)
          .fetchRanking(leagueId: leagueId, seasonId: seasonId);
    }
  }

  // Pull-to-refresh helper - always force refresh
  Future<void> _refreshRankingForCurrentTab() {
    final leagueId = _leagueIdForTab(_tabController.index);
    return ref
        .read(rankingNotifierProvider.notifier)
        .fetchRanking(
          leagueId: leagueId,
          seasonId: seasonId,
          forceRefresh: true,
        );
  }

  // Check and refresh cache if needed (called from HomePage)
  void checkAndRefreshIfNeeded() {
    final currentTabIndex = _tabController.index;
    final leagueId = _leagueIdForTab(currentTabIndex);

    final cacheState = ref.read(rankingCacheProvider);

    // If cache is invalid and we have cached data, clear it
    if (cacheState.hasCachedData(leagueId, seasonId) &&
        !cacheState.isCacheValid(leagueId, seasonId)) {
      ref
          .read(rankingCacheProvider.notifier)
          .clearCacheForLeague(leagueId, seasonId);
      // Trigger a fresh fetch
      _loadRankingForTab(currentTabIndex);
    }
  }

  // Friendly error helpers (URL-free detection from message text)
  bool _looksNoInternet(String message) {
    final m = message.toLowerCase();
    return m.contains('socketexception') ||
        m.contains('failed host lookup') ||
        m.contains('network is unreachable') ||
        m.contains('internet') ||
        m.contains('network') ||
        m.contains('connection refused');
  }

  bool _looksTimeout(String message) {
    final m = message.toLowerCase();
    return m.contains('timeoutexception') ||
        m.contains('timeout') ||
        m.contains('delai');
  }

  String _friendlyTitleFrom(String message) {
    if (_looksNoInternet(message)) return 'Pas de connexion internet';
    return 'Oups, un probleme est survenu';
  }

  String _friendlyMessageFrom(String message) {
    if (_looksNoInternet(message)) {
      return 'Verifiez votre connexion et reessayez.';
    }
    if (_looksTimeout(message)) {
      return 'Le serveur met trop de temps a repondre. Reessayez.';
    }
    return 'Impossible de charger le classement. Veuillez reessayer.';
  }

  IconData _friendlyIconFrom(String message) {
    if (_looksNoInternet(message)) return Icons.wifi_off_rounded;
    if (_looksTimeout(message)) return Icons.schedule_rounded;
    return Icons.error_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
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
              'CLASSEMENT LINAFOOT',
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
            onTap: _loadRankingForTab,
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
        children: [
          _buildRankingTab('Play-off'),
          _buildRankingTab('Groupe A'),
          _buildRankingTab('Groupe B'),
        ],
      ),
    );
  }

  Widget _buildRankingTab(String groupName) {
    return Consumer(
      builder: (context, ref, child) {
        final rankingState = ref.watch(rankingNotifierProvider);
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final colorScheme = theme.colorScheme;

        if (rankingState is RankingLoading) {
          return RankingLoadingState(
            isDark: isDark,
            colorScheme: colorScheme,
            theme: theme,
          );
        }

        if (rankingState is RankingError) {
          final title = _friendlyTitleFrom(rankingState.message);
          final message = _friendlyMessageFrom(rankingState.message);
          final icon = _friendlyIconFrom(rankingState.message);

          return RankingErrorState(
            title: title,
            message: message,
            icon: icon,
            isDark: isDark,
            colorScheme: colorScheme,
            theme: theme,
            onRetry: () => _loadRankingForTab(_tabController.index),
          );
        }

        if (rankingState is RankingLoaded) {
          return _buildRankingTable(rankingState.ranking);
        }

        return RankingEmptyState(
          isDark: isDark,
          colorScheme: colorScheme,
          theme: theme,
          onRefresh: () => _loadRankingForTab(_tabController.index),
        );
      },
    );
  }

  Widget _buildRankingTable(Ranking ranking) {
    final teams = ranking.teams;
    final headers = ranking.headers;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    if (teams.isEmpty) {
      return RankingEmptyState(
        isDark: isDark,
        colorScheme: colorScheme,
        theme: theme,
        onRefresh: _refreshRankingForCurrentTab,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshRankingForCurrentTab,
      color: colorScheme.primary,
      backgroundColor: isDark
          ? AppColors.surfaceElevatedDark
          : AppColors.surfaceLight,
      strokeWidth: 2.5,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Top spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: AppDesignSystem.space16),
          ),

          // Ranking table card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.space12,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.surfaceLight,
                  borderRadius: AppDesignSystem.borderRadiusXl,
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    width: 1,
                  ),
                  boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
                ),
                child: ClipRRect(
                  borderRadius: AppDesignSystem.borderRadiusXl,
                  child: Column(
                    children: [
                      // Table header
                      RankingTableHeader(
                        headers: headers,
                        isDark: isDark,
                      ),

                      // Team rows with animation
                      ...teams.asMap().entries.map((entry) {
                        final index = entry.key;
                        final team = entry.value;

                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(
                            milliseconds: 200 + (index * 50),
                          ),
                          curve: AppDesignSystem.curveEmphasized,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: RankingTeamRow(
                            team: team,
                            index: index,
                            isDark: isDark,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Legend section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDesignSystem.space16),
              child: _buildLegend(isDark, theme),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: AppDesignSystem.space24),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.space16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerDark.withAlpha(60)
            : AppColors.surfaceContainerLight.withAlpha(100),
        borderRadius: AppDesignSystem.borderRadiusLg,
        border: Border.all(
          color: isDark
              ? AppColors.borderSubtleDark
              : AppColors.borderSubtleLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legende',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppDesignSystem.space12),
          Wrap(
            spacing: AppDesignSystem.space16,
            runSpacing: AppDesignSystem.space8,
            children: [
              _LegendItem(
                label: 'J - Matchs joues',
                isDark: isDark,
              ),
              _LegendItem(
                label: 'G - Victoires',
                color: AppColors.success,
                isDark: isDark,
              ),
              _LegendItem(
                label: 'N - Nuls',
                isDark: isDark,
              ),
              _LegendItem(
                label: 'D - Defaites',
                color: AppColors.error,
                isDark: isDark,
              ),
              _LegendItem(
                label: 'DIF - Difference de buts',
                isDark: isDark,
              ),
              _LegendItem(
                label: 'PTS - Points',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isDark;

  const _LegendItem({
    required this.label,
    this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (color != null) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDesignSystem.space6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
