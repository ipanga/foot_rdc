# UI/UX audit, 3 Nov 2026 (before changes)

Baseline: `screens/baseline/` (iPhone 18 Pro and Pixel 8 Pro: 25-step navigation from build 32 plus `*-base-*`;
iPhone 11 on iOS 27: `iphone11/`). Code at `077a341`.

## Advertising (Google AdMob, `google_mobile_ads` 5.3.1; no AdSense or WebView ads)

| # | Finding | Evidence |
|---|---|---|
| A1 | Native "medium" template forced into a fixed 320 px high, full-width box, clipped by rounded corners (`Clip.antiAlias`). Google's medium template frame is 320–400 wide and 320–400 high; on phones wider than 432 pt and on tablets the frame is stretched beyond 400, and the corners crop the creative. Most likely cause of "Modified ad code: Resizing Ad Frames" | `news_list_screen.dart`, `search_screen.dart`, `saved_articles_screen.dart` `_buildNativeAdItem` |
| A3 | Anchored banner pinned directly above the bottom navigation on every tab and under every article: discouraged next to navigation controls (accidental clicks) | `home_screen.dart`, `article_detail_screen.dart`, `persistent_banner_ad.dart` |
| A4 | Native ad code duplicated three times | same files |

## Notifications

| # | Finding |
|---|---|
| A2 | `NotificationNotifier` calls OneSignal `optIn`/`optOut` on every start from a derived value. A fresh install without permission yet is opted out silently and stays opted out after granting permission. Reproduced: opening the drawer triggers `optOut` (`base-extra-pixel.log`) |
| A5 | Permission requested at every launch, even when the user turned notifications off in the app |
| A6 | One switch mixes device permission and app preference; no way to reach system settings after a refusal |

## Navigation and layout

| # | Finding |
|---|---|
| N1 | Home drawer duplicates Plus (theme, notifications, about) |
| N2 | "Thème et notifications" reuses the drawer inside a page: a half-width panel, unaccented labels ("Theme", "Systeme", "A propos") |
| N3 | Article back, save and share buttons scroll away with the header image; no back control mid-article |
| N4 | Matchs (Aujourd'hui, À venir, Résultats) and Linafoot (Calendrier, Résultats) duplicate match lists |
| N5 | Home headline area shows an empty tinted block while loading |

## Tests

No tests for ad frames, theme persistence, notification preferences or article navigation. Covered today: football data,
widgets, tabs, links, club news (87 tests) and device navigation.
