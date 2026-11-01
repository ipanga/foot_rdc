# FootRDC Flutter: RDC Football migration and redesign

Final report, 1 Nov 2026. Branch `feat/rdc-football-mobile-redesign`, code commit `5f79298`, version `5.12.10+30`.

The app now runs on the RDC Football API with five tabs, including Édito. Every automated test and all seven device runs pass on the same commit. It has not been tried on a physical phone or during a live match, and nothing was uploaded to Apple or Google.

## Status

| Item | Status |
|---|---|
| RDC FOOTBALL API MIGRATION | PASS |
| SPORTSPRESS FOOTBALL DEPENDENCY | REMOVED |
| HOME | PASS |
| MATCH CENTER | PARTIAL: finished matches verified; a live match was not available |
| FIXTURES | PASS |
| RESULTS | PASS |
| STANDINGS | PASS |
| LINAFOOT HUB | PASS |
| CLUBS | PASS |
| PLAYERS / SQUADS | PARTIAL: squads exist only for imported clubs |
| ÉDITO TAB | PASS |
| SEARCH | PASS |
| FAVORITES | PARTIAL: tested in widget tests, not on a device |
| IOS QA | PASS |
| ANDROID QA | PASS |
| API CONTRACT TESTS | PASS |
| REGRESSION TESTS | PASS |
| PERFORMANCE | PARTIAL: no profile build on a physical phone |
| RELEASE AUTOMATION PLAN | READY |
| TESTFLIGHT UPLOAD | NOT EXECUTED |
| GOOGLE PLAY UPLOAD | NOT EXECUTED |

`SPORTSPRESS_USAGE_REMAINING: 0` across `lib`, `test`, `integration_test` and `tool`. The word remains only in documents describing the past.

## Architecture

| | Before | After |
|---|---|---|
| Football source | SportsPress REST | RDC Football REST |
| Layers | Screens close to raw responses | Client, mappers, domain, repository, Riverpod state, UI |
| Seasons | Fixed in code | Discovered from the API, current and past |
| Cache | Memory only | Saved on device, shown first, then refreshed |
| Standings | Read from SportsPress | Read from the server, never calculated in the app |
| Navigation | Navigator, no router | Unchanged, plus deep links |

The app was evolved rather than rewritten. Articles, saved articles, ads and theming stayed in place.

## Final navigation

Accueil, Matchs, Linafoot, Édito, Plus.

## API mapping

Full table: `API_MIGRATION_MATRIX.md`.

Remaining WordPress use is articles, categories and article search through `/wp/v2`, which is intended. Édito reads the WordPress category with slug `editorial`, resolved at run time.

## Screens

| Tab | Screens |
|---|---|
| Accueil | À la Une, match strip, news, Linafoot snapshot |
| Matchs | Aujourd'hui, À venir, Résultats, match detail |
| Linafoot | Aperçu, Calendrier, Résultats, Classements, Clubs, season picker |
| Édito | Article list, article |
| Plus | Clubs, clubs suivis, recherche, articles enregistrés, Bon à savoir, thème et notifications |
| Shared | Club (Aperçu, Actualités, Résultats, Calendrier, Classement, Effectif), player |

New for readers: match events, past seasons, club pages, squads, player pages, followed clubs, search across articles, clubs and players, and deep links.

Design changes: lighter tab bar, denser match rows, neutral day headers, compact and full standings, initials when a club has no crest, and intentional loading, empty and error states in French.

## Caching

Football responses are saved on the device and shown immediately, then refreshed. After 2 minutes matches and tables count as old; other data lasts longer. When a refresh fails, saved data stays on screen with the notice "Données enregistrées. Actualisation impossible pour le moment." Data older than 24 hours is not shown offline. Live polling runs every 30 seconds, stops when a match ends, and pauses in the background.

## Device QA

All on commit `5f79298`.

| Device | Screens | Result |
|---|---|---|
| iPhone 18 Pro | `docs/mobile-redesign/screens/after/` (`ios-*`) | 20 of 20 steps |
| Small iPhone, dark mode | `screens/small-dark/` | 20 of 20 steps |
| iPad, portrait | `screens/ipad/` | 20 of 20 steps |
| Pixel 8 Pro | `screens/after/` (`android-*`) | 20 of 20 steps |
| Android 360x640 dp, text 130% | `screens/android-narrow-large-text/` | 20 of 20 steps |
| iOS and Android failure states | `screens/states/` | 6 of 6 states each |

0 exceptions and 0 layout overflows in those runs. Before screens are in `screens/baseline/`.

Unit and widget tests: 66 passed. Analyzer: 0 errors, 0 warnings, 33 style infos. Details: `TEST_MATRIX.md`.

### Bugs found by device runs and fixed

- Club and player search never matched. The screen passed its URL string instead of the search term. Unit tests missed it because they called the widget with a clean term.
- Tab labels were cut off at large system text.
- Club search overflowed on a small screen with a tall keyboard. The ad and tabs now hide while typing, and search scrolls with the list.
- A sponsor carousel showed an empty box because its images are placeholders. It is hidden until real images exist.
- Result rows in lists without day headers showed no date.
- Club news left the app instead of opening the article inside it.

## Performance

| Measure | Result |
|---|---|
| Main API responses, single request from this Mac | 0.63 to 1.35 s |
| Compressed response size | 168 B to 2.3 KB |
| Reopening with saved data | Shown without a spinner, then refreshed |

Startup time and frame rates were not measured, because profile builds do not run on simulators or emulators. Debug timings would not be meaningful. This needs a physical phone.

## Push audit

Delivery stays on OneSignal. Tapping a notification opens the matching article, club, match or standings through the same deep-link path. The permission request no longer blocks the first frame, but it still appears at launch. No football notification was added, so nothing new can be noisy. Firebase is initialised only for the existing messaging setup. There is no analytics SDK, and none was added.

## Limitations

1. No live match was observed. The first real test is the fixtures on 4 Nov 12:00 UTC.
2. Squads are empty for clubs not yet imported, for example Blessing, and the app says so. Filling them depends on the separate decision to extend squad imports.
3. A Production table hidden on the website has no public REST flag, so the app cannot honour that setting. Tables are shown with the provisional note.
4. Some clubs have no crest and show initials. Crest data on Production changed during QA: AF Ufalya Simba briefly returned an Étoile du Congo crest, then none, while Butras and Etoile du Congo de Buta gained crests. No write came from this work. Check that AF Ufalya Simba is correct.
5. Minimum iOS rises to 15.0, because Xcode 27 refuses older targets. iOS 13 and 14 devices keep their installed version.
6. Ads shown in screenshots are test ads. Real ad placement was not checked.
7. Sponsor carousel code stays disabled until real images and links exist.
8. Landscape was not tested.

## Release readiness

Ready for an internal test build, not yet for public release. Before a public release: run on physical iPhone and Android phones, follow one live match, send one real push notification, and raise the version. Plan: `docs/release/MOBILE_RELEASE_AUTOMATION_PLAN.md`. Checklist: `RELEASE_CHECKLIST.md`.

Future CI/CD: `.github/workflows/ci.yml` stays as analysis and tests. Fastlane beta and internal lanes come after the owner adds signing credentials outside Git.

Nothing was submitted to Apple or Google.
