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
        borderRadius: AppDesignSystem.borderRadiusLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDesignSystem.borderRadiusLg,
          splashColor: colorScheme.primary.withAlpha(20),
          highlightColor: colorScheme.primary.withAlpha(8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withAlpha(isDark ? 30 : 25),
                  colorScheme.primary.withAlpha(isDark ? 8 : 6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppDesignSystem.borderRadiusLg,
            ),
            child: Container(
              margin: const EdgeInsets.all(1.5),
              padding: const EdgeInsets.all(AppDesignSystem.space14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceElevatedDark
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusLg - 1),
                boxShadow: isDark ? AppShadows.softDark : AppShadows.cardLight,
              ),
              child: Column(
                children: [
                  // Header row with status and date
                  _buildHeaderRow(context, isDark, hasScore),

                  const SizedBox(height: AppDesignSystem.space12),

                  // Teams and score row
                  _buildTeamsRow(context, isDark, hasScore),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, bool isDark, bool hasScore) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _MatchStatusBadge(
          isFinished: hasScore,
          isDark: isDark,
        ),
        const Spacer(),
        Icon(
          Icons.schedule_rounded,
          size: AppDesignSystem.iconXs,
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
        ),
        const SizedBox(width: AppDesignSystem.space6),
        Text(
          formatArticleDate(match.dateGmt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamsRow(BuildContext context, bool isDark, bool hasScore) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Home team
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  match.homeTeam,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDesignSystem.space10),
              _TeamLogo(teamName: match.homeTeam, size: 36, isDark: isDark),
            ],
          ),
        ),

        // Score box
        Expanded(
          flex: 1,
          child: Center(
            child: AnimatedContainer(
              duration: AppDesignSystem.durationFast,
              curve: AppDesignSystem.curveEmphasized,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.space12,
                vertical: AppDesignSystem.space8,
              ),
              decoration: BoxDecoration(
                color: hasScore
                    ? colorScheme.primary.withAlpha(isDark ? 30 : 20)
                    : (isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainerLight),
                borderRadius: AppDesignSystem.borderRadiusMd,
                border: Border.all(
                  color: hasScore
                      ? colorScheme.primary.withAlpha(isDark ? 60 : 50)
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: 1,
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
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                  letterSpacing: hasScore ? 1 : 2,
                  fontFamily: 'Oswald',
                ),
              ),
            ),
          ),
        ),

        // Away team
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _TeamLogo(teamName: match.awayTeam, size: 36, isDark: isDark),
              const SizedBox(width: AppDesignSystem.space10),
              Flexible(
                child: Text(
                  match.awayTeam,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatchStatusBadge extends StatelessWidget {
  final bool isFinished;
  final bool isDark;

  const _MatchStatusBadge({
    required this.isFinished,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final label = isFinished ? 'FT' : 'A venir';
    final icon = isFinished ? Icons.check_circle_outline : Icons.schedule_rounded;

    final backgroundColor = isFinished
        ? AppColors.matchFinished.withAlpha(isDark ? 40 : 25)
        : (isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight);

    final foregroundColor = isFinished
        ? AppColors.matchFinished
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    final borderColor = isFinished
        ? AppColors.matchFinished.withAlpha(isDark ? 60 : 40)
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.space10,
        vertical: AppDesignSystem.space4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppDesignSystem.borderRadiusFull,
        border: Border.all(color: borderColor, width: 1),
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

class _TeamLogo extends StatefulWidget {
  final String teamName;
  final double size;
  final bool isDark;

  const _TeamLogo({
    required this.teamName,
    this.size = 36,
    required this.isDark,
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

    final containerColor = widget.isDark
        ? AppColors.surfaceContainerDark
        : AppColors.surfaceContainerLight;

    final borderColor = widget.isDark
        ? AppColors.borderDark
        : AppColors.borderLight;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: containerColor,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: widget.isDark ? [] : AppShadows.softLight,
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
                  return Padding(
                    padding: EdgeInsets.all(widget.size * 0.25),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary.withAlpha(128),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildFallbackIcon(ColorScheme colorScheme) {
    return Icon(
      Icons.sports_soccer_rounded,
      size: widget.size * 0.5,
      color: colorScheme.outline,
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
                      child: Text(
                        hasScore
                            ? "${match.homeScore} - ${match.awayScore}"
                            : "VS",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: hasScore
                              ? colorScheme.primary
                              : colorScheme.outline,
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
