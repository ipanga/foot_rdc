NEXT_ACTION: Owner approves an internal build. Then, with signing credentials added outside Git: raise the build number, build, and send to TestFlight internal testers and Google Play internal testing only, following docs/release/MOBILE_RELEASE_AUTOMATION_PLAN.md and RELEASE_CHECKLIST.md. Testers check physical iPhone 11 and Android phones, one live match, and one real push. No upload before that approval.

# Development status

| | |
|---|---|
| Branch | `feat/rdc-football-mobile-redesign` (from `develop` 7e9f137), not pushed |
| Current phase | All phases done; stopped at the release gate |
| Latest app code commit | `9d572f3`, tests at `9054081` |
| Tests | `flutter test`: 75 passed, 0 failed. `flutter analyze`: 33 infos, 0 errors, 0 warnings |
| Device QA | 9 of 9 runs pass on the final code, 0 exceptions, 0 overflows. See `TEST_MATRIX.md` |
| Emulators | iPhone 18 Pro booted; Pixel_8_Pro restored to default size and text |
| API | Production read-only; no writes made |
| SportsPress usage | `SPORTSPRESS_USAGE_REMAINING: 0` |
| iOS support | Minimum deployment target iOS 15.0; target device family iPhone 11 and newer supported iPhones |
| Bottom tabs | Accueil, Édito, Matchs, Linafoot, Plus |

## Known blockers

None for a test build. Open limits are in the final report.

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

## Final checkpoint

PHASE STATUS: final iOS and navigation adjustment PASS; stopped at the release gate
TESTS: 75 passed, 0 failed
IOS: PASS on iPhone 11 (iOS 27.0 and 18.5), iPhone 18 Pro, iPhone 17e, iPad
ANDROID: PASS on Pixel 8 Pro and on 360x640 dp with text at 130%
API: Production read-only, contract tests pass
KNOWN ISSUES: see final report
NEXT_ACTION: as above
COMMIT: see `git log`; app code `9d572f3`
