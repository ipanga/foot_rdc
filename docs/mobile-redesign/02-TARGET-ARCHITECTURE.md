# 02 — Target architecture

```text
RdcFootballApiClient (Dio, allowlist, TTL cache)
  → JSON
  → football_mappers.dart (tolerant; a malformed row is skipped, never a crash)
  → domain models (Match, Club, StandingRow, ...)
  → FootballRepository
  → Riverpod providers (stale-while-revalidate)
  → screens and widgets
```

Screens never read JSON. WordPress stays in `features/news` and `features/editorial`.

## Season context

`selectedSeasonProvider` holds the season chosen in the Linafoot hub; default is the API's current season. Everything in the hub derives from it, so data can never mix seasons.

## Cache

Metadata and clubs 1 h, standings 2 min, matches 2 min, live never cached. Fresh data replaces stale data on screen; if the network fails, the last copy shows with a "données enregistrées" label for up to 24 h.

## Live

Polling every 30 s only while a live match is visible and the app is foregrounded; stops when the server reports the match is over.

## Deep links

`footrdc://` plus parser for article, club, match, Linafoot and standings; https app links need server files and are a later Production task.
