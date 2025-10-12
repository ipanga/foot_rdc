import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/presentation/providers/theme_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _changeTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeModeCustom themeModeCustom,
  ) {
    ref.read(themeCustomNotifierProvider.notifier).setTheme(themeModeCustom);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final currentTheme = ref.watch(themeCustomNotifierProvider);

    return Drawer(
      child: Column(
        children: [
          // Simple Header
          AnimatedContainer(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              // Softer header: subtle primary tint over surface
              color: Color.alphaBlend(
                scheme.primary.withOpacity(0.08),
                scheme.surface,
              ),
              border: Border(
                bottom: BorderSide(color: scheme.outline.withOpacity(0.2)),
              ),
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo_splash_footrdc.png',
                  height: 50,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                Text(
                  'FOOTRDC.COM',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Theme Section
                _DrawerSection(
                  title: 'Thème',
                  child: Column(
                    children: [
                      _ThemeOption(
                        icon: Icons.brightness_auto,
                        label: 'Système',
                        isSelected: currentTheme == ThemeModeCustom.system,
                        onTap: () =>
                            _changeTheme(context, ref, ThemeModeCustom.system),
                      ),
                      _ThemeOption(
                        icon: Icons.light_mode,
                        label: 'Clair',
                        isSelected: currentTheme == ThemeModeCustom.light,
                        onTap: () =>
                            _changeTheme(context, ref, ThemeModeCustom.light),
                      ),
                      _ThemeOption(
                        icon: Icons.dark_mode,
                        label: 'Sombre',
                        isSelected: currentTheme == ThemeModeCustom.dark,
                        onTap: () =>
                            _changeTheme(context, ref, ThemeModeCustom.dark),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Other Options
                _DrawerTile(
                  icon: Icons.info_outline,
                  label: 'À propos',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '© ${DateTime.now().year} FOOTRDC.COM',
              style: TextStyle(
                color: scheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check, size: 18, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.onSurface.withOpacity(0.7)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: scheme.onSurface),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: scheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
