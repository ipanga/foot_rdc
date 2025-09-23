import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'article_web_repository.g.dart';

// Riverpod provider factory returning ArticleRepository.
@riverpod
ArticleWebRepository articleRepository(Ref ref) {
  return ArticleWebRepository(ref);
}

class ArticleWebRepository {
  final Ref ref;
  ArticleWebRepository(this.ref);

  /// Fetch a page of articles from the WordPress REST API.
  ///
  /// The `pagination` parameter should be a single query string containing
  /// both page number and per_page, e.g. "page=1&per_page=15".
  Future<List<Article>> fetchArticlesData(String pagination) async {
    final url = 'https://footrdc.com/wp-json/wp/v2/posts?$pagination';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load articles (status ${response.statusCode})',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected response format: expected a JSON array');
    }

    return decoded
        .map<Article>((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
