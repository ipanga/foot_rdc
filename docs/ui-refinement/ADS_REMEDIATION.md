# AdMob: "Modified ad code: Resizing Ad Frames", 3 Nov 2026

Status: **code remediated, not yet released.** The restriction stays on the account until a release containing this
fix is live and the owner requests a review in AdMob.

## Setup

- SDK: `google_mobile_ads` 5.3.1 (AdMob only; no AdSense, no WebView ads, no mediation).
- Ad units unchanged (`lib/core/constants/ad_constants.dart`): one banner unit, one native unit; release builds use
  them, debug and profile builds use Google's published test units.
- `adFrequency = 9`: at most one native ad per 9 articles, never as the last item.

## Root cause (code review; Google does not name the screen)

| # | What the app did | Why it counts as resizing the frame |
|---|---|---|
| 1 | Native "medium" template placed in `Container(height: 320, …)` spanning the full list width (up to ~430 pt on phones, ~1000 pt on tablets), with rounded corners and `Clip.antiAlias` — in the feed, search and saved articles | Google's medium template frame is 320–400 wide and 320–400 high. A wider box stretches it; clipping crops the creative, AdChoices and attribution corners |
| 2 | A failed native ad stayed in the list as an empty, spinner-filled 320 px box | An ad frame with no ad |
| 3 | Anchored adaptive banner fixed directly above the bottom navigation on every tab and under every article | Not resizing, but Google discourages banners next to navigation controls (accidental clicks) and reviewers see both together |

## Remediation (`lib/shared/widgets/ads.dart`, commit `2731e94`)

- Native ads: the template sits in a `ConstrainedBox(min 320×320, max 400×400)`, centered, never clipped, no fixed
  height, no rounded mask. On a screen narrower than 320 the slot is not shown. A failed ad takes no space.
- A "PUBLICITÉ" label sits above each ad, outside its frame.
- Banners: the anchored banners are removed. Articles get one inline adaptive banner after the body, before
  "Clubs liés": `AdSize.getInlineAdaptiveBannerAdSize(width, 250)`, rendered at the size returned by
  `getPlatformAdSize()` after load, as Google's inline adaptive guide prescribes. Nothing is reserved before it loads.
- No new ad network, unit or format. No change to request frequency beyond removing the always-on banners.
- Tests: `test/shared/ads_test.dart` (frame within 320–400 at 320/358/390/768/1100 px, no clip inside the slot,
  label outside the frame, failed and narrow cases take no space, no ad widget outside `ads.dart`, no anchored banner).
  Device: `integration_test/ui_ads_qa_test.dart` with test ads only, never taps an ad. iPhone 18 Pro and Pixel 8 Pro:
  native frame 400×400 loaded; inline banner loaded. Screens: `screens/phase1-ads/`.

## Sources

- Google Mobile Ads Flutter, native templates: medium template min 320×320, max 400×400 (developers.google.com/admob/flutter/native/templates).
- Google Mobile Ads Flutter, inline adaptive banners: size from width, read the actual size after load (developers.google.com/admob/flutter/banner/inline-adaptive).
- AdMob policy, ad placement: avoid ads near navigation and interactive controls (support.google.com/admob/answer/6128877).
- AdMob & AdSense programme policies, ad code modification (support.google.com/admob/answer/48182). Google's public
  page does not describe "Resizing Ad Frames" in detail; the Policy Center entry for the app is authoritative.
- Reports of the same notice, with fixes: Google Mobile Ads SDK forum (groups.google.com/g/google-admob-ads-sdk/c/S1YVVijxBvM),
  googleads-mobile-flutter banner on Android (lightrun.com summary of the GitHub issue), B4X forum thread 112884.
  Common causes: frames cut off or not matching the ad's size, banners not regenerated after an orientation change.
  The inline banner here reloads when its width changes.

## Owner actions after the fixed version is published

1. Publish the release through the usual TestFlight/Play internal then store process (not done in this task).
2. AdMob › Policy center › the app's issue "Modified ad code: Resizing Ad Frames" › **Request review**, stating:
   native ads now use Google's template inside its documented 320–400 frame without clipping; anchored banners next
   to navigation were removed; one inline adaptive banner is shown at the end of articles at the SDK-reported size.
3. Keep the restriction notice and the review answer with this file.
