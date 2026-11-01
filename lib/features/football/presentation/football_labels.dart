import 'package:intl/intl.dart';

import '../domain/models.dart';

/// French wording for server values. Presentation only: stored values are never changed.
String phaseLabel(String name) => switch (name.trim().toLowerCase()) {
  'regular season' => 'Saison régulière',
  'group stage' => 'Phase de groupes',
  'championship round' || 'play-offs' || 'playoffs' || 'play-off' => 'Play-offs',
  'group a' => 'Groupe A',
  'group b' => 'Groupe B',
  _ => name,
};

String statusLabel(MatchStatus status) => switch (status) {
  MatchStatus.scheduled => 'À venir',
  MatchStatus.live => 'En direct',
  MatchStatus.halftime => 'Mi-temps',
  MatchStatus.finished => 'Terminé',
  MatchStatus.postponed => 'Reporté',
  MatchStatus.cancelled => 'Annulé',
  MatchStatus.abandoned => 'Arrêté',
  MatchStatus.awarded => 'Décision administrative',
  MatchStatus.interrupted => 'Interrompu',
  MatchStatus.unknown => '',
};

String positionLabel(String value) => switch (value.toLowerCase()) {
  'goalkeeper' => 'Gardien',
  'defender' => 'Défenseur',
  'midfielder' => 'Milieu',
  'attacker' || 'forward' => 'Attaquant',
  _ => value,
};

const positionGroups = [
  ('Goalkeeper', 'Gardiens'),
  ('Defender', 'Défenseurs'),
  ('Midfielder', 'Milieux'),
  ('Attacker', 'Attaquants'),
];

/// Times are shown in the device's zone; the server sends UTC.
String kickoffTime(DateTime? utc) => utc == null ? '--:--' : DateFormat('HH:mm', 'fr').format(utc.toLocal());
String dayLabel(DateTime? utc, {DateTime? now}) {
  if (utc == null) return 'Date à confirmer';
  final local = utc.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  final days = DateTime(
    local.year,
    local.month,
    local.day,
  ).difference(DateTime(today.year, today.month, today.day)).inDays;
  if (days == 0) return "Aujourd'hui";
  if (days == 1) return 'Demain';
  if (days == -1) return 'Hier';
  final text = DateFormat('EEEE d MMMM', 'fr').format(local);
  return text[0].toUpperCase() + text.substring(1);
}

String shortDate(DateTime? utc) => utc == null ? '' : DateFormat('d MMM', 'fr').format(utc.toLocal());
int? ageAt(DateTime? birth, DateTime now) {
  if (birth == null) return null;
  var years = now.year - birth.year;
  if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) years--;
  return years > 10 && years < 60 ? years : null;
}
