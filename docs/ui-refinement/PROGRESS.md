# UI/UX refinement — progress

Branch `feat/ui-refinement` from `feat/rdc-football-mobile-redesign` at `077a341` (internal beta 5.12.11 (32)).
Rule: every significant change is checked on an iOS simulator and an Android emulator before the next one.
No TestFlight or Google Play upload in this task.

Devices: iPhone 11 QA 27 (iPhone 11, iOS 27.0), iPhone 18 Pro (iOS 27.0), Pixel 8 Pro emulator (Android 16, API 36).
Screens: `docs/ui-refinement/screens/<phase>/`.

| Phase | Scope | Status | Commit |
|---|---|---|---|
| 0 | Audit, baseline screenshots | done | `456efb2` |
| 1 | Ads policy remediation and placement | done: no pinned banner; native frame 320–400 unclipped; inline banner after article body; 5 tests; device QA iOS + Android (400×400 native, inline banner loaded) | phase 1 commit |
| 2 | Article back navigation | pending | |
| 3 | Home: drawer removal, AppBar | pending | |
| 4 | Plus: Thèmes, Notifications | pending | |
| 5 | Matchs and Classement reorganisation | pending | |
| 6 | Bottom navigation and full visual pass | pending | |
| 7 | Regression, final walkthrough, report | pending | |

## Audit findings

See `AUDIT.md`.
