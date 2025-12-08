import 'package:flutter/material.dart';
import 'package:foot_rdc/features/matches/domain/entities/match.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';
import 'package:foot_rdc/core/utils/date_utils.dart';

class MatchListItem extends StatelessWidget {
  final Match match;
  final VoidCallback? onTap;

  const MatchListItem({super.key, required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final hasScore = match.homeScore != null && match.awayScore != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.space12,
        vertical: AppDesignSystem.space6,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppDesignSystem.borderRadiusXl,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDesignSystem.borderRadiusXl,
          splashColor: colorScheme.primary.withAlpha(15),
          highlightColor: colorScheme.primary.withAlpha(8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.surfaceLight,
              borderRadius: AppDesignSystem.borderRadiusXl,
              border: Border.all(
                color: isDark
                    ? AppColors.borderSubtleDark
                    : AppColors.borderSubtleLight,
                width: 1,
              ),
              boxShadow: isDark ? AppShadows.softDark : AppShadows.cardLight,
            ),
            child: Column(
              children: [
                // Header with status and date
                _MatchHeader(
                  date: match.dateGmt,
                  hasScore: hasScore,
                  isDark: isDark,
                ),

                // Main content: Teams and Score
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDesignSystem.space16,
                    AppDesignSystem.space12,
                    AppDesignSystem.space16,
                    AppDesignSystem.space16,
                  ),
                  child: Row(
                    children: [
                      // Home Team
                      Expanded(
                        child: _TeamSection(
                          teamName: match.homeTeam,
                          score: match.homeScore,
                          isHome: true,
                          hasScore: hasScore,
                          isDark: isDark,
                          isWinner: _isWinner(match.homeScore, match.awayScore),
                        ),
                      ),

                      // Score Box
                      _ScoreBox(
                        homeScore: match.homeScore,
                        awayScore: match.awayScore,
                        hasScore: hasScore,
                        isDark: isDark,
                      ),

                      // Away Team
                      Expanded(
                        child: _TeamSection(
                          teamName: match.awayTeam,
                          score: match.awayScore,
                          isHome: false,
                          hasScore: hasScore,
                          isDark: isDark,
                          isWinner: _isWinner(match.awayScore, match.homeScore),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isWinner(int? score1, int? score2) {
    if (score1 == null || score2 == null) return false;
    return score1 > score2;
  }
}

/// Header section with match status and date
class _MatchHeader extends StatelessWidget {
  final DateTime? date;
  final bool hasScore;
  final bool isDark;

  const _MatchHeader({
    required this.date,
    required this.hasScore,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.space16,
        vertical: AppDesignSystem.space10,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerDark.withAlpha(60)
            : AppColors.surfaceContainerLight.withAlpha(180),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDesignSystem.radiusXl),
        ),
      ),
      child: Row(
        children: [
          _MatchStatusBadge(
            isFinished: hasScore,
            isDark: isDark,
          ),
          const Spacer(),
          if (date != null) ...[
            Icon(
              Icons.calendar_today_rounded,
              size: 12,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            const SizedBox(width: AppDesignSystem.space6),
            Text(
              formatArticleDate(date!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Team section with logo and name
class _TeamSection extends StatelessWidget {
  final String teamName;
  final int? score;
  final bool isHome;
  final bool hasScore;
  final bool isDark;
  final bool isWinner;

  const _TeamSection({
    required this.teamName,
    required this.score,
    required this.isHome,
    required this.hasScore,
    required this.isDark,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Team Logo
        _TeamLogo(
          teamName: teamName,
          size: 44,
          isDark: isDark,
          isWinner: isWinner && hasScore,
        ),

        const SizedBox(height: AppDesignSystem.space10),

        // Team Name
        Text(
          teamName,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: isWinner && hasScore ? FontWeight.w800 : FontWeight.w600,
            color: isWinner && hasScore
                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Modern score box with gradient and animations
class _ScoreBox extends StatelessWidget {
  final int? homeScore;
  final int? awayScore;
  final bool hasScore;
  final bool isDark;

  const _ScoreBox({
    required this.homeScore,
    required this.awayScore,
    required this.hasScore,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!hasScore) {
      return _buildUpcomingMatch(theme, colorScheme);
    }

    return _buildScoreDisplay(theme, colorScheme);
  }

  Widget _buildUpcomingMatch(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDesignSystem.space12),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.space16,
        vertical: AppDesignSystem.space12,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight,
        borderRadius: AppDesignSystem.borderRadiusMd,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Text(
        'VS',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
          letterSpacing: 3,
          fontFamily: 'Oswald',
        ),
      ),
    );
  }

  Widget _buildScoreDisplay(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDesignSystem.space8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            Color.lerp(colorScheme.primary, Colors.black, 0.2)!,
          ],
        ),
        borderRadius: AppDesignSystem.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(isDark ? 60 : 40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.space4,
          vertical: AppDesignSystem.space8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Home Score
            _ScoreDigit(
              score: homeScore ?? 0,
              isWinner: (homeScore ?? 0) > (awayScore ?? 0),
            ),

            // Separator
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.space6,
              ),
              child: Text(
                ':',
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'Oswald',
                ),
              ),
            ),

            // Away Score
            _ScoreDigit(
              score: awayScore ?? 0,
              isWinner: (awayScore ?? 0) > (homeScore ?? 0),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual score digit with background
class _ScoreDigit extends StatelessWidget {
  final int score;
  final bool isWinner;

  const _ScoreDigit({
    required this.score,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 40,
      decoration: BoxDecoration(
        color: isWinner
            ? Colors.white.withAlpha(30)
            : Colors.white.withAlpha(15),
        borderRadius: AppDesignSystem.borderRadiusSm,
      ),
      child: Center(
        child: Text(
          '$score',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Oswald',
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Match status badge
class _MatchStatusBadge extends StatelessWidget {
  final bool isFinished;
  final bool isDark;

  const _MatchStatusBadge({
    required this.isFinished,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final label = isFinished ? 'Terminé' : 'A venir';
    final icon = isFinished
        ? Icons.check_circle_rounded
        : Icons.access_time_rounded;

    final backgroundColor = isFinished
        ? AppColors.matchFinished.withAlpha(isDark ? 30 : 20)
        : AppColors.matchUpcoming.withAlpha(isDark ? 30 : 20);

    final foregroundColor = isFinished
        ? AppColors.matchFinished
        : AppColors.matchUpcoming;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.space10,
        vertical: AppDesignSystem.space4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppDesignSystem.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foregroundColor),
          const SizedBox(width: AppDesignSystem.space4),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Team logo with loading and error states
class _TeamLogo extends StatefulWidget {
  final String teamName;
  final double size;
  final bool isDark;
  final bool isWinner;

  const _TeamLogo({
    required this.teamName,
    this.size = 44,
    required this.isDark,
    this.isWinner = false,
  });

  @override
  State<_TeamLogo> createState() => _TeamLogoState();
}

class _TeamLogoState extends State<_TeamLogo> {
  int _currentUrlIndex = 0;

  List<String> _generatePossibleUrls(String teamName) {
    const baseUrl =
        "https://i0.wp.com/footrdc.com/wp-content/uploads/2021/10/Team-";

    return [
      "$baseUrl${teamName.trim().replaceAll(' ', '-')}.png",
      "$baseUrl${teamName.split(' ').map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()).join('-')}.png",
      "$baseUrl${teamName.trim().replaceAll(' ', '-').toUpperCase()}.png",
      "$baseUrl${teamName.trim().replaceAll(' ', '-').toLowerCase()}.png",
      if (!teamName.toUpperCase().startsWith('FC'))
        "$baseUrl${'FC-${teamName.trim().replaceAll(' ', '-')}'}.png",
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final possibleUrls = _generatePossibleUrls(widget.teamName);

    return AnimatedContainer(
      duration: AppDesignSystem.durationFast,
      curve: AppDesignSystem.curveDefault,
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight,
        border: Border.all(
          color: widget.isWinner
              ? colorScheme.primary.withAlpha(widget.isDark ? 100 : 80)
              : (widget.isDark ? AppColors.borderDark : AppColors.borderLight),
          width: widget.isWinner ? 2 : 1,
        ),
        boxShadow: widget.isWinner
            ? [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(30),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : (widget.isDark ? [] : AppShadows.softLight),
      ),
      child: ClipOval(
        child: _currentUrlIndex >= possibleUrls.length
            ? _buildFallbackIcon(colorScheme)
            : Image.network(
                possibleUrls[_currentUrlIndex],
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _currentUrlIndex++);
                    }
                  });
                  return _buildFallbackIcon(colorScheme);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: widget.size * 0.4,
                      height: widget.size * 0.4,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary.withAlpha(100),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildFallbackIcon(ColorScheme colorScheme) {
    return Center(
      child: Icon(
        Icons.sports_soccer_rounded,
        size: widget.size * 0.45,
        color: widget.isDark
            ? AppColors.textTertiaryDark
            : AppColors.textTertiaryLight,
      ),
    );
  }
}

/// Compact match card for horizontal lists
class MatchCompactCard extends StatelessWidget {
  final Match match;
  final VoidCallback? onTap;
  final double width;

  const MatchCompactCard({
    super.key,
    required this.match,
    this.onTap,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final hasScore = match.homeScore != null && match.awayScore != null;

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppDesignSystem.borderRadiusLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDesignSystem.borderRadiusLg,
          child: Container(
            padding: const EdgeInsets.all(AppDesignSystem.space12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.surfaceLight,
              borderRadius: AppDesignSystem.borderRadiusLg,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: isDark ? AppShadows.softDark : AppShadows.cardLight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date
                Text(
                  formatArticleDate(match.dateGmt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),

                const SizedBox(height: AppDesignSystem.space10),

                // Teams and score
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Home
                    Expanded(
                      child: Column(
                        children: [
                          _TeamLogo(
                            teamName: match.homeTeam,
                            size: 32,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            match.homeTeam,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Score
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDesignSystem.space8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesignSystem.space10,
                          vertical: AppDesignSystem.space6,
                        ),
                        decoration: hasScore
                            ? BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    Color.lerp(colorScheme.primary, Colors.black, 0.15)!,
                                  ],
                                ),
                                borderRadius: AppDesignSystem.borderRadiusSm,
                              )
                            : BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceContainerDark
                                    : AppColors.surfaceContainerLight,
                                borderRadius: AppDesignSystem.borderRadiusSm,
                              ),
                        child: Text(
                          hasScore
                              ? "${match.homeScore} - ${match.awayScore}"
                              : "VS",
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: hasScore
                                ? Colors.white
                                : colorScheme.outline,
                            fontFamily: 'Oswald',
                          ),
                        ),
                      ),
                    ),

                    // Away
                    Expanded(
                      child: Column(
                        children: [
                          _TeamLogo(
                            teamName: match.awayTeam,
                            size: 32,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            match.awayTeam,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
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
}
