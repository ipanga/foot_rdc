import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:foot_rdc/core/network/dio_client.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';

abstract class ArticleRemoteDataSource {
  Future<List<Article>> fetchArticles(int page, int perPage);
  Future<List<Article>> searchArticles(String query, int page, int perPage);
}

class ArticleRemoteDataSourceImpl implements ArticleRemoteDataSource {
  final DioClient _dioClient;

  ArticleRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<Article>> fetchArticles(int page, int perPage) async {
    final response = await _dioClient.get<List<dynamic>>(
      '${ApiConstants.wpApiPath}/posts',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        '_embed': true,
      },
    );

    final List<dynamic> jsonList = response.data ?? [];
    return jsonList.map((json) => Article.fromJson(json)).toList();
  }

  @override
  Future<List<Article>> searchArticles(String query, int page, int perPage) async {
    final response = await _dioClient.get<List<dynamic>>(
      '${ApiConstants.wpApiPath}/posts',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        'search': query,
        '_embed': true,
      },
    );

    final List<dynamic> jsonList = response.data ?? [];
    return jsonList.map((json) => Article.fromJson(json)).toList();
  }
}
