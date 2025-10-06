import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/presentation/providers/ranking_provider.dart';
import 'package:foot_rdc/features/domain/entities/ranking.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '|  CLASSEMENT LINAFOOT',
          style: TextStyle(
            color: Color(0xFFec3535),
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Oswald',
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.3),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: TabBar(
          controller: _tabController,
          onTap: _loadRankingForTab,
          indicatorColor: Colors.red,
          indicatorWeight: 3,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.grey[600],
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
      backgroundColor: Colors.grey[50],
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

        if (rankingState is RankingLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          );
        }

        if (rankingState is RankingError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    rankingState.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _loadRankingForTab(_tabController.index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
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
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune donnée disponible',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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

    if (teams.isEmpty) {
      return const Center(
        child: Text('Aucune équipe trouvée', style: TextStyle(fontSize: 16)),
      );
    }

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.white),
              headingRowHeight: 50,
              headingTextStyle: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
              dataTextStyle: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              columnSpacing: 14,
              horizontalMargin: 12,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
                top: BorderSide(color: Colors.grey[300]!, width: 2),
              ),
              columns: [
                const DataColumn(label: Text('Pos')),
                const DataColumn(label: Text('Club')),
                DataColumn(label: Text(headers?.pts ?? 'Pts')),
                DataColumn(label: Text(headers?.p ?? 'J')),
                DataColumn(label: Text(headers?.w ?? 'G')),
                DataColumn(label: Text(headers?.d ?? 'N')),
                DataColumn(label: Text(headers?.ptwo ?? 'D')),
                DataColumn(label: Text(headers?.gd ?? 'DIF')),
              ],
              rows: teams.map((team) {
                return DataRow(
                  color: MaterialStateProperty.all(Colors.white),
                  cells: [
                    DataCell(
                      Text(
                        '${team.pos}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(
                          team.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        team.pts ?? '0',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    DataCell(Text(team.p ?? '0')),
                    DataCell(Text(team.w ?? '0')),
                    DataCell(Text(team.d ?? '0')),
                    DataCell(Text(team.ptwo ?? '0')),
                    DataCell(
                      Center(
                        child: Text(
                          team.gd ?? '0',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
