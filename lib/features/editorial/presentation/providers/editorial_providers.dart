import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foot_rdc/core/constants/api_constants.dart';
import 'package:foot_rdc/core/network/dio_client.dart';
import 'package:foot_rdc/features/news/domain/entities/article.dart';

/// Resolves the WordPress category slug `bon-a-savoir` to its numeric ID.
/// Categories rarely change, so the result is cached for the session by
/// Riverpod's [FutureProvider]. Returns `null` if no matching category exists
/// (the category was deleted or renamed on the WP side).
final editorialCategoryIdProvider = FutureProvider<int?>((ref) async {
  final dioClient = ref.watch(dioClientProvider);
  final response = await dioClient.get<List<dynamic>>(
    '${ApiConstants.wpApiPath}/categories',
    queryParameters: {
      'slug': ApiConstants.bonASavoirCategorySlug,
      '_fields': 'id,slug',
    },
  );
  final list = response.data ?? const <dynamic>[];
  if (list.isEmpty) return null;
  final first = list.first as Map<String, dynamic>;
  return first['id'] as int?;
});

/// Identifies a single page request for editorial articles. Used as the
/// family key for [fetchEditorialArticlesProvider].
class EditorialPageRequest {
  final int categoryId;
  final int page;
  final int perPage;

  const EditorialPageRequest({
    required this.categoryId,
    required this.page,
    required this.perPage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorialPageRequest &&
          categoryId == other.categoryId &&
          page == other.page &&
          perPage == other.perPage;

  @override
  int get hashCode => Object.hash(categoryId, page, perPage);
}

/// Fetches a single page of editorial articles for a given category.
final fetchEditorialArticlesProvider =
    FutureProvider.family<List<Article>, EditorialPageRequest>((ref, request) async {
  final dioClient = ref.watch(dioClientProvider);
  final response = await dioClient.get<List<dynamic>>(
    '${ApiConstants.wpApiPath}/posts',
    queryParameters: {
      '_embed': true,
      'categories': request.categoryId,
      'page': request.page,
      'per_page': request.perPage,
    },
  );
  final list = response.data ?? const <dynamic>[];
  return list.map((j) => Article.fromJson(j)).toList();
});
