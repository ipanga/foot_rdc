# Test matrix

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

## Test harness notes

Two Pixel runs stopped on `Could not copy the pixels` from Flutter's Android screenshot helper. The app was running normally. Only that call now retries, up to three times, and logs each retry. The final run needed none.

## Not exercised

- A match in progress: none was being played. Polling is covered by widget tests.
- A delivered push notification. The link choice and the path it takes are tested; a real delivery is not.
- Following a club, opening a player page, and opening an article from club news: widget tests only.
- iOS 15, 16 and 17: this Mac has iOS 18.0 and later runtimes only.
- Landscape.
- Physical phones. All runs used simulators and emulators.
