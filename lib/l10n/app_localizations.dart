import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Foot RDC'**
  String get appTitle;

  /// Home page label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Articles section label
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get articles;

  /// Matches section label
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matches;

  /// Ranking/Classification section label
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get ranking;

  /// Saved articles section label
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// Search action label
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Search articles placeholder
  ///
  /// In en, this message translates to:
  /// **'Search articles...'**
  String get searchArticles;

  /// Message when no search results
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get error;

  /// Retry action label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Read more action
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// Settings page label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Subtitle text for language selection
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get selectLanguage;

  /// About page label
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// French language option
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Message when article is saved to bookmarks
  ///
  /// In en, this message translates to:
  /// **'Article saved successfully'**
  String get articleSavedSuccessfully;

  /// Message when share feature is not available on the platform
  ///
  /// In en, this message translates to:
  /// **'Share not supported on this platform'**
  String get shareNotSupportedOnThisPlatform;

  /// Button label to copy article link
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// Message when article link is copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Article link copied to clipboard'**
  String get articleLinkCopiedToClipboard;

  /// Error message when unable to copy link to clipboard
  ///
  /// In en, this message translates to:
  /// **'Unable to copy link'**
  String get unableToCopyLink;

  /// Title for article details page when no title is available
  ///
  /// In en, this message translates to:
  /// **'Article Details'**
  String get articleDetails;

  /// Message when article has no content
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get noContentAvailable;

  /// Title for saved articles page
  ///
  /// In en, this message translates to:
  /// **'Saved Articles'**
  String get savedArticles;

  /// Message when no articles are saved
  ///
  /// In en, this message translates to:
  /// **'No saved articles'**
  String get noSavedArticles;

  /// Hint text for the search input field
  ///
  /// In en, this message translates to:
  /// **'Enter search terms...'**
  String get searchHintText;

  /// Validation error when search field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a search term'**
  String get searchValidationError;

  /// Message when no articles are available
  ///
  /// In en, this message translates to:
  /// **'No articles found'**
  String get noArticles;

  /// Message when no articles are available to display
  ///
  /// In en, this message translates to:
  /// **'No articles available'**
  String get noArticlesAvailable;

  /// Error message when loading more articles fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load more articles'**
  String get failedToLoadMoreArticles;

  /// Error message when refreshing articles fails
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh articles'**
  String get failedToRefreshArticles;

  /// Title for match results page
  ///
  /// In en, this message translates to:
  /// **'MATCH RESULTS'**
  String get matchResults;

  /// Loading matches message
  ///
  /// In en, this message translates to:
  /// **'Loading matches...'**
  String get loadingMatches;

  /// Error message when loading matches fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load matches'**
  String get failedToLoadMatches;

  /// Error message when loading more matches fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load more matches: {error}'**
  String failedToLoadMoreMatches(String error);

  /// Error message when refreshing matches fails
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh matches: {error}'**
  String failedToRefreshMatches(String error);

  /// Connection problem message
  ///
  /// In en, this message translates to:
  /// **'Connection problem. Pull to refresh or tap retry.'**
  String get connectionProblem;

  /// Message when no matches are found
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noMatchesFound;

  /// Message to indicate pull to refresh action
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get pullToRefresh;

  /// Loading more matches message
  ///
  /// In en, this message translates to:
  /// **'Loading more matches...'**
  String get loadingMoreMatches;

  /// Message to indicate scrolling for more matches
  ///
  /// In en, this message translates to:
  /// **'Scroll down for more matches'**
  String get scrollForMoreMatches;

  /// Title for league table page
  ///
  /// In en, this message translates to:
  /// **'League Table'**
  String get leagueTable;

  /// Message when no data is available to display
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// Message when no teams are found in the ranking
  ///
  /// In en, this message translates to:
  /// **'No teams found'**
  String get noTeamsFound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
