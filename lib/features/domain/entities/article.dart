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

  Article({
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
      id: json['id'],
      dateGmt: DateTime.parse(json['date_gmt']),
      guid: json['guid']?['rendered'] ?? '',
      modifiedGmt: DateTime.parse(json['modified_gmt']),
      slug: json['slug'] ?? '',
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      category: json['class_list']?['7'] ?? '',
      link: json['link'] ?? '',
      title: json['title']?['rendered'] ?? '',
      content: json['content']?['rendered'] ?? '',
      excerpt: json['excerpt']?['rendered'] ?? '',
      imageUrl: json['jetpack_featured_media_url'] ?? '',
    );
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
      'jetpack_featured_media_url': imageUrl,
    };
  }

  /// copyWith method
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
    String? featuredImage,
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
      imageUrl: featuredImage ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'Article(id: $id, slug: $slug, title: $title, link: $link)';
  }
}
