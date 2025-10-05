import 'package:flutter/material.dart';
import 'package:foot_rdc/features/domain/entities/match.dart';
import 'package:foot_rdc/utils/date_utils.dart'; // Add this import for formatArticleDate

class MatchListItem extends StatelessWidget {
  final Match match;
  final VoidCallback? onTap;

  const MatchListItem({super.key, required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teams with swapped positions: name + logo for home, logo + name for away
              Row(
                children: [
                  // Home team (name + logo) - swapped
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            match.homeTeam,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTeamIcon(match.homeTeam),
                      ],
                    ),
                  ),

                  // Score in the middle
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        if (match.homeScore != null && match.awayScore != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFec3535).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${match.homeScore} - ${match.awayScore}",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFec3535),
                                  ),
                            ),
                          )
                        else
                          Text(
                            'VS',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                          ),
                      ],
                    ),
                  ),

                  // Away team (logo + name) - swapped
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildTeamIcon(match.awayTeam),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            match.awayTeam,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Date below the score using formatArticleDate
              Center(
                child: Text(
                  formatArticleDate(match.dateGmt),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamIcon(String teamName, {double size = 30}) {
    return _TeamIconWidget(teamName: teamName, size: size);
  }
}

class _TeamIconWidget extends StatefulWidget {
  final String teamName;
  final double size;

  const _TeamIconWidget({required this.teamName, this.size = 30});

  @override
  State<_TeamIconWidget> createState() => _TeamIconWidgetState();
}

class _TeamIconWidgetState extends State<_TeamIconWidget> {
  int _currentUrlIndex = 0;

  List<String> _generatePossibleUrls(String teamName) {
    final baseUrl =
        "https://i0.wp.com/footrdc.com/wp-content/uploads/2021/10/Team-";

    return [
      // Original formatting
      "$baseUrl${teamName.trim().replaceAll(' ', '-')}.png",
      // Uppercase first letter of each word
      "$baseUrl${teamName.split(' ').map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()).join('-')}.png",
      // All uppercase
      "$baseUrl${teamName.trim().replaceAll(' ', '-').toUpperCase()}.png",
      // All lowercase
      "$baseUrl${teamName.trim().replaceAll(' ', '-').toLowerCase()}.png",
      // With FC prefix if not present
      if (!teamName.toUpperCase().startsWith('FC'))
        "$baseUrl${'FC-${teamName.trim().replaceAll(' ', '-')}'}.png",
    ];
  }

  @override
  Widget build(BuildContext context) {
    final possibleUrls = _generatePossibleUrls(widget.teamName);

    if (_currentUrlIndex >= possibleUrls.length) {
      // All URLs failed, show fallback
      return Container(
        width: widget.size,
        height: widget.size,
        child: Icon(
          Icons.sports_soccer,
          size: widget.size * 0.6,
          color: Colors.grey[600],
        ),
      );
    }

    final currentUrl = possibleUrls[_currentUrlIndex];
    print('Trying URL $_currentUrlIndex: $currentUrl');

    return Container(
      width: widget.size,
      height: widget.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          currentUrl,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print('Failed URL $_currentUrlIndex: $currentUrl');
            // Try next URL
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _currentUrlIndex++;
                });
              }
            });
            return const SizedBox.shrink(); // Return empty while trying next URL
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              print('Successfully loaded: $currentUrl');
              return child;
            }
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: SizedBox(
                  width: widget.size * 0.5,
                  height: widget.size * 0.5,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
