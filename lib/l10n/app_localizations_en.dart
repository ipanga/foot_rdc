// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Foot RDC';

  @override
  String get home => 'Home';

  @override
  String get articles => 'Articles';

  @override
  String get matches => 'Matches';

  @override
  String get ranking => 'Ranking';

  @override
  String get saved => 'Saved';

  @override
  String get search => 'Search';

  @override
  String get searchArticles => 'Search articles...';

  @override
  String get noResults => 'No results found';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'An error occurred';

  @override
  String get retry => 'Retry';

  @override
  String get readMore => 'Read more';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select your preferred language';

  @override
  String get about => 'About';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get articleSavedSuccessfully => 'Article saved successfully';

  @override
  String get shareNotSupportedOnThisPlatform =>
      'Share not supported on this platform';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get articleLinkCopiedToClipboard => 'Article link copied to clipboard';

  @override
  String get unableToCopyLink => 'Unable to copy link';

  @override
  String get articleDetails => 'Article Details';

  @override
  String get noContentAvailable => 'No content available';

  @override
  String get savedArticles => 'Saved Articles';

  @override
  String get noSavedArticles => 'No saved articles';

  @override
  String get searchHintText => 'Enter search terms...';

  @override
  String get searchValidationError => 'Please enter a search term';

  @override
  String get noArticles => 'No articles found';

  @override
  String get noArticlesAvailable => 'No articles available';

  @override
  String get failedToLoadMoreArticles => 'Failed to load more articles';

  @override
  String get failedToRefreshArticles => 'Failed to refresh articles';

  @override
  String get matchResults => 'MATCH RESULTS';

  @override
  String get loadingMatches => 'Loading matches...';

  @override
  String get failedToLoadMatches => 'Failed to load matches';

  @override
  String failedToLoadMoreMatches(String error) {
    return 'Failed to load more matches: $error';
  }

  @override
  String failedToRefreshMatches(String error) {
    return 'Failed to refresh matches: $error';
  }

  @override
  String get connectionProblem =>
      'Connection problem. Pull to refresh or tap retry.';

  @override
  String get noMatchesFound => 'No matches found';

  @override
  String get pullToRefresh => 'Pull down to refresh';

  @override
  String get loadingMoreMatches => 'Loading more matches...';

  @override
  String get scrollForMoreMatches => 'Scroll down for more matches';

  @override
  String get leagueTable => 'League Table';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get noTeamsFound => 'No teams found';
}
