import 'package:flutter/material.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';
import 'package:foot_rdc/core/theme/app_design_system.dart';
import 'package:foot_rdc/features/rankings/domain/entities/ranking.dart';

/// Modern ranking table header with column labels
class RankingTableHeader extends StatelessWidget {
  final TeamData? headers;
  final bool isDark;

  const RankingTableHeader({
    super.key,
    this.headers,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.space12,
        vertical: AppDesignSystem.space12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            Color.lerp(colorScheme.primary, Colors.black, 0.15)!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDesignSystem.radiusXl),
        ),
      ),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 32,
            child: Text(
              '#',
              style: _headerStyle,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: AppDesignSystem.space8),

          // Club name - takes remaining space
          Expanded(
            child: Text(
              'CLUB',
              style: _headerStyle,
            ),
          ),

          // Stats columns - compact
          _StatHeaderCell(label: headers?.p ?? 'J', width: 26),
          _StatHeaderCell(label: headers?.w ?? 'G', width: 26),
          _StatHeaderCell(label: headers?.d ?? 'N', width: 26),
          _StatHeaderCell(label: headers?.ptwo ?? 'D', width: 26),
          _StatHeaderCell(label: headers?.gd ?? 'DIF', width: 32),
          _StatHeaderCell(
            label: headers?.pts ?? 'PTS',
            width: 36,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  TextStyle get _headerStyle => const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 10,
        letterSpacing: 0.6,
      );
}

/// Header cell for stat columns
class _StatHeaderCell extends StatelessWidget {
  final String label;
  final double width;
  final bool isPrimary;

  const _StatHeaderCell({
    required this.label,
    required this.width,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: isPrimary ? Colors.white : Colors.white.withAlpha(200),
          fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w700,
          fontSize: isPrimary ? 11 : 10,
          letterSpacing: 0.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Individual ranking row with team data
class RankingTeamRow extends StatelessWidget {
  final TeamData team;
  final int index;
  final bool isDark;
  final VoidCallback? onTap;

  const RankingTeamRow({
    super.key,
    required this.team,
    required this.index,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pos = team.pos;

    // Position-based styling
    final positionStyle = _getPositionStyle(pos, isDark, colorScheme);

    // Alternating row background
    final rowColor = index.isOdd
        ? (isDark
            ? AppColors.surfaceContainerDark.withAlpha(40)
            : AppColors.surfaceContainerLight.withAlpha(100))
        : Colors.transparent;

    return Material(
      color: rowColor,
      child: InkWell(
        onTap: onTap,
        splashColor: colorScheme.primary.withAlpha(20),
        highlightColor: colorScheme.primary.withAlpha(10),
        child: AnimatedContainer(
          duration: AppDesignSystem.durationFast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.space12,
            vertical: AppDesignSystem.space10,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppColors.borderSubtleDark
                    : AppColors.borderSubtleLight,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Position badge - compact
              _PositionBadge(
                position: pos,
                color: positionStyle.color,
                backgroundColor: positionStyle.backgroundColor,
                isDark: isDark,
              ),

              const SizedBox(width: AppDesignSystem.space8),

              // Club name - takes all remaining space
              Expanded(
                child: Text(
                  team.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 12,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: AppDesignSystem.space4),

              // Stats - compact widths
              _StatCell(
                value: team.p ?? '0',
                width: 26,
                isDark: isDark,
              ),
              _StatCell(
                value: team.w ?? '0',
                width: 26,
                color: AppColors.success,
                isDark: isDark,
              ),
              _StatCell(
                value: team.d ?? '0',
                width: 26,
                isDark: isDark,
                isSecondary: true,
              ),
              _StatCell(
                value: team.ptwo ?? '0',
                width: 26,
                color: AppColors.error,
                isDark: isDark,
              ),
              _GoalDifferenceCell(
                value: team.gd ?? '0',
                width: 32,
                isDark: isDark,
              ),
              _PointsCell(
                value: team.pts ?? '0',
                width: 36,
                colorScheme: colorScheme,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _PositionStyle _getPositionStyle(
      int pos, bool isDark, ColorScheme colorScheme) {
    if (pos == 1) {
      return _PositionStyle(
        color: AppColors.positionGold,
        backgroundColor: AppColors.positionGold.withAlpha(isDark ? 35 : 20),
      );
    } else if (pos == 2) {
      return _PositionStyle(
        color: AppColors.positionSilver,
        backgroundColor: AppColors.positionSilver.withAlpha(isDark ? 35 : 20),
      );
    } else if (pos == 3) {
      return _PositionStyle(
        color: AppColors.positionBronze,
        backgroundColor: AppColors.positionBronze.withAlpha(isDark ? 35 : 20),
      );
    } else if (pos <= 4) {
      return _PositionStyle(
        color: AppColors.positionPromotion,
        backgroundColor:
            AppColors.positionPromotion.withAlpha(isDark ? 30 : 15),
      );
    } else {
      return _PositionStyle(
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        backgroundColor: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight,
      );
    }
  }
}

class _PositionStyle {
  final Color color;
  final Color backgroundColor;

  _PositionStyle({required this.color, required this.backgroundColor});
}

/// Position badge with medal-style design for top 3
class _PositionBadge extends StatelessWidget {
  final int position;
  final Color color;
  final Color backgroundColor;
  final bool isDark;

  const _PositionBadge({
    required this.position,
    required this.color,
    required this.backgroundColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isTopThree = position <= 3;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppDesignSystem.borderRadiusSm,
        border: Border.all(
          color: color.withAlpha(isTopThree ? 150 : 80),
          width: isTopThree ? 2 : 1,
        ),
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: color.withAlpha(30),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isTopThree && position == 1
            ? Icon(
                Icons.emoji_events_rounded,
                size: 16,
                color: color,
              )
            : Text(
                '$position',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
      ),
    );
  }
}

/// Stat cell for displaying numeric values
class _StatCell extends StatelessWidget {
  final String value;
  final double width;
  final Color? color;
  final bool isDark;
  final bool isSecondary;

  const _StatCell({
    required this.value,
    required this.width,
    this.color,
    required this.isDark,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        style: TextStyle(
          fontWeight: color != null ? FontWeight.w700 : FontWeight.w600,
          fontSize: 11,
          color: color ??
              (isSecondary
                  ? (isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight)
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight)),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Goal difference cell with positive/negative styling
class _GoalDifferenceCell extends StatelessWidget {
  final String value;
  final double width;
  final bool isDark;

  const _GoalDifferenceCell({
    required this.value,
    required this.width,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final numValue = int.tryParse(value) ?? 0;
    Color textColor;
    String displayValue;

    if (numValue > 0) {
      textColor = AppColors.success;
      displayValue = '+$value';
    } else if (numValue < 0) {
      textColor = AppColors.error;
      displayValue = value;
    } else {
      textColor =
          isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
      displayValue = value;
    }

    return SizedBox(
      width: width,
      child: Text(
        displayValue,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: textColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Points cell with highlighted background
class _PointsCell extends StatelessWidget {
  final String value;
  final double width;
  final ColorScheme colorScheme;
  final bool isDark;

  const _PointsCell({
    required this.value,
    required this.width,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.space4,
        vertical: AppDesignSystem.space4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(isDark ? 25 : 15),
        borderRadius: AppDesignSystem.borderRadiusSm,
      ),
      child: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: colorScheme.primary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Empty state widget for rankings
class RankingEmptyState extends StatelessWidget {
  final bool isDark;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onRefresh;

  const RankingEmptyState({
    super.key,
    required this.isDark,
    required this.colorScheme,
    required this.theme,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.space32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.space24),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.leaderboard_outlined,
                size: 56,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space24),
            Text(
              'Classement vide',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space8),
            Text(
              'Aucune equipe dans ce classement pour le moment.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space28),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Actualiser'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.space24,
                  vertical: AppDesignSystem.space14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppDesignSystem.borderRadiusMd,
                ),
                side: BorderSide(
                  color: colorScheme.primary.withAlpha(150),
                  width: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state widget for rankings
class RankingErrorState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final bool isDark;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onRetry;

  const RankingErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.isDark,
    required this.colorScheme,
    required this.theme,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(AppDesignSystem.space24),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withAlpha(isDark ? 40 : 60),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: AppDesignSystem.space24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
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
            const SizedBox(height: AppDesignSystem.space28),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Reessayer'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.space28,
                  vertical: AppDesignSystem.space14,
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
}

/// Loading state widget for rankings
class RankingLoadingState extends StatelessWidget {
  final bool isDark;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const RankingLoadingState({
    super.key,
    required this.isDark,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppDesignSystem.space20),
          Text(
            'Chargement du classement...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
