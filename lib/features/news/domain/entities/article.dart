class Article {
  final int id;
  final DateTime dateGmt;
  final String guid;
  final DateTime modifiedGmt;
  final String slug;
  final String status;
  final String type;
  final String category;
  final String link;
  final String title;
  final String content;
  final String excerpt;
  final String imageUrl;

  const Article({
    required this.id,
    required this.dateGmt,
    required this.guid,
    required this.modifiedGmt,
    required this.slug,
    required this.status,
    required this.type,
    required this.category,
    required this.link,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.imageUrl,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as int? ?? 0,
      dateGmt: DateTime.tryParse(json['date_gmt'] as String? ?? '') ??
          DateTime.now(),
      guid: (json['guid'] as Map<String, dynamic>?)?['rendered'] as String? ??
          '',
      modifiedGmt: DateTime.tryParse(json['modified_gmt'] as String? ?? '') ??
          DateTime.now(),
      slug: json['slug'] as String? ?? '',
      status: json['status'] as String? ?? '',
      type: json['type'] as String? ?? '',
      category: _extractCategoryName(json),
      link: json['link'] as String? ?? '',
      title:
          (json['title'] as Map<String, dynamic>?)?['rendered'] as String? ??
          '',
      content:
          (json['content'] as Map<String, dynamic>?)?['rendered'] as String? ??
          '',
      excerpt:
          (json['excerpt'] as Map<String, dynamic>?)?['rendered'] as String? ??
          '',
      imageUrl: _extractFeaturedImage(json),
    );
  }

  static String _extractCategoryName(Map<String, dynamic> json) {
    try {
      // Try to get category name from _embedded wp:term (when using _embed parameter)
      final embedded = json['_embedded'] as Map<String, dynamic>?;
      if (embedded != null) {
        final wpTerms = embedded['wp:term'] as List<dynamic>?;
        if (wpTerms != null && wpTerms.isNotEmpty) {
          // wp:term is an array of arrays - first array contains categories
          final categories = wpTerms.first as List<dynamic>?;
          if (categories != null && categories.isNotEmpty) {
            final firstCategory = categories.first as Map<String, dynamic>?;
            if (firstCategory != null) {
              final name = firstCategory['name'] as String?;
              if (name != null && name.isNotEmpty) {
                return name;
              }
            }
          }
        }
      }

      // Fallback to category ID if name not available
      final categoryIds = json['categories'] as List<dynamic>?;
      if (categoryIds != null && categoryIds.isNotEmpty) {
        return 'Category ${categoryIds.first}';
      }

      return '';
    } catch (_) {
      return '';
    }
  }

  static String _extractFeaturedImage(Map<String, dynamic> json) {
    try {
      final embedded = json['_embedded'] as Map<String, dynamic>?;
      if (embedded == null) return '';

      final mediaList = embedded['wp:featuredmedia'] as List<dynamic>?;
      if (mediaList == null || mediaList.isEmpty) return '';

      final media = mediaList.first as Map<String, dynamic>?;
      if (media == null) return '';

      final sizes =
          (media['media_details'] as Map<String, dynamic>?)?['sizes']
              as Map<String, dynamic>?;
      if (sizes != null) {
        if (sizes.containsKey('medium_large')) {
          return (sizes['medium_large']
                  as Map<String, dynamic>?)?['source_url'] as String? ??
              '';
        }
        if (sizes.containsKey('full')) {
          return (sizes['full'] as Map<String, dynamic>?)?['source_url']
                  as String? ??
              '';
        }
      }

      return media['source_url'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_gmt': dateGmt.toIso8601String(),
      'guid': {'rendered': guid},
      'modified_gmt': modifiedGmt.toIso8601String(),
      'slug': slug,
      'status': status,
      'type': type,
      'category': category,
      'link': link,
      'title': {'rendered': title},
      'content': {'rendered': content},
      'excerpt': {'rendered': excerpt},
      'imageUrl': imageUrl,
    };
  }

  Article copyWith({
    int? id,
    DateTime? dateGmt,
    String? guid,
    DateTime? modifiedGmt,
    String? slug,
    String? status,
    String? type,
    String? category,
    String? link,
    String? title,
    String? content,
    String? excerpt,
    String? imageUrl,
  }) {
    return Article(
      id: id ?? this.id,
      dateGmt: dateGmt ?? this.dateGmt,
      guid: guid ?? this.guid,
      modifiedGmt: modifiedGmt ?? this.modifiedGmt,
      slug: slug ?? this.slug,
      status: status ?? this.status,
      type: type ?? this.type,
      category: category ?? this.category,
      link: link ?? this.link,
      title: title ?? this.title,
      content: content ?? this.content,
      excerpt: excerpt ?? this.excerpt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'Article(id: $id, title: $title, dateGmt: $dateGmt)';
  }
}
