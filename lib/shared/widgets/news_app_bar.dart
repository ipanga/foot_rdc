import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foot_rdc/core/theme/app_colors.dart';

/// Home app bar: the FootRDC brand on the left, search on the right. Settings, theme and notifications live in Plus.
class NewsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearchPressed;
  final Widget? trailing;

  const NewsAppBar({super.key, this.onSearchPressed, this.trailing});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AppBar(
      toolbarHeight: kToolbarHeight,
      automaticallyImplyLeading: false,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: isDark ? Colors.black54 : Colors.black12,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      titleSpacing: 16,
      centerTitle: false,
      title: const BrandTitle(),
      actions: [
        trailing ??
            IconButton(
              icon: const Icon(Icons.search_rounded, size: 26),
              tooltip: 'Rechercher',
              onPressed: onSearchPressed,
            ),
        const SizedBox(width: 6),
      ],
    );
  }
}

/// Logo and wordmark, read by screen readers as "FootRDC". The logo is the trimmed mark (the splash image carries
/// about 20 % transparent margin, which made the mark look small and off-centre), and the wordmark is centred on its
/// capitals, not on its line box, so both share one visual centre line.
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  static const markSize = 26.0;
  static const fontSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
      height: 1,
      leadingDistribution: TextLeadingDistribution.even,
      color: isDark ? AppColors.brandPrimaryLight : AppColors.brandPrimary,
    );
    return Semantics(
      header: true,
      label: 'FootRDC',
      excludeSemantics: true,
      // The wordmark keeps its size whatever the system text size, like the logo next to it.
      child: MediaQuery.withNoTextScaling(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo_mark_footrdc.png', width: markSize, height: markSize),
            const SizedBox(width: 9),
            _CapCentered(text: 'FOOTRDC', style: style),
          ],
        ),
      ),
    );
  }
}

/// Text whose capital letters (not its ascent/descent box) are centred in its height.
class _CapCentered extends StatelessWidget {
  final String text;
  final TextStyle style;
  const _CapCentered({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(style)),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    final metrics = painter.computeLineMetrics();
    painter.dispose();
    if (metrics.isEmpty) return Text(text, style: style);
    final line = metrics.first;
    // Capital height is about 0.71 em in the system fonts (Roboto, SF Pro). Centre of the capitals measured from
    // the top of the line box, compared with the centre of the box.
    final capHeight = (style.fontSize ?? 14) * 0.71;
    final capCentre = line.baseline - capHeight / 2;
    final shift = line.height / 2 - capCentre;
    return Transform.translate(offset: Offset(0, shift), child: Text(text, style: style));
  }
}
