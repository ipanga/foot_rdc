import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FootballStrings {
  final Locale locale;
  const FootballStrings(this.locale);
  static FootballStrings of(BuildContext context) =>
      Localizations.of<FootballStrings>(context, FootballStrings) ??
      const FootballStrings(Locale('fr'));
  static const delegate = _FootballStringsDelegate();
  static const fr = {
    'competition': 'Linafoot',
    'competitions': 'Compétitions',
    'teams': 'Équipes',
    'today': "Aujourd'hui",
    'live': 'En direct',
    'upcoming': 'À venir',
    'finished': 'Terminés',
    'fixtures': 'Calendrier',
    'results': 'Résultats',
    'standings': 'Classement',
    'standingsEmpty': 'Classement en cours de vérification',
    'overview': 'Aperçu',
    'next': 'Prochain match',
    'recent': 'Derniers résultats',
    'squad': 'Effectif',
    'statistics': 'Statistiques',
    'match': 'Match',
    'empty': 'Aucune donnée disponible',
    'nextEmpty': 'Aucun prochain match disponible',
    'matchesEmpty': 'Aucun match disponible',
    'retry': 'Réessayer',
    'error': 'Impossible de charger les données. Vérifiez votre connexion.',
    'unavailable': 'Ces données ne sont pas encore disponibles.',
    'cached': 'Contenu en cache',
    'more': 'Afficher plus',
    'search': 'Rechercher une équipe',
    'partial': 'Données partielles',
    'squadPartial': 'Effectif partiel',
    'eventsPartial': 'Événements partiels',
    'eventsEmpty': 'Aucun événement disponible',
    'unverified': 'Données en cours de vérification',
    'stale': 'Mise à jour retardée',
    'livePending': 'Direct en cours de validation',
    'unknown': 'Statut indisponible',
    'scheduled': 'Programmé',
    'halftime': 'Mi-temps',
    'fulltime': 'Terminé',
    'postponed': 'Reporté',
    'cancelled': 'Annulé',
    'abandoned': 'Arrêté',
    'awarded': 'Décision administrative',
    'groupA': 'Groupe A',
    'groupB': 'Groupe B',
    'playoff': 'Playoff',
    'goal': 'But',
    'own_goal': 'But contre son camp',
    'penalty': 'Penalty',
    'yellow_card': 'Carton jaune',
    'red_card': 'Carton rouge',
    'substitution': 'Remplacement',
    'var': 'VAR',
    'event': 'Action',
    'goalkeepers': 'Gardiens',
    'defenders': 'Défenseurs',
    'midfielders': 'Milieux',
    'attackers': 'Attaquants',
    'others': 'Autres',
    'home': 'à domicile',
    'away': "à l'extérieur",
    'played': 'Matchs',
    'wins': 'Victoires',
    'draws': 'Nuls',
    'losses': 'Défaites',
    'goals_for': 'Buts pour',
    'goals_against': 'Buts contre',
    'clean_sheets': 'Clean sheets',
    'appearances': 'Apparitions',
    'starts': 'Titularisations',
    'minutes': 'Minutes',
    'goals': 'Buts',
    'assists': 'Passes décisives',
    'yellow_cards': 'Cartons jaunes',
    'red_cards': 'Cartons rouges',
    'position': 'Position',
    'points': 'Points',
    'firstHalf': 'Première période',
    'secondHalf': 'Deuxième période',
    'extraTime': 'Prolongation',
    'penalties': 'Tirs au but',
  };
  static const en = {
    'competition': 'Linafoot',
    'competitions': 'Competitions',
    'teams': 'Teams',
    'today': 'Today',
    'live': 'Live',
    'upcoming': 'Upcoming',
    'finished': 'Finished',
    'fixtures': 'Schedule',
    'results': 'Results',
    'standings': 'Standings',
    'standingsEmpty': 'Standings under review',
    'overview': 'Overview',
    'next': 'Next match',
    'recent': 'Recent results',
    'squad': 'Squad',
    'statistics': 'Statistics',
    'match': 'Match',
    'empty': 'No data available',
    'nextEmpty': 'No upcoming match available',
    'matchesEmpty': 'No matches available',
    'retry': 'Retry',
    'error': 'Unable to load data. Check your connection.',
    'unavailable': 'This data is not available yet.',
    'cached': 'Cached content',
    'more': 'Show more',
    'search': 'Search teams',
    'partial': 'Partial data',
    'squadPartial': 'Partial squad',
    'eventsPartial': 'Partial events',
    'eventsEmpty': 'No events available',
    'unverified': 'Data under review',
    'stale': 'Update delayed',
    'livePending': 'Live validation pending',
    'unknown': 'Status unavailable',
    'scheduled': 'Scheduled',
    'halftime': 'Half-time',
    'fulltime': 'Full-time',
    'postponed': 'Postponed',
    'cancelled': 'Cancelled',
    'abandoned': 'Abandoned',
    'awarded': 'Administrative decision',
    'groupA': 'Group A',
    'groupB': 'Group B',
    'playoff': 'Playoff',
    'goal': 'Goal',
    'own_goal': 'Own goal',
    'penalty': 'Penalty',
    'yellow_card': 'Yellow card',
    'red_card': 'Red card',
    'substitution': 'Substitution',
    'var': 'VAR',
    'event': 'Event',
    'goalkeepers': 'Goalkeepers',
    'defenders': 'Defenders',
    'midfielders': 'Midfielders',
    'attackers': 'Attackers',
    'others': 'Others',
    'home': 'at home',
    'away': 'away',
    'played': 'Matches',
    'wins': 'Wins',
    'draws': 'Draws',
    'losses': 'Losses',
    'goals_for': 'Goals for',
    'goals_against': 'Goals against',
    'clean_sheets': 'Clean sheets',
    'appearances': 'Appearances',
    'starts': 'Starts',
    'minutes': 'Minutes',
    'goals': 'Goals',
    'assists': 'Assists',
    'yellow_cards': 'Yellow cards',
    'red_cards': 'Red cards',
    'position': 'Position',
    'points': 'Points',
    'firstHalf': 'First half',
    'secondHalf': 'Second half',
    'extraTime': 'Extra time',
    'penalties': 'Penalties',
  };
  String get language => locale.languageCode == 'en' ? 'en' : 'fr';
  String period(String value) => switch (value.toLowerCase()) {
    'first_half' || '1st-half' || '1h' => t('firstHalf'),
    'second_half' || '2nd-half' || '2h' => t('secondHalf'),
    'extra_time' || 'extra-time' => t('extraTime'),
    'penalties' => t('penalties'),
    _ => '',
  };
  String t(String key) => (language == 'en' ? en : fr)[key] ?? t('empty');
  String status(String value) => t(
    value == 'finished'
        ? 'fulltime'
        : [
            'scheduled',
            'live',
            'halftime',
            'postponed',
            'cancelled',
            'abandoned',
            'awarded',
          ].contains(value)
        ? value
        : 'unknown',
  );
  String phase(FootballPhaseLike phase) => phase.type == 'playoff'
      ? t('playoff')
      : phase.name == 'Group A'
      ? t('groupA')
      : phase.name == 'Group B'
      ? t('groupB')
      : phase.name;
  String metric(String key) {
    for (final side in ['home', 'away']) {
      if (key.endsWith('_$side')) {
        return '${metric(key.substring(0, key.length - side.length - 1))} ${t(side)}';
      }
    }
    return fr.containsKey(key) ? t(key) : t('statistics');
  }

  String role(String role) => t(switch (role.toLowerCase()) {
    'goalkeeper' => 'goalkeepers',
    'defender' => 'defenders',
    'midfielder' => 'midfielders',
    'attacker' || 'forward' => 'attackers',
    _ => 'others',
  });
}

typedef FootballPhaseLike = ({String name, String type});

class _FootballStringsDelegate extends LocalizationsDelegate<FootballStrings> {
  const _FootballStringsDelegate();
  @override
  bool isSupported(Locale locale) => ['fr', 'en'].contains(locale.languageCode);
  @override
  Future<FootballStrings> load(Locale locale) =>
      SynchronousFuture(FootballStrings(locale));
  @override
  bool shouldReload(_FootballStringsDelegate old) => false;
}
