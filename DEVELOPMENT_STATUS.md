NEXT_ACTION: 5.12.11 (36) on TestFlight Internal (6 Nov 00:48) and Google Play internal (01:03); Play beta 34, production 30 unchanged. AdMob native validator warning fixed on Android (own native layout). Production: `rdc-football-mobile-ads` 0.1.1, no campaign; FCM mode test. Samsung test phone has a debug QA build: install 36 from Play internal, then re-mark its new notification code as test device.

# Development status

| | |
|---|---|
| Branch | `feat/rdc-football-mobile-redesign`, pushed, head `ff54f72` (fast-forwarded from `feat/ui-refinement`) |
| Current phase | Internal beta 5.12.11 (33) with the UI refinement on both stores; physical testing next |
| Latest app code commit | `a4dabbc`; uploaded source revision `ff54f72` |
| Version | Flutter `5.12.11+33`; iOS CFBundleVersion 33, CFBundleShortVersionString 5.12.11; Android versionCode 33, versionName 5.12.11 |
| Tests | `flutter test`: 113 passed, 0 failed. `flutter analyze`: 17 infos, 0 errors, 0 warnings |
| Device QA | Pre-release runs on iPhone 11, iPhone 18 Pro, Pixel 8 Pro: all pass after the club-news test fix; screens in `docs/ui-refinement/screens/prerelease/` |
| Emulators | iPhone 18 Pro booted; Pixel_8_Pro restored to default size and text |
| API | Production read-only; no writes made |
| SportsPress usage | `SPORTSPRESS_USAGE_REMAINING: 0` |
| iOS support | Minimum deployment target iOS 15.0; target device family iPhone 11 and newer supported iPhones |
| Release automation | Fastlane in `fastlane/`; `ios beta` and `android internal` have both uploaded for real |
| Bottom tabs | Accueil, Édito, Matchs, Classement, Plus |

## Known blockers

None for internal testing.

## Deferred

See `DECISIONS.md` and the limitations in the final report.

## Phase log
| Custom mobile ads (WordPress « Publicités mobiles » + slots home_feed/article_inline) | IMPLEMENTED; Staging VERIFIED; 170 tests; device QA PASS Pixel 8 Pro, iPhone 18 Pro, iPhone 17e | `feat/app-refinements-20261106` (uncommitted) + rdc-football-platform `feat/mobile-ads` |
| App refinements 6 Nov (club onboarding, notification defaults/permission, tabs, category, header, notification hardening) | IMPLEMENTED; 150 tests; device QA PASS on Pixel 8 Pro, iPhone 18 Pro, iPhone 17e | `feat/app-refinements-20261106` (uncommitted) |
| FCM notifications (« À la Une », club alerts) | IMPLEMENTED; simulators VERIFIED (token, settings, simulated banner); real delivery PENDING owner credentials | `058acd3` on `feat/fcm-notifications` (local) |

| Phase | Status | Commit |
|---|---|---|
| 0 Audit and baseline | PASS | `07b7d2b` |
| 1 API client and domain | PASS | `07b7d2b` |
| 2 Navigation and design system | PASS | `cac8142` |
| 3 Linafoot | PASS | `cac8142` |
| 4 Matches, results, match center | PARTIAL: no live match was available to observe | `cac8142`, `d5fcca1` |
| 5 Clubs, players, squads | PARTIAL: squads exist only for imported clubs | `cac8142` |
| 6 Editorial, Édito, search, favorites, Home | PARTIAL: favorites not exercised on a device | `cac8142`, `1a76fcc` |
| 7 Emulator QA, performance, regression | PARTIAL: performance measured in part | `5f79298` |
| 8 Store automation prep | PASS: plan only, nothing uploaded | `06f653a` |
| Final iOS and navigation adjustment | PASS | `3aa200f` to `9054081` |
| Internal beta | PASS: uploaded to TestFlight internal and Google Play internal | `2925323` |
| UI refinement (ads policy, navigation, settings, Matchs/Classement) | PASS, owner-approved; see `docs/ui-refinement/REPORT.md` | `456efb2` to `a4dabbc` |
| Internal beta 5.12.11 (33) | PASS: TestFlight internal (Main testers, IN_BETA_TESTING) and Google Play internal (completed); production track 30 unchanged | `ff54f72` |

## Club-linked news (3 Nov 2026)

| Item | State |
|---|---|
| Server | RDC Football Core 0.11.0 / UI 0.18.0 on Production since 3 Nov 2026 11:39 UTC |
| App | `Article.relatedClubs`, club "Actualités" cards with paging, "Clubs liés" on articles; released internally as 5.12.11 (32) |
| Device QA against Production | iOS and Android pass 9 of 9 club steps, 25 of 25 regression steps and 6 failure states; 0 exceptions, 0 overflows |
| Release dependency | Met: Production serves `related_clubs` and the richer `/teams/{id}/news`; the released 5.12.11 parsers pass on the live responses |

## Final checkpoint

PHASE STATUS: internal beta 5.12.11 (33) PASS on both stores; physical testing not started
TESTS: 113 passed, 0 failed
IOS: 5.12.11 (33) in TestFlight, internal testing (Main testers)
ANDROID: 5.12.11 (33) in Google Play internal testing; production track still 30
API: Production read-only
KNOWN ISSUES: physical phones, real push, a live match and real (non-test) ads are unverified; AdMob restriction stays until a public release and a review request
NEXT_ACTION: as above
COMMIT: `ff54f72` uploaded
