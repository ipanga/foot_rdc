# FootRDC UI/UX refinement: final report, 3 Nov 2026

Branch `feat/ui-refinement` (local, not pushed) from `077a341` (internal beta 5.12.11 (32)). Version unchanged.
Before/after page for review: https://claude.ai/artifact/N4dvYGe8CaXQuJ2sWFHnbn (private). Screens: `screens/baseline/`, `screens/final/`, and per phase.

| Item | Result |
|---|---|
| INITIAL UI/UX AUDIT | `AUDIT.md`: 4 ad findings, 3 notification bugs, drawer duplication, article back control lost while reading, Matchs/Linafoot overlap, unaccented labels |
| HOME DRAWER REMOVAL | PASS: drawer and hamburger removed; theme, notifications, about moved to Plus |
| THEMES SETTINGS | PASS: Plus › Thème, Automatique / Clair / Sombre, saved and restored; Automatique follows the device |
| NOTIFICATIONS SETTINGS | PASS: no OneSignal opt in/out at start (fresh installs were silently opted out); launch prompt only while unanswered, never a settings detour, never after opting out; preference and device permission shown separately; settings button when not allowed. Real delivery not observed (no push permission on simulator/emulator) |
| GOOGLE ADS POLICY REMEDIATION | PARTIAL: code fixed and verified with test ads; the account restriction lifts only after release and an AdMob review request (`ADS_REMEDIATION.md`) |
| AD PLACEMENT REDESIGN | PASS: no banner by the navigation; native ads every 9 articles in Google's 320–400 frame, unclipped, labelled; one inline banner after the article body |
| ARTICLE BACK NAVIGATION | PASS: pinned bar (back, title, save, share); feed position kept (Pixel 1666 → 1666, iPhone 11 1761 → 1761); system back |
| MATCHS REORGANIZATION | PASS: Aujourd'hui (live, today), Calendrier, Résultats; season picker; Tous / Groupe / Play-offs filters; club fixtures on club pages |
| CLASSEMENT REORGANIZATION | PASS: Linafoot → Classement; one tab per table (Groupe A, Groupe B, Play-offs…) and Clubs; season picker with past-season notice; standings links switch to the tab |
| HOME APPBAR | PASS: brand left, search right, standard AppBar |
| BOTTOM NAVIGATION DESIGN | PASS: Accueil, Édito, Matchs, Classement, Plus; button + selected semantics; 4.5:1 labels light and dark; fits 320 px at 2× text |
| FULL APP VISUAL REFINEMENT | PASS within scope: French dates, accents in messages, Matchs tab labels fit on small screens; no redesign of club, player or search screens beyond shared components |
| IOS SIMULATOR QA | PASS: iPhone 11 (iOS 27) 5 device tests; iPhone 18 Pro navigation + settings |
| ANDROID EMULATOR QA | PASS: Pixel 8 Pro 5 device tests; small configuration 360×640 dp with 130 % text, navigation 17/17, 0 overflow |
| FLUTTER ANALYZE | 0 errors, 0 warnings, 17 infos (33 before) |
| FLUTTER TESTS | 113/113 |
| RDC FOOTBALL API REGRESSION | PASS on Production, read-only: navigation, standings, seasons, club news with pagination, Clubs liés; no API change |
| UNRESOLVED ISSUES | No physical device or iOS 15 runtime tested. Two one-off failures in the final pass (club news on Pixel, ads on iPhone 11) passed on rerun; causes not established (logs overwritten). Pixel default and iPhone 18 Pro navigation ran before the last Matchs tab-label fix (rechecked on iPhone 11 and small Pixel). Unused asset `menu-icon.svg` left in place |
| TESTFLIGHT UPLOAD | NOT EXECUTED |
| GOOGLE PLAY UPLOAD | NOT EXECUTED |

## Internal beta 5.12.11 (33), 4 Nov 2026 (owner-approved)

| Item | Result |
|---|---|
| Commit | `ff54f72` on `feat/rdc-football-mobile-redesign` (pushed); includes `feat/article-clubs` |
| Pre-release checks | Club news on Android failed 3/3 before upload: the device test tapped "Voir le club" below the screen when the 250 px inline ad pushed the cards down. Test fixed (scroll cards on screen, never tap off screen); then 3/3 on Pixel, 1/1 on iPhone 11. No ad was clicked (no AdActivity in the logs). Ads on iPhone 11 2/2 with the banner loaded after a longer wait (test ads were slow, no load error). Navigation 17/17 on Pixel and iPhone 18 Pro; article back navigation and settings pass |
| Ads | Native 400×400 inside Google's 320–400 frame; inline banner 374×58 or 374×250 on iPhone 11, 408×250 on Pixel, at the SDK-reported size; test ads only during QA |
| TestFlight | 5.12.11 (33) VALID, export compliance set (no non-exempt encryption, as confirmed for earlier builds), internal IN_BETA_TESTING, Main testers has access to all builds. Not submitted for external review. The lane stopped on an SSL drop after the changelog; the compliance answer was then applied with the same value the lane uses |
| Google Play | internal track 33, release completed; alpha and beta empty; production 30 unchanged |
