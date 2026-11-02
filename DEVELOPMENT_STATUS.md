NEXT_ACTION: Owner fills ASC_ISSUER_ID, ASC_KEY_ID and ASC_KEY_PATH in ~/.footrdc-release/release.env, then says so in chat without pasting values. Then run the read-only App Store Connect validation for the FootRDC record, highest build and internal groups. Keep build 31 if it is free on both stores. Google needs the FootRDC-only service account in PLAY_JSON_PATH. No upload until the owner instructs it.

# Development status

| | |
|---|---|
| Branch | `feat/rdc-football-mobile-redesign` (from `develop` 7e9f137), pushed to `origin`; head holds the exact SHA |
| Current phase | Internal beta: stopped before upload, credentials missing |
| Latest app code commit | `9d572f3`; tested code and release tooling pushed at `ece67f1` |
| Version | Flutter `5.12.10+31`; iOS CFBundleVersion 31, CFBundleShortVersionString 5.12.10; Android versionCode 31, versionName 5.12.10 |
| Tests | `flutter test`: 79 passed, 0 failed. `flutter analyze`: 33 infos, 0 errors, 0 warnings |
| Device QA | 9 of 9 runs pass on the final code, 0 exceptions, 0 overflows. See `TEST_MATRIX.md` |
| Emulators | iPhone 18 Pro booted; Pixel_8_Pro restored to default size and text |
| API | Production read-only; no writes made |
| SportsPress usage | `SPORTSPRESS_USAGE_REMAINING: 0` |
| iOS support | Minimum deployment target iOS 15.0; target device family iPhone 11 and newer supported iPhones |
| Release automation | Fastlane in `fastlane/`; `beta_all dry_run:true` passes; uploads await credentials |
| Bottom tabs | Accueil, Édito, Matchs, Linafoot, Plus |

## Known blockers

Uploads are blocked by missing credentials, listed in `RELEASE_CHECKLIST.md`.

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
| Internal beta preparation | PARTIAL: dry run passes, not uploaded | `29398b5` to `ece67f1` |

## Final checkpoint

PHASE STATUS: internal beta preparation PARTIAL; automation ready, upload blocked on credentials
TESTS: 79 passed, 0 failed
IOS: release build passes unsigned; signing blocked
ANDROID: signed AAB passes with the upload key; upload blocked
API: Production read-only
KNOWN ISSUES: signing and upload steps have not yet run against Apple or Google
NEXT_ACTION: as above
COMMIT: `ece67f1` tested; later commits on this branch are documentation
