class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://footrdc.com/wp-json';
  static const String wpApiPath = '/wp/v2';

  // Articles endpoints
  static const String postsEndpoint = '$baseUrl$wpApiPath/posts';

  // Editorial content
  static const String bonASavoirCategorySlug = 'bon-a-savoir';
  static const String editoCategorySlug = 'editorial';

  // Pagination defaults
  static const int defaultArticlesPerPage = 15;
}
