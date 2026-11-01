# 01 — UX audit

## Current navigation

```text
Accueil (news, drawer, search)
À Savoir (category list)
Matchs → Play-off | Groupe A | Groupe B
Classement → Play-off | Groupe A | Groupe B
Enregistrés
```

## Proposed navigation

```text
Accueil   hero, match strip, news, Linafoot snapshot
Matchs    Aujourd'hui | À venir | Résultats, live on top
Linafoot  Aperçu | Calendrier | Résultats | Classements | Clubs, with season selector
Édito     WordPress category `editorial`
Plus      Clubs, Favoris, Enregistrés, Bon à savoir, Recherche, Réglages
```

Reason: football lives in one hub, the daily match view stays one tap away, Édito gets its required tab, and saved articles and settings move to Plus.

## SportsPress dependency map

| Caller | Endpoint |
|---|---|
| `features/matches` data source and providers | `sportspress/v2/events` |
| `features/rankings` data source and providers | `sportspress/v2/tables` |
| `core/constants/api_constants.dart` | IDs and endpoints |

## RDC Football opportunities

Match events timeline, today and live views, club pages, squads, player profiles, historical season, calculated standings, provisional labels, canonical crests.

## Screen inventory

Home, Matchs, match detail, Linafoot hub (5 tabs), club directory, club detail (6 tabs), player detail, Édito list, article detail, search, favorites, saved, À savoir, settings, plus loading, empty, offline and error states for each.

## Design direction

Dense and calm: white and slate surfaces, hairline dividers instead of cards in lists, FootRDC red reserved for active state, live state and key actions. Status is always text plus colour. 44 pt minimum targets.
