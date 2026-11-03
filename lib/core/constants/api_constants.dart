class ApiConstants {
  ApiConstants._();

  /// Production by default. `--dart-define=FOOTRDC_WP_BASE=…` is for local Staging checks only; release lanes pass none.
  static const String baseUrl = String.fromEnvironment('FOOTRDC_WP_BASE', defaultValue: 'https://footrdc.com/wp-json');
  static const String wpApiPath = '/wp/v2';

  // Articles endpoints
  static const String postsEndpoint = '$baseUrl$wpApiPath/posts';

  // Editorial content
  static const String bonASavoirCategorySlug = 'bon-a-savoir';
  static const String editoCategorySlug = 'editorial';

  // Pagination defaults
  static const int defaultArticlesPerPage = 15;
}
