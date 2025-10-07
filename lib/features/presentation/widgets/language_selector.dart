import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/presentation/providers/locale_provider.dart';
import 'package:foot_rdc/l10n/app_localizations.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language),
      tooltip: l10n.language,
      onSelected: (Locale locale) {
        ref.read(localeNotifierProvider.notifier).setLocale(locale);
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<Locale>(
          value: const Locale('fr'),
          child: Row(
            children: [
              if (currentLocale.languageCode == 'fr')
                const Icon(Icons.check, color: Color(0xFFec3535)),
              if (currentLocale.languageCode != 'fr') const SizedBox(width: 24),
              const SizedBox(width: 8),
              Text(l10n.french),
            ],
          ),
        ),
        PopupMenuItem<Locale>(
          value: const Locale('en'),
          child: Row(
            children: [
              if (currentLocale.languageCode == 'en')
                const Icon(Icons.check, color: Color(0xFFec3535)),
              if (currentLocale.languageCode != 'en') const SizedBox(width: 24),
              const SizedBox(width: 8),
              Text(l10n.english),
            ],
          ),
        ),
      ],
    );
  }
}
