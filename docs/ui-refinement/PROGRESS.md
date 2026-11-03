# UI/UX refinement — progress

Branch `feat/ui-refinement` from `feat/rdc-football-mobile-redesign` at `077a341` (internal beta 5.12.11 (32)).
Rule: every significant change is checked on an iOS simulator and an Android emulator before the next one.
No TestFlight or Google Play upload in this task.

Devices: iPhone 11 QA 27 (iPhone 11, iOS 27.0), iPhone 18 Pro (iOS 27.0), Pixel 8 Pro emulator (Android 16, API 36).
Screens: `docs/ui-refinement/screens/<phase>/`.

| Phase | Scope | Status | Commit |
|---|---|---|---|
| 0 | Audit, baseline screenshots | done | `456efb2` |
| 1 | Ads policy remediation and placement (`ADS_REMEDIATION.md`) | done: no pinned banner; native frame 320–400 unclipped; inline banner after article body; 5 tests; device QA iOS + Android (400×400 native, inline banner loaded) | `2731e94` |
| 2 | Article back navigation | done: pinned collapsing bar (back, title, save, share); feed offset kept after back (Pixel 1673.5→1673.5, iPhone 11 1760→1760); system back; 2 tests | `38a71be` |
| 3 | Home drawer removal, Home AppBar | done: drawer and hamburger removed; brand left, search right, standard AppBar (status bar via systemOverlayStyle) | `b03caaa` |
| 4 | Plus: Thème, Notifications, À propos | done: separate screens; theme saved and restored; notifications: no OneSignal call at start, launch prompt once without settings detour and never after opting out, device permission vs app preference shown apart, settings button after refusal; À propos dialog (was a no-op); 11 tests | `b03caaa` |
| 5 | Matchs and Classement reorganisation | done: Matchs = Aujourd'hui (live, today), Calendrier, Résultats with season picker and Tous/Groupe/Play-offs filters; Linafoot → Classement: one tab per table + Clubs; Aperçu removed (duplicated Home and Matchs); standings links switch to the tab; navigation regression iPhone 11 17/17 | `b68145a` |
| 6 | Bottom navigation and full visual pass | done: bar rebuilt (button + selected semantics, 4.5:1 labels light/dark, no blur, fits 320 px at 2× text, Plus icon); French article dates ("Hier", "2 nov."); accents in error messages; 8 tests | `b68145a` |
| 7 | Regression, final walkthrough, report | done: `REPORT.md`; 113 tests; device tests on iPhone 11, iPhone 18 Pro, Pixel 8 Pro and small Pixel; Matchs tab labels fixed for small screens | final commit |

## Audit findings

See `AUDIT.md`.
