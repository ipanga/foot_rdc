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
