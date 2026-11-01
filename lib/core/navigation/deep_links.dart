/// Where a link leads. Parsing is pure so that every link form can be tested.
sealed class DeepLink {
  const DeepLink();

  /// Accepts `footrdc://club/4` and `https://footrdc.com/...` article URLs. Unknown links return null and open nothing.
  static DeepLink? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    if (uri.scheme == 'footrdc') {
      final id = uri.pathSegments.isEmpty ? null : int.tryParse(uri.pathSegments.first);
      return switch (uri.host) {
        'match' when id != null && id > 0 => MatchLink(id),
        'club' when id != null && id > 0 => ClubLink(id),
        'article' when id != null && id > 0 => ArticleLink(id),
        'linafoot' => const LinafootLink(),
        'standings' => const LinafootLink(standings: true),
        _ => null,
      };
    }
    final host = uri.host.replaceFirst('www.', '');
    if ((uri.scheme == 'https' || uri.scheme == 'http') && host == 'footrdc.com') {
      if (uri.pathSegments.isEmpty) return null;
      if (uri.pathSegments.first == 'linafoot') {
        return uri.pathSegments.any((s) => s.startsWith('classement'))
            ? const LinafootLink(standings: true)
            : const LinafootLink();
      }
      return ArticleSlugLink(uri.pathSegments.where((s) => s.isNotEmpty).last);
    }
    return null;
  }
}

class MatchLink extends DeepLink {
  final int id;
  const MatchLink(this.id);
}

class ClubLink extends DeepLink {
  final int id;
  const ClubLink(this.id);
}

class ArticleLink extends DeepLink {
  final int id;
  const ArticleLink(this.id);
}

class ArticleSlugLink extends DeepLink {
  final String slug;
  const ArticleSlugLink(this.slug);
}

class LinafootLink extends DeepLink {
  final bool standings;
  const LinafootLink({this.standings = false});
}
