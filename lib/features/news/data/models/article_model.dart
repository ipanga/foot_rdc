import 'package:hive/hive.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';

part 'article_model.g.dart';

@HiveType(typeId: 0)
class ArticleModel {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final DateTime dateGmt;

  @HiveField(2)
  final String guid;

  @HiveField(3)
  final DateTime modifiedGmt;

  @HiveField(4)
  final String slug;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final String type;

  @HiveField(7)
  final String category;

  @HiveField(8)
  final String link;

  @HiveField(9)
  final String title;

  @HiveField(10)
  final String content;

  @HiveField(11)
  final String excerpt;

  @HiveField(12)
  final String imageUrl;

  const ArticleModel({
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

  factory ArticleModel.fromEntity(Article article) {
    return ArticleModel(
      id: article.id,
      dateGmt: article.dateGmt,
      guid: article.guid,
      modifiedGmt: article.modifiedGmt,
      slug: article.slug,
      status: article.status,
      type: article.type,
      category: article.category,
      link: article.link,
      title: article.title,
      content: article.content,
      excerpt: article.excerpt,
      imageUrl: article.imageUrl,
    );
  }

  Article toEntity() {
    return Article(
      id: id,
      dateGmt: dateGmt,
      guid: guid,
      modifiedGmt: modifiedGmt,
      slug: slug,
      status: status,
      type: type,
      category: category,
      link: link,
      title: title,
      content: content,
      excerpt: excerpt,
      imageUrl: imageUrl,
    );
  }
}
