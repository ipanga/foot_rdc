# Accueil: recent results and upcoming fixtures, new launcher icon (10 Nov 2026)

Branch `feat/rdc-football-mobile-redesign`. Released as **5.12.11 (38) to TestFlight internal testers and Google Play internal testing** on owner request (10 Nov, « internal tracks »); nothing public.

## 1. What changed

### Accueil
The single « Matchs » strip is replaced by two compact carousels, between the featured article and the news feed (same place as before):

- **Derniers résultats**
  - Five completed Linafoot matches of the current season, newest first.
  - Only `finished` or `awarded` matches with both scores. Cancelled, postponed, abandoned or interrupted matches are never shown as results.
  - Each card shows the date (« Décision administrative » for an awarded result), group, crests, names and both scores, with the winner in bold.
  - « Tout voir » opens Matchs › Résultats for the current season.
- **Prochains matchs**
  - Live matches first, with the existing « En direct » / minute badge.
  - Then the next five `scheduled` fixtures, nearest first.
  - Each card shows « Aujourd'hui / Demain / 12 nov. · 14:00 » in the device's local time, the group and both clubs. No score is ever shown for a fixture.
  - « Calendrier » opens Matchs › Calendrier.
- Every card opens the existing match screen (`openMatch`, same IDs and deep links).
- Each section hides itself when empty or when the API fails, so the rest of Accueil is unaffected.
- **Reuse:**
  - existing providers `matchWindowProvider` (finished, upcoming) and `liveMatchesProvider`, with the same cache (2 min TTL), the same stale-while-revalidate refresh and the same offline behaviour;
  - `ClubCrest` (scaling and initials fallback), `StatusBadge`, the date helpers and `phaseLabel`.
- **Matchs tab:** a small `matchesSectionProvider` lets Accueil open a given section once. The tab otherwise behaves as before.
- **Large text and long names:**
  - text in the cards is capped at 1.3× (as the old strip was);
  - section titles stay on one line, shrinking instead of breaking a word;
  - the date and kickoff time always show in full, and only the group label gives way;
  - long club names are cut with an ellipsis.

### Launcher icon (`Logo Foot RDC_1.png`, 800 × 800 transparent)
The PSD and the SVG in the same folder are the same 800 px artwork (the SVG embeds a raster), so the PNG was used.

`tool/generate_launcher_icons.py` regenerates every existing file at its existing size. The logo is scaled with Lanczos, never redrawn.

- **Android adaptive icon:**
  - white background (`ic_launcher_background` = #FFFFFF; the logo's blue would vanish on the former #04a2da);
  - the foreground logo is 64 dp wide on the 108 dp canvas, measured so that even its outermost bump stays inside the 72 dp visible circle;
  - legacy `ic_launcher` (white rounded square) and `ic_launcher_round` (white circle).
- **iOS:** opaque white squares (no alpha channel), logo at 80 %.
- **Unchanged:** notification icon `ic_stat_footrdc`, splash screens, in-app logo, website favicon, bundle IDs, signing.

## 2. Tests

| Check | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 16 infos (pre-existing; was 17) |
| `flutter test` | **188 passed** (179 before + 2 match-event contract tests from the 10 Nov editor work + 7 new) |
| New `test/football/home_matches_test.dart` | results filter and order; fixtures order with live first; card content; long names at 2× text on a 320 px screen; both sections from the contract API, current season only, one request per window; « Tout voir » / « Calendrier » targets; API failure; Matchs opening on the asked section |
| Release builds | `flutter build apk --release` ✓ (69.1 MB); `flutter build ios --release --no-codesign` ✓ (36.1 MB); not uploaded |
| Device QA `integration_test/home_matches_qa_test.dart` (Production API, read-only) | **PASS** on iPhone 11, iPhone 18 Pro, Pixel 8 Pro, small Android (720 × 1280 at 320 dpi = 360 dp wide), iPhone 11 with accessibility-extra-large text |

QA covers:
- Accueil in light and dark mode;
- both sections, each scrolled horizontally on its own;
- a result card and a fixture card opening the match;
- « Tout voir » → Matchs › Résultats, « Calendrier » → Matchs › Calendrier;
- back on Accueil with the bottom bar and the page position kept.

Logs are in `logs/`. Device QA was run twice:
- **First run:**
  - the test's own tap landed under the header on the first iPhone run, a test issue;
  - on Android the football sections arrived after the light-mode check, so the taps weren't exercised;
  - very large text showed two real defects, fixed:
    - a title breaking inside a word;
    - the kickoff time being cut.
- **Final run:** every configuration passes the full flow (QA-HOME lines).

### Pre-release regression (build 38 candidate)

| Device | Suites | Result |
|---|---|---|
| iPhone 18 Pro | `app_qa_test`, `ui_ads_qa_test`, `ui_article_nav_qa_test` | PASS |
| iPhone 11 | `ui_redesign_qa_test`, `ui_nav_scroll_qa_test` | PASS |
| Pixel 8 Pro | `app_qa_test`, `ui_nav_scroll_qa_test` | PASS |

`ui_redesign_qa_test` first failed on iPhone 11 in dark mode: with the carousels loaded, the first story sits below the fold and the test tapped it off screen. The test now scrolls it into view (a test fix, not an app change), then passed. Screens in `prerelease/screens/`.

## 3. Screens

| Folder | Content |
|---|---|
| `screens/before/` | old Accueil (iPhone 11, Pixel 8 Pro, light/dark), old icon on the iPhone 11 home screen, Android drawer / app info / recent apps |
| `screens/after-iphone11/`, `after-iphone18pro/`, `after-pixel8pro/`, `after-android-small/` | Accueil top, both sections, scrolled carousels, result and fixture match screens, Tout voir, Calendrier, dark mode |
| `screens/after-iphone11-grand-texte/` | same with the largest accessibility text |
| `screens/after-icons/` | new icon on the iPhone 11 and iPhone 18 Pro home screens; Android app drawer (circle mask), app info, recent apps |

The before screens came from a temporary Git worktree at `a08abb6`, now removed.

The iOS home-screen captures put FootRDC on page 1 by editing the QA simulators' `IconState.plist`: `simctl` cannot swipe, and Simulator.app is not installed on this Mac.

## 4. API

**No backend change.** The endpoints used already existed and are used unchanged:
- `matches/finished` (limit 10, filtered in the app);
- `matches/upcoming` (limit 6);
- `matches/live`.

Both are queried with `season_id` of the current season from `currentSeasonProvider`, never a historical one.

Compared with the old strip, the only difference is the finished window (10 instead of 4). There are no extra endpoints and no extra requests when coming back to Accueil, thanks to the provider cache.

## 5. Limitations and notes

- **Data, not app:** on 10 Nov the featured article reports Vita Club – Les Aigles as postponed, but the API still lists match 6575 (11 Nov 14:00) as `scheduled`. The app shows what the data says. Mark it « Reporté » in WordPress (RDC Football → Matchs → Modifier) and it disappears from « Prochains matchs ».
- AF Ufalya Simba has no approved crest yet (initials shown). Uploading it is now possible on the website.
- The sections appear when their data arrives, a moment after the articles, as the old strip did.
- No live match was available during QA. The « En direct » badge is covered by the widget test, not observed on a device.
- iOS was checked on simulators only; physical-phone checks come with the next internal build.

## 6. Next steps (owner)

1. Install build 38 from TestFlight / Google Play internal testing on physical phones.
2. A public release (App Store review, Google Play production) needs a separate decision; the release tooling has no public path.
