import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:foot_rdc/core/network/dio_client.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';
import 'package:foot_rdc/features/news/data/datasources/article_remote_datasource.dart';

part 'news_providers.g.dart';

/// Provider for the article remote data source
final articleRemoteDataSourceProvider = Provider<ArticleRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ArticleRemoteDataSourceImpl(dioClient);
});

/// Fetches articles from the API with pagination
@riverpod
Future<List<Article>> fetchArticles(Ref ref, String input) async {
  final dioClient = ref.watch(dioClientProvider);

  // Parse the input string to extract query parameters
  final params = Uri.splitQueryString(input);
  final queryParams = <String, dynamic>{
    '_embed': true,
  };

  for (final entry in params.entries) {
    // Convert numeric strings to integers for page and per_page
    if (entry.key == 'page' || entry.key == 'per_page') {
      queryParams[entry.key] = int.tryParse(entry.value) ?? entry.value;
    } else {
      queryParams[entry.key] = entry.value;
    }
  }

  final response = await dioClient.get<List<dynamic>>(
    '${ApiConstants.wpApiPath}/posts',
    queryParameters: queryParams,
  );

  final List<dynamic> jsonList = response.data ?? [];
  return jsonList.map((j) => Article.fromJson(j)).toList();
}

/// Searches articles from the API
@riverpod
Future<List<Article>> searchArticles(Ref ref, String searchName) async {
  final dioClient = ref.watch(dioClientProvider);

  // Parse the search input string to extract query parameters
  final params = Uri.splitQueryString(searchName);
  final queryParams = <String, dynamic>{
    '_embed': true,
  };

  for (final entry in params.entries) {
    if (entry.key == 'page' || entry.key == 'per_page') {
      queryParams[entry.key] = int.tryParse(entry.value) ?? entry.value;
    } else {
      queryParams[entry.key] = entry.value;
    }
  }

  final response = await dioClient.get<List<dynamic>>(
    '${ApiConstants.wpApiPath}/posts',
    queryParameters: queryParams,
  );

  final List<dynamic> jsonList = response.data ?? [];
  return jsonList.map((j) => Article.fromJson(j)).toList();
}
