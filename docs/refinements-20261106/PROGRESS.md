# App refinements (6 Nov 2026) — progress

Owner brief after the Production test-mode report: favourite-club onboarding, notification defaults, bottom tabs,
article category, Home header, notification hardening, device QA.
Branch `feat/app-refinements-20261106` from `feat/rdc-football-mobile-redesign` at `111a0aa` (5.12.11 (34)). Local only.
No backend deployment, no store upload, OneSignal untouched, no global FCM activation.

Devices: Pixel 8 Pro emulator (Android 16, API 36), iPhone 18 Pro and iPhone 17e simulators (iOS 27.0).
Device QA runs with `--dart-define=FOOTRDC_PUSH_BASE=https://127.0.0.1:9/qa-no-registration`, so QA devices never
register on Production (football and news still come from Production, read-only).
Screens: `docs/refinements-20261106/screens/{before,after}/<device>/`.

| # | Scope | Status |
|---|---|---|
| 1 | Favourite-club onboarding | done: `ClubOnboardingGate` + `ClubOnboardingScreen`; shared `ClubPicker` (season clubs, crests, search, several choices, followed clubs outside the season kept); state key `rdcf_club_onboarding` (`followed`/`done`/`later`), offered once; skipped when clubs are already followed, offline/API failure (retried next launch) or another screen is open (notification/link); Plus › Clubs suivis: « Modifier », empty state button, clubs outside the season |
| 2 | Notification defaults | done: kickoff ON, result ON, changes ON, goals OFF, reminder OFF once club alerts are on; explicit choices tracked (`rdcf_push_explicit`), 5.12.11 (34) stored preferences all kept; no launch permission prompt; permission asked when the user turns on news, club alerts or the master switch, and from the onboarding « Alertes de match » |
| 3 | Bottom tabs | done: pill removed; filled red icon + bold red label + 28×3 rule on the top edge; outlined grey others |
| 4 | Article category | done: `CategoryLabel` (red small capitals, no box) on detail, list cards (« RDC · 10:45 ») and featured card; « À la Une » with its accent |
| 5 | Home header | done: trimmed logo `logo_mark_footrdc.png` (splash image had ~20 % transparent margin), 26 px, wordmark centred on its capitals, no text scaling; measured centre offset before −6.0 px (iPhone 18 Pro) / −6.5 px (Pixel), after 0.0 / −0.5 px |
| 6 | Notification hardening | done: `app_version` « 5.12.11 (34) » from package info; `permission` field; `prefs.enabled` false while the device refuses; permission refreshed on every resume (`AppLifecycleListener`); no in-app banner while refused/off or for a message older than 2 min |
| — | Found on the way | Home headline showed raw `&rsquo;` → decoded |
| 7 | Tests and device QA | see `TEST_MATRIX` section below |
| 8 | Report | `REPORT.md` |

Backend: none required. Notify 0.1.1 ignores the new `permission` field and stores `app_version`; « enabled »
already exists. No old-event replay: the server's match baseline and dedup keys are unchanged; the app adds nothing.

Resume: run `flutter test`, then `tool/qa_drive.sh` with the tests in `integration_test/onboarding*_qa_test.dart`,
`ui_redesign_qa_test.dart` and the regression set (`app_qa`, `ui_notifications`, `ui_article_nav`, `article_clubs`).
