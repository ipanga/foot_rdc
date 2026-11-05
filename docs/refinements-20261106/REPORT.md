# App refinements — report (6 Nov 2026)

Branch `feat/app-refinements-20261106` (from `111a0aa`, 5.12.11 (34)), working tree, not committed or pushed.
Nothing deployed, nothing uploaded, OneSignal untouched, Production notifications stay in mode `test`.

## Changes

| Area | What changed | Files |
|---|---|---|
| Favourite clubs | Optional « Vos clubs » screen over Home, offered once to users who follow no club (fresh install or upgrade): real season clubs from the RDC Football API with crests (initials when missing), search (accent-insensitive), several choices, « Plus tard » / « Continuer (n) » / close. Not shown when clubs are already followed, when the clubs cannot be loaded (offline, API error: next launch), or when a notification/link opened another screen. Followed clubs stay keyed by canonical team id; clubs no longer in the season stay listed (« Hors de la saison en cours ») and removable. Plus › Clubs suivis: « Modifier », empty state « Choisir mes clubs » | `features/onboarding/club_onboarding.dart`, `football/presentation/widgets/club_picker.dart`, `more/more_screen.dart`, `more/settings_screens.dart`, `football/presentation/providers.dart` |
| Notification defaults | Once club alerts are on: kickoff, final result, postponement/cancellation ON; goals and the 1-hour reminder OFF. Only explicitly changed settings are kept (`rdcf_push_explicit`); everything saved by 5.12.11 (34) counts as explicit, and the OneSignal-era « off » is kept, so nothing disabled is re-enabled. « Articles à la Une » independent | `core/notifications/push.dart` |
| Permission | No system dialog at launch any more. Asked in context: onboarding « Alertes de match » + Continuer, or turning on news / club alerts / the master switch in Plus › Notifications. A refusal after Continuer offers « Autoriser » | `main.dart`, `shared/providers/notification_provider.dart` |
| Bottom tabs | Pill background removed. Selected: filled icon, bold label in FootRDC red (4.5:1 shade), 28×3 rule on the bar's top edge; others outlined grey. Order unchanged | `shared/widgets/premium_bottom_nav_bar.dart` |
| Article category | `CategoryLabel`: red small capitals, no box. Detail page; cards « RDC · 10:45 » (badge removed from the photo); featured card in white. « À la Une » keeps its accent | `shared/widgets/category_label.dart`, `news/.../article_detail_screen.dart`, `article_list_item.dart`, `core/utils/string_utils.dart` |
| Home header | The splash logo has ~20 % transparent margin (508×504, mark 310×310): new trimmed `assets/images/logo_mark_footrdc.png` at 26 px; wordmark centred on its capitals; header not scaled with system text | `shared/widgets/news_app_bar.dart` |
| Notification hardening | Registration sends `app_version` « 5.12.11 (34) » (package info) and `permission`; `prefs.enabled` is false while the device refuses (the server stops sending); permission re-read on every resume (any screen); no in-app banner while notifications are refused or off, nor for a message more than 2 min old. Token refresh, deep links, follows and dedup unchanged | `push.dart`, `push_messages.dart`, `notification_provider.dart` |
| Found during QA | Home headline showed raw `&rsquo;` (« l&rsquo;AS ») | `news_list_screen.dart` |
| QA support | `FOOTRDC_PUSH_BASE` overrides only the notification server (device QA never registers on Production); `Qa.launch(clubOnboarding:, resetClubs:)`; skip-reason log `club-onboarding: …` | `push.dart`, `integration_test/` |

New dependency: `package_info_plus` ^9.0.1.

## Backend / API

None required. Notify 0.1.1 (Production, mode test) already stores `app_version` and `prefs.enabled`, and ignores the
extra `permission` field. Old match events cannot fire after an update: the server's first-seen baseline and dedup
keys are unchanged, and the app replays nothing. Released apps (34 and earlier) are unaffected.

## Tests

| Layer | Result |
|---|---|
| `flutter analyze` | 17 infos, 0 warnings, 0 errors (unchanged) |
| `flutter test` | 150 passed, 0 failed (was 125): +10 onboarding, +13 notification defaults/permission/banners, +1 tab, +3 category |
| Pixel 8 Pro emulator (Android 16) | redesign (light + dark) PASS; onboarding PASS; onboarding « Plus tard » PASS; navigation 17/17 PASS; notifications screen PASS (FCM token obtained); article navigation PASS; club news PASS; 0 exceptions, 0 overflows |
| iPhone 18 Pro simulator (iOS 27) | same set, all PASS |
| iPhone 17e simulator (iOS 27) | redesign PASS; onboarding PASS; « Plus tard » PASS |
| Android by hand (adb, debug build) | fresh install: no dialog at launch, onboarding shown; 2 clubs + alerts → system dialog only then → Allow → Notifications « Activées », kickoff/result/changes on, reminder/goals off; real restart: not offered again; refusal → « Non autorisées par l’appareil », grant while in background → « Activées » on resume; offline fresh install → Home with the offline message, no onboarding (log « clubs unavailable … next launch »), online relaunch → offered; dark mode + 130 % text: onboarding and Home without overflow |
| Header alignment (pixels, centre of capitals − centre of mark) | iPhone 18 Pro −6.0 → 0.0; Pixel −6.5 → −0.5; iPhone 17e 0.0 |
| Backend | not run: no backend change (last gate PASS 4 Nov, 38 suites) |

Screens: `screens/before/{pixel,p18}/` (5.12.11 (34)), `screens/after/{pixel,p18,i17e,manual}/`, and side-by-side
`compare-home-article-android.jpg`, `after-onboarding-android.jpg`, `after-dark-notifications-android.jpg`,
`after-permission-dark-text130.jpg`.

## Limitations

- iOS system permission dialog not exercised on the simulator (no window to answer); covered on Android by hand and
  by widget tests. Physical iPhone check advised with the next build.
- New installs no longer get a permission prompt at launch, so they receive nothing (OneSignal included) until they
  turn alerts on. This is the requested behaviour; it lowers the share of opted-in new users.
- The onboarding is not re-offered after « Plus tard » (by design); users go to Plus › Clubs suivis.
- If the app is killed while the permission dialog is open after « Continuer », the clubs are saved and the offer is
  not repeated (state `followed`), but the alert choice depends on the answer given to the system.
- The light-theme switch « off » track is very pale (existing theme, unchanged).

## Next internal beta

5.12.11 (35) from this branch after review: TestFlight Internal + Play internal (`bundle exec fastlane beta_all`,
needs the branch merged into `feat/rdc-football-mobile-redesign` and pushed). Then on the owner phones: fresh
install onboarding, iOS permission dialog, defaults in Plus › Notifications, and one Production test message to
confirm `app_version` « 5.12.11 (35) » appears in `/root/prod-test.sh list`. Release notes (draft): « Choisissez vos
clubs dès l’ouverture, alertes de match plus utiles par défaut, navigation et catégories plus lisibles. »
