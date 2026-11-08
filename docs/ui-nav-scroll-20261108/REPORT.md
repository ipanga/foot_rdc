# Navigation and reading comfort — 8 Nov 2026

Branch `feat/ui-nav-scroll-20261108` (from `449d9d3`), released as **5.12.11 (37)** for internal testing after owner approval (8 Nov). WordPress untouched.

## Changes

| # | Change | Where |
|---|---|---|
| 1 | Article category in the date's colour (shared tertiary text token; white 70 % on the photo card, like its date; club news cards use the date's `onSurfaceVariant`) | `shared/widgets/category_label.dart`, `news/.../article_list_item.dart`, `football/.../club_detail_screen.dart` |
| 2 | No red rule above the selected tab; filled red icon + bold red label kept; no pill or background | `shared/widgets/premium_bottom_nav_bar.dart` |
| 3 | Tab bar hides while reading further, returns when going back up | new `shared/widgets/auto_hide_bottom_bar.dart`; one listener in `home_screen.dart` |
| 4 | « Bon à savoir » removed from Plus (tile, `EditorialChannel.bonASavoir`, `ApiConstants.bonASavoirCategorySlug`) | `more/more_screen.dart`, `editorial/.../editorial_providers.dart`, `core/constants/api_constants.dart` |
| 5 | Optional update suggestion, iOS (see below) | new `features/app_update/app_update.dart`; banner in `home_screen.dart` |
| — | Fix found in QA: Accueil's match strip overflowed with very large text; text there now grows to 1.3× (full size on Matchs) | `football/.../football_widgets.dart` (`MatchChip`) |

### Scroll behaviour (3)
- One `NotificationListener` around the tab pages feeds `BottomBarVisibility`; no screen has its own listener. Only vertical scrolls count (carousels, tab swipes and the wide table are ignored).
- Hides after 28 px held in the reading direction, shows after 28 px back; a change of direction restarts the count, so tremors never toggle.
- Always shown: at the top, at the end of the content, on content scrolling less than 160 px (Plus, a short « Aujourd'hui » list, empty states), on tab change, on return from an article/club/Plus page, on app resume.
- The bar's slot shrinks with it (220 ms, ease-out), so the page gains the room without content moving; safe area included. Instant with « Réduire les animations »; never hidden with VoiceOver/TalkBack; hidden tabs can't be tapped or focused.
- The offline banner and the update line stay in view when the tabs slide away.
- Articles, club and match pages open over the tabs (no tab bar there), so nothing changes in them.
- Group tables are about one screen: they reach their end quickly, where the bar returns — intended.

### Update suggestion (5) — iOS implemented, Android deferred
- iOS: Apple's public lookup (`itunes.apple.com/lookup?bundleId=…`, no key, no permission), at most once per 24 h, result cached. Only public App Store versions exist there, so TestFlight builds are never offered. Today the store has **1.1.3**, below 5.12.11: nobody is prompted until a newer public version is published.
- A slim line above the tabs, **Accueil only** (never over an article, a match or Plus): « Nouvelle version de FootRDC disponible · Plus tard · Mettre à jour ». « Mettre à jour » opens the App Store listing; « Plus tard » hides it for that version for 7 days. No blocking dialog, no mandatory update.
- **Android deferred**: Google Play has no public version lookup. The reliable route is Google's In-App Updates API (package `in_app_update`, Play Core native library): it reports only versions the user's own track may install, but an internal tester would see internal builds, it cannot be tested before a Play-installed release, and it adds a native dependency. Recommendation for a later phase: add `in_app_update`, call `checkForUpdate()` at most daily, reuse this same banner and cooldown, open the Play listing (or the flexible flow) on « Mettre à jour ». Alternative without native code: a « latest Android version » field served by the existing RDC Football API, updated at each release.

## Device results (all against Production, read-only)

| Device | Run | Result |
|---|---|---|
| iPhone 11 (iOS simulator) | before / after / very large text (accessibility XL) | PASS; bar 98 → 0 → 98 on Accueil and Matchs (light and dark), stays on Classement end and Plus; « Bon à savoir » 0; 0 overflows after the strip fix |
| iPhone 18 Pro (simulator) | after | PASS, same measurements |
| Pixel 8 Pro (Android emulator) | before / after | PASS; bar 64 → 0 → 64, same pattern; 0 exceptions |
| iPhone 11 | update suggestion (`APP_UPDATE_INSTALLED=1.0.0`, real lookup → 1.1.3) | PASS: shown on Accueil, absent on Matchs, « Plus tard » hides and remembers 1.1.3 |
| Pixel 8 Pro | existing ads (native ads in feed, inline banner in article), article navigation, notifications (settings, simulated banner opening the article) | PASS, 0 exceptions. First run: ads QA failed tapping « Édito » after scrolling far down (bar hidden — test helper `Qa.nav` now scrolls back up first); notifications QA failed once on route-closing timing and passed on rerun |
| Physical Android | — | none connected (only the emulator) |

QA script: `integration_test/ui_nav_scroll_qa_test.dart` (prints `QA-BAR … visible=` at each step) and `ui_app_update_qa_test.dart`. Screens: `screens/before/`, `screens/after-iphone11/`, `after-iphone18pro/`, `after-pixel8pro/`, `after-iphone11-grand-texte/`, `update-iphone11/`. Logs: `logs/`.

## Automated tests
- `flutter test`: **179 passed** (was 170): new `test/shared/auto_hide_bottom_bar_test.dart` (hide/show, tremors, edges, short content, horizontal ignored, slot shrink, reduced motion, screen reader, version comparison); nav bar test now asserts no indicator; category test asserts the date colour.
- `flutter analyze`: 16 infos, 0 warnings, 0 errors (was 17 infos).

## Limitations and risks
- **Category contrast** — owner decision 8 Nov: the shared tertiary text token is darkened in light mode, #94A3B8 → #64748B (2.6:1 → 4.8:1 on white, 4.4:1 on the grey page background), for dates, categories and other meta text everywhere; the category test checks 4.5:1 again. Dark mode unchanged.
- « Mettre à jour » opening the App Store was not tapped on the simulator (no App Store there); the URL is the store's own `trackViewUrl`.
- Android update suggestion deferred (above).
- Device tests that tap a tab after scrolling far down need the bar back: the shared `Qa.nav` helper now scrolls up first.

## Pre-release checks (after the colour change)
`flutter analyze` 0 errors/warnings, `flutter test` 179 passed. Device: iPhone 11 navigation + redesign QA, iPhone 18 Pro full app + ads + notifications QA, Pixel 8 Pro navigation + full app + settings QA — all PASS, 0 exceptions (`logs/prerelease-*`, `screens/prerelease-*`). The settings QA still looked for « Préférence FootRDC » (renamed on 6 Nov); updated to « Articles à la Une ».

## Next steps
1. Your review of the screens (and the contrast choice).
2. Commit on request; then a build for internal testing only with your approval.
3. Later phase: Android update suggestion.
