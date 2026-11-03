# API migration matrix

| Feature | Current source | RDC Football replacement | Migration status | Tests |
|---|---|---|---|---|
| Fixtures list (Groupe A/B, Play-off) | SportsPress `events` | `matches?view=fixtures`, `matches/upcoming`, `group_id`, `stage_id` | Done | contract, widget |
| Results list | SportsPress `events` | `matches?view=results`, `matches/finished` | Done | contract, widget |
| Match card and detail | SportsPress `events` | `matches/{id}`, `matches/{id}/events` | Done | contract, widget |
| Standings | SportsPress `tables` | `standings` joined with `stages`, `groups`, `teams` | Done | contract, widget |
| Hard-coded league and season IDs | `ApiConstants` | `competitions/1/seasons`, `stages`, `groups` | Done, constants removed | contract |
| Crests in football screens | SportsPress logo URLs | `home_logo`, `away_logo`, `logo_url` | Done; initials when null | contract, widget |

`SPORTSPRESS_USAGE_REMAINING: 0` in `lib/` (grep for `sportspress`, `sp_event`, `eventsEndpoint`, `tablesEndpoint`).

## Article ↔ club (Production API since 3 Nov 2026)

| Feature | Source | Status | Tests |
|---|---|---|---|
| Club "Actualités" | `teams/{id}/news?limit=15&page=n`: id, title, url, published_at, excerpt, image, category, related_clubs | Branch `feat/article-clubs`; app not released yet | widget, device (Staging) |
| "Clubs liés" on articles | `related_clubs` on `/wp/v2/posts` | Branch `feat/article-clubs`; app not released yet | parsing, widget, device (Staging) |

## New capabilities now exposed

Clubs directory, club profile, club news, next match, squads, players, match events, live and today views, historical seasons, provisional labels.

Not used yet: `seasons/{id}/freshness`, `teams/{id}/statistics` (empty today), `match-center/view`.

## WordPress, unchanged

Posts, categories, authors, media, search: `/wp/v2`.
