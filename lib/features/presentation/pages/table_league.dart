import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/presentation/providers/ranking_provider.dart';
import 'package:foot_rdc/features/presentation/providers/ranking_cache_provider.dart';
import 'package:foot_rdc/features/domain/entities/ranking.dart';

class TableLeague extends ConsumerStatefulWidget {
  const TableLeague({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => TableLeagueState();
}

class TableLeagueState extends ConsumerState<TableLeague>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // League and Season IDs from the API URLs
  static const int seasonId = 553;
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '|  CLASSEMENT LINAFOOT',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Oswald',
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
        elevation: 2,
        shadowColor: colorScheme.shadow,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        bottom: TabBar(
          controller: _tabController,
          onTap: _loadRankingForTab,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: 'Oswald',
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            fontFamily: 'Oswald',
          ),
          tabs: const [
            Tab(text: 'Groupe A'),
            Tab(text: 'Groupe B'),
            Tab(text: 'Play-off'),
          ],
        ),
      ),
      backgroundColor: colorScheme.surface,
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
        final colorScheme = theme.colorScheme;

        if (rankingState is RankingLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          );
        }

        if (rankingState is RankingError) {
          // Use friendly, URL-free error messaging and design
          final title = _friendlyTitleFrom(rankingState.message);
          final message = _friendlyMessageFrom(rankingState.message);
          final icon = _friendlyIconFrom(rankingState.message);

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 36,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _loadRankingForTab(_tabController.index),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 64,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune donnée disponible',
                style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRankingTable(Ranking ranking) {
    final teams = ranking.teams;
    final headers = ranking.headers;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (teams.isEmpty) {
      return Center(
        child: Text(
          'Aucune équipe trouvée',
          style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshRankingForCurrentTab,
      color: colorScheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.08),
                spreadRadius: 2,
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: DataTable(
                  // Header
                  headingRowColor: MaterialStateProperty.all(
                    colorScheme.secondaryContainer.withOpacity(0.45),
                  ),
                  headingRowHeight: 56,
                  headingTextStyle: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),

                  // Rows
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 60,
                  dataTextStyle: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),

                  // Layout
                  columnSpacing: 12,
                  horizontalMargin: 10,
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: colorScheme.outline.withOpacity(0.25),
                      width: 1,
                    ),
                    top: BorderSide(
                      color: colorScheme.outline.withOpacity(0.6),
                      width: 2,
                    ),
                    bottom: BorderSide(
                      color: colorScheme.outline.withOpacity(0.6),
                      width: 2,
                    ),
                  ),

                  columns: [
                    const DataColumn(label: Text('Pos'), numeric: true),
                    const DataColumn(label: Text('Club')),
                    DataColumn(
                      label: Text(headers?.pts ?? 'Pts'),
                      numeric: true,
                    ),
                    DataColumn(label: Text(headers?.p ?? 'J'), numeric: true),
                    DataColumn(label: Text(headers?.w ?? 'G'), numeric: true),
                    DataColumn(label: Text(headers?.d ?? 'N'), numeric: true),
                    DataColumn(
                      label: Text(headers?.ptwo ?? 'D'),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(headers?.gd ?? 'DIF'),
                      numeric: true,
                    ),
                  ],

                  rows: teams.asMap().entries.map((entry) {
                    final index = entry.key;
                    final team = entry.value;

                    final pos = team.pos is int
                        ? team.pos as int
                        : int.tryParse('${team.pos}') ?? 0;

                    final isOdd = index.isOdd;
                    final baseRowColor = isOdd
                        ? colorScheme.secondaryContainer.withOpacity(0.08)
                        : colorScheme.surface;

                    return DataRow(
                      color: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered) ||
                            states.contains(WidgetState.focused)) {
                          return colorScheme.secondaryContainer.withOpacity(
                            0.18,
                          );
                        }
                        return baseRowColor;
                      }),
                      cells: [
                        // Position badge
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: pos <= 3
                                  ? colorScheme.primary.withOpacity(0.12)
                                  : colorScheme.surfaceVariant.withOpacity(
                                      0.36,
                                    ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: pos <= 3
                                    ? colorScheme.primary
                                    : colorScheme.outline.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '$pos',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: pos <= 3
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),

                        // Club name
                        DataCell(
                          SizedBox(
                            width: 135,
                            child: Text(
                              team.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),

                        // Numeric stats
                        DataCell(Text(team.pts ?? '0')),
                        DataCell(Text(team.p ?? '0')),
                        DataCell(Text(team.w ?? '0')),
                        DataCell(Text(team.d ?? '0')),
                        DataCell(Text(team.ptwo ?? '0')),
                        DataCell(Text(team.gd ?? '0')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
