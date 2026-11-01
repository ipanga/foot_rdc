# API migration matrix

| Feature | Current source | RDC Football replacement | Migration status | Tests |
|---|---|---|---|---|
| Fixtures list (Groupe A/B, Play-off) | SportsPress `events` | `matches/upcoming`, `matches?season_id&group_id` | Not started | — |
| Results list | SportsPress `events` | `matches/finished`, `matches?status=finished` | Not started | — |
| Match card and detail | SportsPress `events` | `matches/{id}`, `matches/{id}/events` | Not started | — |
| Standings | SportsPress `tables` | `standings?season_id&stage_id&group_id` | Not started | — |
| Hard-coded league and season IDs | `ApiConstants` | `competitions/1`, `seasons`, `stages`, `groups` | Not started | — |
| Crests in football screens | SportsPress logo URLs | `home_logo`, `away_logo`, `logo_url`, `crest_url` | Not started | — |

## New capabilities not exposed by the released app

Clubs directory, club profile, club news, next match, squads, players, match events, live and today views, historical seasons, freshness, data quality labels.

## WordPress, unchanged

Posts, categories, authors, media, search: `/wp/v2`.
