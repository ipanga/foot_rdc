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

  // The currently active competition phase. Tabs in Matchs / Classement open
  // on this league by default. Bump this when the phase rotates (e.g. from
  // group stage back to a future Play-Off).
  static const int currentPhaseLeagueId = playOffLeagueId;

  // Editorial content
  static const String bonASavoirCategorySlug = 'bon-a-savoir';

  // Pagination defaults
  static const int defaultArticlesPerPage = 15;
  static const int defaultMatchesPerPage = 10;
}
