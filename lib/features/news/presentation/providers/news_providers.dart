import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/data/datasources/article_remote_datasource.dart';

part 'news_providers.g.dart';

/// Provider for the article remote data source
final articleRemoteDataSourceProvider = Provider<ArticleRemoteDataSource>((ref) {
  return ArticleRemoteDataSourceImpl(http.Client());
});

/// Fetches articles from the API with pagination
@riverpod
Future<List<Article>> fetchArticles(Ref ref, String input) async {
  final uri = Uri.parse('${ApiConstants.postsEndpoint}?$input&_embed');
  final response = await http.get(uri, headers: {'Accept': 'application/json'});

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((j) => Article.fromJson(j)).toList();
  } else {
    throw Exception('Failed to load articles');
  }
}

/// Searches articles from the API
@riverpod
Future<List<Article>> searchArticles(Ref ref, String searchName) async {
  final uri = Uri.parse('${ApiConstants.postsEndpoint}?$searchName&_embed');
  final response = await http.get(uri, headers: {'Accept': 'application/json'});

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((j) => Article.fromJson(j)).toList();
  } else {
    throw Exception('Failed to search articles');
  }
}
