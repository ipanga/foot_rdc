import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/presentation/providers/ranking_provider.dart';
import 'package:foot_rdc/features/domain/entities/ranking.dart';
import 'dart:ui' show FontFeature;

class TableLeague extends ConsumerStatefulWidget {
  const TableLeague({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TableLeagueState();
}

class _TableLeagueState extends ConsumerState<TableLeague>
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

    ref
        .read(rankingNotifierProvider.notifier)
        .fetchRanking(leagueId: leagueId, seasonId: seasonId);
  }

  // Pull-to-refresh helper
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
        .fetchRanking(leagueId: leagueId, seasonId: seasonId);
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: colorScheme.error.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    rankingState.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _loadRankingForTab(_tabController.index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
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
                  columnSpacing: 12, // was 18
                  horizontalMargin: 10, // was 14
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
                      color: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.hovered) ||
                            states.contains(MaterialState.focused)) {
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

                        // Club name (no initial avatar) with tighter width
                        DataCell(
                          SizedBox(
                            width: 135, // reduced to help the table fit
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

                        // Numeric stats (right-aligned by numeric: true)
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
