import 'package:flutter/material.dart';

/// A custom AppBar widget with a modern design featuring:
/// - An icon in a decorated container with shadow
/// - A gradient title text
/// - An optional subtitle
/// - Custom elevation and shadow
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The icon to display in the AppBar
  final IconData icon;

  /// The main title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional TabBar to display at the bottom of the AppBar
  final PreferredSizeWidget? bottom;

  /// Whether to center the title (default: false)
  final bool centerTitle;

  /// Custom elevation (default: 4.0)
  final double elevation;

  const CustomAppBar({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.bottom,
    this.centerTitle = false,
    this.elevation = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    colorScheme.surface,
                    colorScheme.surface.withOpacity(0.95),
                  ]
                : [
                    colorScheme.surface,
                    colorScheme.surface.withOpacity(0.98),
                  ],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withOpacity(0.15),
                  colorScheme.primary.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.05),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                    stops: const [0.3, 0.9],
                  ).createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Oswald',
                      letterSpacing: 1.8,
                      height: 1.2,
                      color: Colors.white, // color is replaced by shader
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                      letterSpacing: 0.3,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      centerTitle: centerTitle,
      elevation: elevation,
      shadowColor: isDark ? Colors.black45 : Colors.black26,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
