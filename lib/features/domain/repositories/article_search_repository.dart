import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/features/domain/entities/article.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'article_search_repository.g.dart';

@riverpod
ArticleSearchRepository articleSearchRepository(Ref ref) {
  return ArticleSearchRepository(ref);
}

class ArticleSearchRepository {
  final Ref ref;
  ArticleSearchRepository(this.ref);

  /// Fetch a page of articles from the WordPress REST API.
  Future<List<Article>> searchArticlesData(String searchName) async {
    final url = 'https://footrdc.com/wp-json/wp/v2/posts?$searchName';

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
