class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://footrdc.com/wp-json';
  static const String wpApiPath = '/wp/v2';
  static const String sportsApiPath = '/sportspress/v2';

  // Articles endpoints
  static const String postsEndpoint = '$baseUrl$wpApiPath/posts';

  // Matches endpoint
  static const String eventsEndpoint = '$baseUrl$sportsApiPath/events';

  // Rankings endpoint
  static const String tablesEndpoint = '$baseUrl$sportsApiPath/tables';

  // League and Season IDs
  static const int currentSeasonId = 821;
  static const int groupeALeagueId = 546;
  static const int groupeBLeagueId = 547;
  static const int playOffLeagueId = 552;

  // Pagination defaults
  static const int defaultArticlesPerPage = 15;
  static const int defaultMatchesPerPage = 10;
}
