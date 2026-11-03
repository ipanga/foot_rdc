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

/// Logo and wordmark, read by screen readers as "FootRDC".
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      header: true,
      label: 'FootRDC',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/logo_splash_footrdc.png', height: 32, fit: BoxFit.contain),
          const SizedBox(width: 10),
          Text(
            'FOOTRDC',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              height: 1,
              color: isDark ? AppColors.brandPrimaryLight : AppColors.brandPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
