import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/rankings/presentation/providers/ranking_provider.dart';
import 'package:foot_rdc/features/rankings/presentation/providers/ranking_cache_provider.dart';
import 'package:foot_rdc/features/rankings/domain/entities/ranking.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => RankingsScreenState();
}

class RankingsScreenState extends ConsumerState<RankingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // League and Season IDs from the API URLs
  static const int seasonId = 821;
  static const int groupeALeagueId = 546;
  static const int groupeBLeagueId = 547;
  static const int playOffLeagueId = 552;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load initial data for Groupe A
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
    int leagueId;
    switch (tabIndex) {
      case 0:
        leagueId = groupeALeagueId;
        break;
      case 1:
        leagueId = groupeBLeagueId;
        break;
      case 2:
        leagueId = playOffLeagueId;
        break;
      default:
        leagueId = groupeALeagueId;
    }

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
    int leagueId;
    switch (_tabController.index) {
      case 0:
        leagueId = groupeALeagueId;
        break;
      case 1:
        leagueId = groupeBLeagueId;
        break;
      case 2:
        leagueId = playOffLeagueId;
        break;
      default:
        leagueId = groupeALeagueId;
    }
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
    int leagueId;
    switch (currentTabIndex) {
      case 0:
        leagueId = groupeALeagueId;
        break;
      case 1:
        leagueId = groupeBLeagueId;
        break;
      case 2:
        leagueId = playOffLeagueId;
        break;
      default:
        leagueId = groupeALeagueId;
    }

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
        m.contains('délai');
  }

  String _friendlyTitleFrom(String message) {
    if (_looksNoInternet(message)) return 'Pas de connexion internet';
    return 'Oups, un problème est survenu';
  }

  String _friendlyMessageFrom(String message) {
    if (_looksNoInternet(message)) {
      return 'Vérifiez votre connexion et réessayez.';
    }
    if (_looksTimeout(message)) {
      return 'Le serveur met trop de temps à répondre. Réessayez.';
    }
    return 'Impossible de charger le classement. Veuillez réessayer.';
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
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: _loadRankingForTab,
              indicator: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: AppDesignSystem.borderRadiusMd,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withAlpha(isDark ? 60 : 40),
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
                fontSize: 12,
                fontFamily: 'Oswald',
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                fontFamily: 'Oswald',
                letterSpacing: 0.3,
              ),
              labelPadding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.space6,
              ),
              tabs: const [
                Tab(
                  height: 42,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_outlined, size: 16),
                      SizedBox(width: AppDesignSystem.space6),
                      Text('Groupe A'),
                    ],
                  ),
                ),
                Tab(
                  height: 42,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.groups_outlined, size: 16),
                      SizedBox(width: AppDesignSystem.space6),
                      Text('Groupe B'),
                    ],
                  ),
                ),
                Tab(
                  height: 42,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 16),
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
        children: [
          _buildRankingTab('Groupe A'),
          _buildRankingTab('Groupe B'),
          _buildRankingTab('Play-off'),
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.space16),
                Text(
                  'Chargement du classement...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        if (rankingState is RankingError) {
          final title = _friendlyTitleFrom(rankingState.message);
          final message = _friendlyMessageFrom(rankingState.message);
          final icon = _friendlyIconFrom(rankingState.message);

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.space32,
                vertical: AppDesignSystem.space20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDesignSystem.space20),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withAlpha(isDark ? 40 : 60),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 40,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: AppDesignSystem.space20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: AppDesignSystem.space8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppDesignSystem.space24),
                  FilledButton.icon(
                    onPressed: () => _loadRankingForTab(_tabController.index),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Réessayer'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDesignSystem.space24,
                        vertical: AppDesignSystem.space12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppDesignSystem.borderRadiusMd,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (rankingState is RankingLoaded) {
          return _buildRankingTable(rankingState.ranking);
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.space32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDesignSystem.space20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainerLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.table_chart_outlined,
                    size: 48,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.space20),
                Text(
                  'Aucune donnée disponible',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.space8),
                Text(
                  'Le classement sera affiché ici',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDesignSystem.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_soccer_outlined,
                size: 48,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
              const SizedBox(height: AppDesignSystem.space16),
              Text(
                'Aucune équipe trouvée',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshRankingForCurrentTab,
      color: colorScheme.primary,
      backgroundColor: isDark
          ? AppColors.surfaceElevatedDark
          : AppColors.surfaceLight,
      strokeWidth: 2.5,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: AppDesignSystem.space16,
            horizontal: AppDesignSystem.space12,
          ),
          decoration: BoxDecoration(
            borderRadius: AppDesignSystem.borderRadiusXl,
            color: isDark
                ? AppColors.surfaceElevatedDark
                : AppColors.surfaceLight,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: AnimatedSwitcher(
                      duration: AppDesignSystem.durationNormal,
                      switchInCurve: AppDesignSystem.curveDefault,
                      switchOutCurve: AppDesignSystem.curveDefault,
                      child: DataTable(
                        // Header
                        headingRowColor: WidgetStateProperty.all(
                          colorScheme.primary.withAlpha(isDark ? 40 : 30),
                        ),
                        headingRowHeight: 56,
                        headingTextStyle: TextStyle(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),

                        // Rows
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 64,
                        dataTextStyle: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),

                        // Layout
                        columnSpacing: 16,
                        horizontalMargin: 14,
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: isDark
                                ? AppColors.borderSubtleDark
                                : AppColors.borderSubtleLight,
                            width: 1,
                          ),
                        ),

                        columns: [
                          const DataColumn(label: Text('#')),
                          const DataColumn(label: Text('CLUB')),
                          DataColumn(
                            label: Center(
                              child: Text(
                                (headers?.pts ?? 'PTS').toUpperCase(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Center(
                              child: Text(
                                (headers?.p ?? 'J').toUpperCase(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Center(
                              child: Text(
                                (headers?.w ?? 'G').toUpperCase(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Center(
                              child: Text(
                                (headers?.d ?? 'N').toUpperCase(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Center(
                              child: Text(
                                (headers?.ptwo ?? 'D').toUpperCase(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Center(
                              child: Text(
                                (headers?.gd ?? 'DIF').toUpperCase(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],

                        rows: teams.asMap().entries.map((entry) {
                          final index = entry.key;
                          final team = entry.value;

                          final pos = team.pos;

                          final isOdd = index.isOdd;
                          final baseRowColor = isOdd
                              ? (isDark
                                  ? AppColors.surfaceContainerDark.withAlpha(60)
                                  : AppColors.surfaceContainerLight.withAlpha(128))
                              : (isDark
                                  ? AppColors.surfaceElevatedDark
                                  : AppColors.surfaceLight);

                          // Position-based styling
                          Color positionColor;
                          Color positionBgColor;
                          if (pos == 1) {
                            positionColor = AppColors.positionGold;
                            positionBgColor = AppColors.positionGold.withAlpha(isDark ? 40 : 25);
                          } else if (pos == 2) {
                            positionColor = AppColors.positionSilver;
                            positionBgColor = AppColors.positionSilver.withAlpha(isDark ? 40 : 25);
                          } else if (pos == 3) {
                            positionColor = AppColors.positionBronze;
                            positionBgColor = AppColors.positionBronze.withAlpha(isDark ? 40 : 25);
                          } else if (pos <= 4) {
                            positionColor = AppColors.positionPromotion;
                            positionBgColor = AppColors.positionPromotion.withAlpha(isDark ? 30 : 20);
                          } else {
                            positionColor = isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight;
                            positionBgColor = isDark
                                ? AppColors.surfaceContainerDark
                                : AppColors.surfaceContainerLight;
                          }

                          return DataRow(
                            color: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.hovered) ||
                                  states.contains(WidgetState.focused)) {
                                return colorScheme.primary.withAlpha(isDark ? 20 : 15);
                              }
                              return baseRowColor;
                            }),
                            cells: [
                              // Position badge
                              DataCell(
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: positionBgColor,
                                    borderRadius: AppDesignSystem.borderRadiusSm,
                                    border: Border.all(
                                      color: positionColor.withAlpha(isDark ? 100 : 80),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$pos',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: positionColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Club name
                              DataCell(
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 140),
                                  child: Text(
                                    team.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                              ),

                              // Points (highlighted)
                              DataCell(
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDesignSystem.space8,
                                      vertical: AppDesignSystem.space4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withAlpha(isDark ? 30 : 20),
                                      borderRadius: AppDesignSystem.borderRadiusSm,
                                    ),
                                    child: Text(
                                      team.pts ?? '0',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Other stats
                              DataCell(
                                Center(
                                  child: Text(
                                    team.p ?? '0',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    team.w ?? '0',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    team.d ?? '0',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiaryLight,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    team.ptwo ?? '0',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: _buildGoalDifference(team.gd ?? '0', isDark),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalDifference(String gd, bool isDark) {
    final value = int.tryParse(gd) ?? 0;
    Color textColor;

    if (value > 0) {
      textColor = AppColors.success;
    } else if (value < 0) {
      textColor = AppColors.error;
    } else {
      textColor = isDark
          ? AppColors.textTertiaryDark
          : AppColors.textTertiaryLight;
    }

    return Text(
      value > 0 ? '+$gd' : gd,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
