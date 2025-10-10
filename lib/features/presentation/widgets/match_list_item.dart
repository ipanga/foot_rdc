import 'package:flutter/material.dart';
import 'package:foot_rdc/features/domain/entities/match.dart';
import 'package:foot_rdc/utils/date_utils.dart'; // Add this import for formatArticleDate

class MatchListItem extends StatelessWidget {
  final Match match;
  final VoidCallback? onTap;

  const MatchListItem({super.key, required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasScore = match.homeScore != null && match.awayScore != null;
    final statusLabel = hasScore ? 'FT' : 'À venir';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          // Gradient frame
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.18),
                colorScheme.primary.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Container(
            margin: const EdgeInsets.all(1.2),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top row: status + date
                Row(
                  children: [
                    _StatusChip(label: statusLabel, colorScheme: colorScheme),
                    const Spacer(),
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatArticleDate(match.dateGmt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Main row: teams + score
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Home team (name + logo)
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              match.homeTeam,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _buildTeamIcon(context, match.homeTeam, size: 34),
                        ],
                      ),
                    ),

                    // Score
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: hasScore
                                ? colorScheme.primary.withOpacity(0.10)
                                : colorScheme.surfaceVariant.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: hasScore
                                  ? colorScheme.primary.withOpacity(0.30)
                                  : colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            hasScore
                                ? "${match.homeScore} - ${match.awayScore}"
                                : "VS",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: hasScore
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withOpacity(0.7),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Away team (logo + name)
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildTeamIcon(context, match.awayTeam, size: 34),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              match.awayTeam,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Circular badge wrapper around the existing team icon
  Widget _buildTeamIcon(
    BuildContext context,
    String teamName, {
    double size = 30,
  }) {
    final cs = Theme.of(context).colorScheme;
    final inner = size - 8; // padding * 2

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.surfaceVariant.withOpacity(0.35),
        border: Border.all(color: cs.outline.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: _TeamIconWidget(teamName: teamName, size: inner),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;

  const _StatusChip({required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final isFinal = label.toUpperCase() == 'FT';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isFinal
            ? colorScheme.secondaryContainer.withOpacity(0.7)
            : colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isFinal
              ? colorScheme.primary.withOpacity(0.35)
              : colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFinal ? Icons.flag_rounded : Icons.event_available_rounded,
            size: 14,
            color: isFinal
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isFinal
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.8),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final possibleUrls = _generatePossibleUrls(widget.teamName);

    if (_currentUrlIndex >= possibleUrls.length) {
      // All URLs failed, show fallback
      return Container(
        width: widget.size,
        height: widget.size,
        color: Colors.transparent,
        child: Icon(
          Icons.sports_soccer,
          size: widget.size * 0.6,
          color: colorScheme.onSurface.withOpacity(0.6),
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
            // Try next URL
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _currentUrlIndex++;
                });
              }
            });
            return const SizedBox.shrink();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Container(
              width: widget.size,
              height: widget.size,
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              child: Center(
                child: SizedBox(
                  width: widget.size * 0.5,
                  height: widget.size * 0.5,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
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
