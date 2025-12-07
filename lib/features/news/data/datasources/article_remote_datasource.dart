import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';

abstract class ArticleRemoteDataSource {
  Future<List<Article>> fetchArticles(int page, int perPage);
  Future<List<Article>> searchArticles(String query, int page, int perPage);
}

class ArticleRemoteDataSourceImpl implements ArticleRemoteDataSource {
  final http.Client client;

  ArticleRemoteDataSourceImpl(this.client);

  @override
  Future<List<Article>> fetchArticles(int page, int perPage) async {
    final url = Uri.parse(
      '${ApiConstants.postsEndpoint}?page=$page&per_page=$perPage&_embed',
    );

    final response = await client.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Article.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load articles: ${response.statusCode}');
    }
  }

  @override
  Future<List<Article>> searchArticles(String query, int page, int perPage) async {
    final url = Uri.parse(
      '${ApiConstants.postsEndpoint}?page=$page&per_page=$perPage&search=$query&_embed',
    );

    final response = await client.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Article.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search articles: ${response.statusCode}');
    }
  }
}
