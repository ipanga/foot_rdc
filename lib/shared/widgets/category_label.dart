import 'package:flutter/material.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';

/// An article's category as an editorial kicker: small capitals, no box, in the colour of the publication date shown
/// beside it (the shared tertiary text token).
class CategoryLabel extends StatelessWidget {
  final String text;
  final double fontSize;

  /// Overrides the colour (for example white on a photo, matching the date there).
  final Color? color;
  const CategoryLabel(this.text, {super.key, this.fontSize = 11, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color ?? (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight),
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        height: 1.2,
      ),
    );
  }
}
