// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Foot RDC';

  @override
  String get home => 'Accueil';

  @override
  String get articles => 'Articles';

  @override
  String get matches => 'Matchs';

  @override
  String get ranking => 'Classement';

  @override
  String get saved => 'Enregistrés';

  @override
  String get search => 'Recherche';

  @override
  String get searchArticles => 'Rechercher des articles...';

  @override
  String get noResults => 'Aucun résultat trouvé';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Une erreur s\'est produite';

  @override
  String get retry => 'Réessayer';

  @override
  String get readMore => 'Lire la suite';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionnez votre langue préférée';

  @override
  String get about => 'À propos';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get articleSavedSuccessfully => 'Article enregistré avec succès';

  @override
  String get shareNotSupportedOnThisPlatform =>
      'Partage non supporté sur cette plateforme';

  @override
  String get copyLink => 'Copier le lien';

  @override
  String get articleLinkCopiedToClipboard =>
      'Lien de l\'article copié dans le presse-papiers';

  @override
  String get unableToCopyLink => 'Impossible de copier le lien';

  @override
  String get articleDetails => 'Détails de l\'article';

  @override
  String get noContentAvailable => 'Aucun contenu disponible';

  @override
  String get savedArticles => 'Articles Enregistrés';

  @override
  String get noSavedArticles => 'Aucun article enregistré';

  @override
  String get searchHintText => 'Saisir les termes de recherche...';

  @override
  String get searchValidationError => 'Veuillez saisir un terme de recherche';

  @override
  String get noArticles => 'Aucun article trouvé';

  @override
  String get noArticlesAvailable => 'No articles available';

  @override
  String get failedToLoadMoreArticles =>
      'Échec du chargement d\'articles supplémentaires';

  @override
  String get failedToRefreshArticles =>
      'Échec de l\'actualisation des articles';

  @override
  String get matchResults => 'RÉSULTATS MATCHS';

  @override
  String get loadingMatches => 'Chargement des matchs...';

  @override
  String get failedToLoadMatches => 'Échec du chargement des matchs';

  @override
  String failedToLoadMoreMatches(String error) {
    return 'Échec du chargement de plus de matchs : $error';
  }

  @override
  String failedToRefreshMatches(String error) {
    return 'Échec de l\'actualisation des matchs : $error';
  }

  @override
  String get connectionProblem =>
      'Problème de connexion. Tirez pour actualiser ou appuyez sur réessayer.';

  @override
  String get noMatchesFound => 'Aucun match trouvé';

  @override
  String get pullToRefresh => 'Tirez vers le bas pour actualiser';

  @override
  String get loadingMoreMatches => 'Chargement de plus de matchs...';

  @override
  String get scrollForMoreMatches =>
      'Faites défiler vers le bas pour plus de matchs';

  @override
  String get leagueTable => 'Tableau de Classement';

  @override
  String get noDataAvailable => 'Aucune donnée disponible';

  @override
  String get noTeamsFound => 'Aucune équipe trouvée';
}
