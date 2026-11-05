# Test matrix

## AdMob native validator fix, 6 Nov 2026 (build 36)

| Check | Result |
|---|---|
| Before (builds 33–35, plugin medium template) | emulator: 1 « Not all asset views lie inside the native ad view » per affected ad (5 of 5 in one run); Samsung: same warning |
| Cause | the template registers its store/advertiser text and hides it (GONE) for rated ads |
| After (Android: `FootrdcNativeAdFactory`, `footrdc_native_ad.xml`) | emulator, 80 scroll steps, 41 with an ad on screen, 4 ads: 0 warnings; validator « No implementation issues found » |
| Regression | `ui_ads_qa_test` pass; 172 unit/widget tests; analyze 17 infos |
| Not re-run | Samsung (phone locked during the evening run); iOS keeps the template (no warning observed there) |


## Physical Samsung Galaxy A56 (Android 17), 5 Nov 2026 evening, build 35 code

| Check | Result |
|---|---|
| Debug QA build (ads from the dev stack via `adb reverse`, no notification registration) | fresh data: onboarding offered; 2 clubs + alerts → system permission dialog only then → allowed; Plus › Clubs suivis 2, Notifications « Activées », defaults kickoff/result/changes on, reminder/goals off |
| Home custom ad | after the 3rd story; AdMob native test ad further down (6 stories apart) |
| Tap | `VIEW https://www.example.com/…` in Chrome |
| Article | custom ad after the introduction; AdMob test banner at the end |
| No active campaign / offline / slow server (6 s) | no slot, no error / Home offline message, no slot / ads received but the slot built behind the onboarding screen stayed empty (by design: no layout move) |
| AdMob | native validator (debug): « Not all asset views lie inside the native ad view » on the existing native template — pre-existing, open |
| Release APK 35 (Production config) | installed, registered as `7DB21FEE` with app_version « 5.12.11 (35) »; marked test device (old `7653D556` unmarked); test message in foreground and in background (system notification, channel actualites) |
| First reinstall | the previous install's 5 followed clubs reappeared during the first launch (most likely Android Auto Backup restoring app data; not proven); a clean data run behaves as specified |

## Custom mobile ads, 5 Nov 2026 (`feat/app-refinements-20261106`, working tree)

| Layer | Scope | Result |
|---|---|---|
| Unit and widget | 20 tests: parsing/unsafe input, 404, format errors, TTL, cache/refresh/offline back-off, end time, slot absent/present/semantics/tap/broken image/late answer, 320–768 px at 1–2×, light/dark contrast, article split | 170 passed in total |
| `custom_ads_qa_test` (dev stack campaigns) | Home + article ads, light/dark | Pass on Pixel 8 Pro, iPhone 18 Pro, iPhone 17e |
| Same, no active campaign (`QA_EXPECT_ADS=false`) | no slot anywhere | Pass on Pixel 8 Pro and iPhone 18 Pro (Android first run failed on a fresh-cache copy from a manual install < 10 min old — expected cache behaviour; clean install passes) |
| Regression with ads active | `ui_ads` (AdMob), `app_qa` 17 steps, `ui_notifications`, `ui_article_nav`, `article_clubs`, `onboarding`, `onboarding_later` | Pass on Pixel 8 Pro; Pass on iPhone 18 Pro (`app_qa` passed on rerun after one live-data wait on « Prochain match ») |
| Android by hand | browser intent on tap, broken image, offline, 130 % text | Pass |
| WordPress | `mobile-ads-runtime` 72; gate 3,942; Staging scenarios and security | Pass |


## App refinements, 6 Nov 2026 (`feat/app-refinements-20261106`, working tree)

| Layer | Scope | Result |
|---|---|---|
| Unit and widget | onboarding (offer rules, Continuer/Plus tard, explicit alerts off, upgrade with clubs, offline, clubs outside the season, 320/768 px at 1×/2×/1.3×), notification defaults and explicit choices, permission sync, banner suppression, tab rule, category label contrast | 150 passed, 0 failed |
| Pixel 8 Pro emulator | `onboarding`, `onboarding_later`, `ui_redesign` (light/dark), `app_qa` 17 steps, `ui_notifications`, `ui_article_nav`, `article_clubs` | Pass, 0 exceptions, 0 overflows |
| iPhone 18 Pro, iOS 27 | same | Pass, 0 exceptions, 0 overflows |
| iPhone 17e, iOS 27 | `ui_redesign`, `onboarding`, `onboarding_later` | Pass |
| Android by hand (adb) | no launch prompt; contextual dialog; defaults; real restart; refuse/grant on resume; offline fresh install; dark + 130 % text | Pass (see `docs/refinements-20261106/REPORT.md`) |
| iOS permission dialog | simulator cannot answer it | NOT RUN (physical iPhone with build 35) |

Device QA uses `--dart-define=FOOTRDC_PUSH_BASE=https://127.0.0.1:9/qa-no-registration` so no QA device registers on Production.


Results on app code `9d572f3`, with the test suite at `9054081`, 2 Nov 2026.

| Layer | Scope | Result |
|---|---|---|
| Unit and widget | Mapping, repository, cache, states, polling, tab order, tab state, routing, links, favorites, release safety | 79 passed, 0 failed, at `ece67f1` |
| API contract | `test/fixtures/production_contract.json`, sanitized live capture | Pass, inside the 75 |
| Responsive widget | 320, 360, 768 wide; text 100% and 130%; light and dark; tall keyboard | Pass, inside the 75 |
| iOS 27 SDK | `flutter build ios --release --no-codesign` | Pass; app and push extension report minimum 15.0, SDK `iphoneos27.0` |
| iPhone 11, iOS 27.0 | 25 steps | Pass, 0 exceptions, 0 overflows |
| iPhone 11, iOS 18.5, text size extra-extra-large | 25 steps | Pass, 0 exceptions, 0 overflows |
| iPhone 18 Pro, iOS 27.0 | 25 steps | Pass, 0 exceptions, 0 overflows |
| iPhone 17e, dark mode | 25 steps | Pass, 0 exceptions, 0 overflows |
| iPad, portrait | 25 steps | Pass, 0 exceptions, 0 overflows |
| Pixel 8 Pro | 25 steps | Pass, 0 exceptions, 0 overflows |
| Android 360x640 dp, text 130% | 25 steps | Pass, 0 exceptions, 0 overflows |
| Failure states, iOS and Android | Stale cache, offline, timeout, HTTP 500, invalid response | Pass, no raw error text |

The 25 steps cover Home, Matchs, match detail, the Linafoot tabs, standings, club search with the keyboard, club and squad, season 2025–2026, Édito, article, kept sub-tab, Plus, unified search, forced cache expiry on Accueil and Édito, and deep links to club, standings, match, article and Édito article. Links are sent from a different tab each time. Back uses the route Android's back button takes.

Failure states are injected at the HTTP layer on the device. The cache and screens are real; the network was not physically cut.

## Internal beta dry run, `ece67f1`, 2 Nov 2026

| Check | Result |
|---|---|
| `bundle exec fastlane beta_all dry_run:true` | Pass; nothing signed for iOS, nothing uploaded |
| iOS release build | Pass; app and extension 5.12.10 (31), minimum 15.0 |
| Android AAB | Pass; versionCode 31, versionName 5.12.10, target SDK 36, signed with the upload key |
| Missing credentials | All three lanes stop first, naming only the variables |
| Dirty tree, unpushed commit, readable credentials file | Each stops the lane |

| Physical and live checks | Result |
|---|---|
| Physical iPhone | NOT RUN |
| Physical Android | NOT RUN |
| Real push | NOT RUN |
| Live match | NOT AVAILABLE: first useful fixtures 4 Nov 2026 12:00 UTC |
| Physical performance | NOT RUN |

## Store preflight, `a360d21`

| Check | Result |
|---|---|
| `bundle exec fastlane android internal dry_run:true` | Pass, including live Google gates |
| `bundle exec fastlane ios beta dry_run:true` | Stopped at Apple's agreement, then passed once it was accepted |
| Fastlane parameters for every signing and upload step | Valid against the installed version |

## Internal uploads, `2925323`, 5.12.11 (31)

| Check | Result |
|---|---|
| `bundle exec fastlane ios beta` | Pass; read back from Apple: valid, `IN_BETA_TESTING`, no review submission |
| `bundle exec fastlane android internal` | Pass; read back from Google: internal 31 completed, production 30 unchanged |

## Club-linked news, `feat/article-clubs`, against Staging

| Check | Result |
|---|---|
| `flutter test` | 87 passed, 0 failed (8 new: parsing, legacy saved articles, paging, in-app opening, empty and offline states, navigation, 320 px) |
| `flutter analyze` | 0 errors, 0 warnings, 33 infos |
| iPhone 18 Pro, `integration_test/article_clubs_qa_test.dart` | Pass, 5 of 5 steps |
| Pixel 8 Pro, same test | Pass, 5 of 5 steps |

Steps: club Actualités, article with Clubs liés, club opened from the article and back twice (system back route), article with four clubs including one without crest, article without clubs. Staging was reached through a local SSH tunnel with debug-only defines; crests show initials there because Staging files sit behind Cloudflare Access.

## Build 32 against Production, 3 Nov 2026 (`4d58d36`)

| Check | iPhone 18 Pro | Pixel 8 Pro |
|---|---|---|
| `article_clubs_qa_test.dart`: Lupopo Actualités, Charger plus, article with clubs, club from article and back (pages kept), one club (opens AS Vita Club), four clubs, AF Ufalya Simba without crest (renamed), no clubs | 9/9 | 9/9 |
| `app_qa_test.dart`: Accueil, Édito, Matchs, match, Linafoot, standings, fixtures, results, clubs, squad, seasons, search, deep links, tab state | 25/25 | 25/25 |
| `failure_qa_test.dart`: cache, offline, timeout, HTTP 500, invalid response | 6/6 | 6/6 |

`flutter test` 87 passed (includes favorites, offline club news, parsing, paging); `flutter analyze` 0 errors, 0 warnings.
Uploads: TestFlight 5.12.11 (32) `IN_BETA_TESTING`, Main testers, no beta review; Google Play internal 5.12.11 (32) completed, production unchanged (30).

## Test harness notes

Two Pixel runs stopped on `Could not copy the pixels` from Flutter's Android screenshot helper. The app was running normally. Only that call now retries, up to three times, and logs each retry. The final run needed none.

## Not exercised

- A match in progress: none was being played. Polling is covered by widget tests.
- A delivered push notification. The link choice and the path it takes are tested; a real delivery is not.
- Following a club, opening a player page, and opening an article from club news: widget tests only.
- iOS 15, 16 and 17: this Mac has iOS 18.0 and later runtimes only.
- Landscape.
- Physical phones. All runs used simulators and emulators.
