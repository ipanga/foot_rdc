NEXT_ACTION: Production now serves club news and related_clubs (RDC Football Core 0.11.0 / UI 0.18.0 since 3 Nov 2026). Next mobile step, only on owner approval: rebase feat/article-clubs onto the release line, raise the build number with tool/set_build_number.sh, rerun the device QA against Production, then `bundle exec fastlane ios beta` and `bundle exec fastlane android internal`. Internal beta 5.12.11 (31) testing continues per docs/release/INTERNAL_BETA_TEST_PLAN.md.

# Development status

| | |
|---|---|
| Branch | `feat/rdc-football-mobile-redesign` (released line, pushed); `feat/article-clubs` (club news, local, not released) |
| Current phase | Internal beta live on both stores; physical testing next |
| Latest app code commit | `9d572f3`; uploaded source revision `2925323` |
| Version | Flutter `5.12.11+31`; iOS CFBundleVersion 31, CFBundleShortVersionString 5.12.11; Android versionCode 31, versionName 5.12.11 |
| Tests | `flutter test`: 87 passed, 0 failed on `feat/article-clubs` (79 on the released line). `flutter analyze`: 33 infos, 0 errors, 0 warnings |
| Device QA | 9 of 9 runs pass on the final code, 0 exceptions, 0 overflows. See `TEST_MATRIX.md` |
| Emulators | iPhone 18 Pro booted; Pixel_8_Pro restored to default size and text |
| API | Production read-only; no writes made |
| SportsPress usage | `SPORTSPRESS_USAGE_REMAINING: 0` |
| iOS support | Minimum deployment target iOS 15.0; target device family iPhone 11 and newer supported iPhones |
| Release automation | Fastlane in `fastlane/`; `ios beta` and `android internal` have both uploaded for real |
| Bottom tabs | Accueil, Édito, Matchs, Linafoot, Plus |

## Known blockers

None for internal testing.

## Deferred

See `DECISIONS.md` and the limitations in the final report.

## Phase log

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

## Club-linked news (3 Nov 2026)

| Item | State |
|---|---|
| Server | RDC Football Core 0.11.0 / UI 0.18.0 on Production since 3 Nov 2026 11:39 UTC |
| App | `Article.relatedClubs`, club "Actualités" cards with paging, "Clubs liés" on articles; branch `feat/article-clubs` |
| Device QA against Staging | iOS and Android pass 5 of 5 steps, 0 exceptions, 0 overflows |
| Release dependency | Met: Production serves `related_clubs` and the richer `/teams/{id}/news`; the released 5.12.11 parsers pass on the live responses |

## Final checkpoint

PHASE STATUS: internal beta PASS on both stores; physical testing not started
TESTS: 79 passed, 0 failed
IOS: 5.12.11 (31) in TestFlight, internal testing
ANDROID: 5.12.11 (31) in Google Play internal testing
API: Production read-only
KNOWN ISSUES: physical phones, real push and a live match are unverified
NEXT_ACTION: as above
COMMIT: `2925323` uploaded; later commits on this branch are documentation
