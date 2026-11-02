# Decisions

## 2026-11-01 Evolve the app, do not rewrite it
Reason: feature-first Riverpod structure, Dio client, theme and WordPress features are sound. Alternatives: new app, new state library. Rejected as cost without user benefit.

## 2026-11-01 Keep Navigator, add no router package
Reason: a tab shell plus named routes covers all screens and deep links. Alternative: go_router. Rejected: migration cost across WordPress screens.

## 2026-11-01 Typed domain models replace the generic FootballRecord
Reason: screens must not read JSON keys. The existing client, allowlist and cache are reused. Alternative: keep FootballRecord. Rejected: brief requires DTO, mapper and domain separation.

## 2026-11-01 Show provisional standings, never filter by `quality.publishable`
Reason: Production reports `publishable:false` for provisional rows, which are the normal state. The website shows them labelled provisional. The old client filter would give empty tables. Limitation: REST has no flag for a table hidden on the website for a material issue; the app cannot detect that. Alternative: wait for an additive API field; Production is read-only in this project, so that is a recommended follow-up.

## 2026-11-01 Live data uses server status only
Reason: the old "live gate" predates Production. Polling runs only while a live match is on screen and the app is in the foreground.

## 2026-11-01 No analytics SDK added
Reason: none exists today and the brief forbids an unnecessary one. A thin no-op interface is not added until an SDK is chosen.

## 2026-11-01 Screenshot QA through integration_test
Reason: same real navigation on iOS and Android, repeatable. Alternative: manual simulator tapping. Rejected: not repeatable.

## 2026-11-01 Project stays on CocoaPods
Reason: `google_mobile_ads` has no Swift Package Manager support and fails `pod install` when the global SwiftPM setting is on. Set per project in `pubspec.yaml`, leaving the machine's global Flutter config alone. Revisit when the ads plugin adopts SwiftPM; Flutter says disabling it will eventually stop being allowed.

## 2026-11-02 iOS support policy

**Minimum deployment target: iOS 15.0.** **Target device family: iPhone 11 and newer supported iPhones.**

Every target in the Xcode project is 15.0, including the app and the push extension. Correction: the entry here on 1 Nov said the minimum rose to 15.0. The app target was in fact 15.6, so 15.0 lowers it. No pod or plugin declares more than iOS 13. The Podfile raises older pods to 15.0, because Xcode 27 refuses less, and leaves alone any pod that needs more.

## 2026-11-02 Tab order and tab identity

Order, by owner requirement: Accueil, Édito, Matchs, Linafoot, Plus. Tabs are named by the `AppTab` enum, so moving one changes a single line and no code depends on a position.

## 2026-11-02 Tabs stay alive

Each tab is built on first visit and then kept, so a sub-tab, scroll position and season survive switching. Before this, every switch rebuilt the tab. Football data refreshes on returning to a tab or the app, and data still within its cache lifetime makes no request. Live polling runs only on Accueil and Matchs.

## 2026-11-01 Sponsor carousel hidden on Home
Reason: its three slots point at placeholder addresses on footrdc.com and render as an empty box. The code stays behind `_sponsorsReady` until real images and links exist.
