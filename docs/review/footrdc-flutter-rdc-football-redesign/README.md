# FootRDC Flutter: RDC Football migration and redesign

Final report, updated 2 Nov 2026. Branch `feat/rdc-football-mobile-redesign`, app code `9d572f3`, tests at `9054081`, version `5.12.11+31`.

The app now runs on the RDC Football API with five tabs, including Édito. Every automated test and all nine device runs pass on the final code. It has not been tried on a physical phone or during a live match, and it is not publicly released.

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
| IOS DEPLOYMENT TARGET | 15.0 |
| IPHONE 11+ COMPATIBILITY | PASS on simulators |
| IOS 27 BUILD | PASS |
| IOS QA | PASS |
| ANDROID QA | PASS |
| API CONTRACT TESTS | PASS |
| REGRESSION TESTS | PASS |
| PERFORMANCE | PARTIAL: no profile build on a physical phone |
| RELEASE AUTOMATION PLAN | READY |
| TESTFLIGHT UPLOAD | INTERNAL ONLY: PASS |
| GOOGLE PLAY UPLOAD | INTERNAL ONLY: PASS |

`SPORTSPRESS_USAGE_REMAINING: 0` across `lib`, `test`, `integration_test` and `tool`. The word remains only in documents describing the past.

## Architecture

| | Before | After |
|---|---|---|
| Football source | SportsPress REST | RDC Football REST |
| Layers | Screens close to raw responses | Client, mappers, domain, repository, Riverpod state, UI |
| Seasons | Fixed in code | Discovered from the API, current and past |
| Cache | Memory only | Saved on device, shown first, then refreshed |
| Standings | Read from SportsPress | Read from the server, never calculated in the app |
| Navigation | Navigator, no router | Unchanged, plus deep links and named tabs that keep their state |

The app was evolved rather than rewritten. Articles, saved articles, ads and theming stayed in place.

## Final navigation

Accueil, Édito, Matchs, Linafoot, Plus.

**Minimum deployment target: iOS 15.0.** **Target device family: iPhone 11 and newer supported iPhones.**

## API mapping

Full table: `API_MIGRATION_MATRIX.md`.

Remaining WordPress use is articles, categories and article search through `/wp/v2`, which is intended. Édito reads the WordPress category with slug `editorial`, resolved at run time.

## Screens

| Tab | Screens |
|---|---|
| Accueil | À la Une, match strip, news, Linafoot snapshot |
| Édito | Article list, article |
| Matchs | Aujourd'hui, À venir, Résultats, match detail |
| Linafoot | Aperçu, Calendrier, Résultats, Classements, Clubs, season picker |
| Plus | Clubs, clubs suivis, recherche, articles enregistrés, Bon à savoir, thème et notifications |
| Shared | Club (Aperçu, Actualités, Résultats, Calendrier, Classement, Effectif), player |

New for readers: match events, past seasons, club pages, squads, player pages, followed clubs, search across articles, clubs and players, and deep links.

Design changes: lighter tab bar, denser match rows, neutral day headers, compact and full standings, initials when a club has no crest, and intentional loading, empty and error states in French.

## Caching

Football responses are saved on the device and shown immediately, then refreshed. After 2 minutes matches and tables count as old; other data lasts longer. When a refresh fails, saved data stays on screen with the notice "Données enregistrées. Actualisation impossible pour le moment." Data older than 24 hours is not shown offline. Live polling runs every 30 seconds, stops when a match ends, and pauses in the background.

## Device QA

All on the final app code. Screens are under `docs/mobile-redesign/screens/`.

| Device | Screens | Result |
|---|---|---|
| iPhone 11, iOS 27.0 | `iphone-11-ios27/` | 25 of 25 steps |
| iPhone 11, iOS 18.5, large text | `iphone-11-ios18-large-text/` | 25 of 25 steps |
| iPhone 18 Pro, iOS 27.0 | `after/` (`ios-*`) | 25 of 25 steps |
| iPhone 17e, dark mode | `small-dark/` | 25 of 25 steps |
| iPad, portrait | `ipad/` | 25 of 25 steps |
| Pixel 8 Pro | `after/` (`android-*`) | 25 of 25 steps |
| Android 360x640 dp, text 130% | `android-narrow-large-text/` | 25 of 25 steps |
| iOS and Android failure states | `states/` | 6 of 6 states each |

0 exceptions and 0 layout overflows in those runs. Bottom navigation on Accueil, Édito and Linafoot for three devices: `final-navigation/`. Before screens: `baseline/`.

Unit and widget tests: 79 passed at `ece67f1`. Analyzer: 0 errors, 0 warnings, 33 style infos. Release build against the iOS 27 SDK succeeds, with minimum 15.0 on the app and the push extension. Details: `TEST_MATRIX.md`.

### Bugs found by device runs and fixed

- Club and player search never matched. The screen passed its URL string instead of the search term. Unit tests missed it because they called the widget with a clean term.
- Tab labels were cut off at large system text.
- Club search overflowed on a small screen with a tall keyboard. The ad and tabs now hide while typing, and search scrolls with the list.
- A sponsor carousel showed an empty box because its images are placeholders. It is hidden until real images exist.
- Result rows in lists without day headers showed no date.
- Tabs were rebuilt on every switch, losing the chosen sub-tab. They now keep their state.
- Home crashed when reopened after its cache expired, once tabs stayed alive. It now refreshes in place.
- Article titles were cut through a line at large text. Cards now grow with text size.
- Two links on Home used fixed tab numbers that the new order would have broken. Tabs are now named.
- The Classements link on Home opened Aperçu. It now opens the standings.
- Club news left the app instead of opening the article inside it.

## Performance

| Measure | Result |
|---|---|
| Main API responses, single request from this Mac | 0.63 to 1.35 s |
| Compressed response size | 168 B to 2.3 KB |
| Reopening with saved data | Shown without a spinner, then refreshed |

Startup time and frame rates were not measured, because profile builds do not run on simulators or emulators. Debug timings would not be meaningful. This needs a physical phone.

## Push audit

Delivery stays on OneSignal. Tapping a notification opens the matching article, club, match or standings through the same deep-link path, whichever tab is open. No real notification was delivered in testing. The permission request no longer blocks the first frame, but it still appears at launch. No football notification was added, so nothing new can be noisy. Firebase is initialised only for the existing messaging setup. There is no analytics SDK, and none was added.

## Limitations

1. No live match was observed. The first real test is the fixtures on 4 Nov 12:00 UTC.
2. Squads are empty for clubs not yet imported, for example Blessing, and the app says so. Filling them depends on the separate decision to extend squad imports.
3. A Production table hidden on the website has no public REST flag, so the app cannot honour that setting. Tables are shown with the provisional note.
4. Some clubs have no crest and show initials. Crest data on Production changed during QA: AF Ufalya Simba briefly returned an Étoile du Congo crest, then none, while Butras and Etoile du Congo de Buta gained crests. No write came from this work. Check that AF Ufalya Simba is correct.
5. iOS 15, 16 and 17 were not run, because this Mac has only iOS 18.0 and later simulators. The lowest version tested is 18.5.
6. Ads shown in screenshots are test ads. Real ad placement was not checked.
7. Sponsor carousel code stays disabled until real images and links exist.
8. Landscape was not tested.

## Release readiness

`5.12.11 (31)` is in TestFlight internal testing and Google Play internal testing. Not ready for public release. Before a public release: run on physical iPhone and Android phones, follow one live match, send one real push notification, and raise the version. Plan: `docs/release/MOBILE_RELEASE_AUTOMATION_PLAN.md`. Checklist: `RELEASE_CHECKLIST.md`.

Future CI/CD: `.github/workflows/ci.yml` stays as analysis and tests. Fastlane beta and internal lanes come after the owner adds signing credentials outside Git.

Nothing was submitted for App Review or any public Google Play track.
