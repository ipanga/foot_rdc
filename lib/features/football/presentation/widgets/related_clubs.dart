import 'package:flutter/material.dart';

import '../../../news/domain/entities/article.dart';
import '../football_routes.dart';
import 'football_widgets.dart';

/// "Clubs liés" at the end of an article: the clubs editors linked. Each opens the native club screen. Nothing is
/// drawn when the article has none, so articles without clubs look exactly as before.
class RelatedClubsSection extends StatelessWidget {
  final List<RelatedClub> clubs;
  const RelatedClubsSection({super.key, required this.clubs});

  @override
  Widget build(BuildContext context) {
    if (clubs.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'Clubs liés',
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: scheme.outlineVariant),
            const SizedBox(height: 12),
            Text('Clubs liés', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final club in clubs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => openClub(context, club.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          ClubCrest(url: club.crestUrl, name: club.name, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              club.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Voir le club',
                            style: text.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                          ),
                          Icon(Icons.chevron_right, color: scheme.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
