# Custom mobile ads (5 Nov 2026) — progress

Owner brief: remotely managed advertiser banners (« Publicités mobiles » in WordPress), two native slots in the app,
AdMob untouched. Full report, API contract, security and SOP: `migration_ovhcloud/docs/review/footrdc-mobile-ads-20261105/README.md`.

Branch: `feat/app-refinements-20261106`, on top of the uncommitted 6 Nov refinements (nothing discarded; a copy of
that working tree was taken first). Not committed. Backend: `rdc-football-platform` branch `feat/mobile-ads`.

| # | Scope | Status |
|---|---|---|
| 1 | WordPress plugin `rdc-football-mobile-ads` 0.1.1 (private post type + meta, admin list/edit/preview/duplicate/pause, validation, audit, REST `GET /rdcfootball/v1/mobile-ads`) | done; runtime suite 72; gate PASS |
| 2 | App: `lib/features/promotions/custom_ads.dart` (model, source, cache/refresh notifier), `custom_ad_slot.dart` (slot, article split) | done |
| 3 | Placements: Home after the 3rd story (`news_list_screen.dart`); article after the 2nd paragraph when ≥ 3 blocks follow (`article_detail_screen.dart`, HTML block moved into `articleHtml()`); prefetch in `main.dart` | done |
| 4 | Staging (48 h session, auto-stop Sat 7 Nov 16:15 UTC): install, scenarios, security, rollback/re-apply, update to 0.1.1 | done |
| 5 | Tests: 20 widget/unit tests; device QA Pixel 8 Pro, iPhone 18 Pro, iPhone 17e (ads, no ads, light/dark); Android by hand (browser intent, broken image, offline, 130 % text) | done |
| 6 | Found and fixed: admin « Enregistrer » blocked by WordPress's leave-page guard (0.1.1); a slot built before the first answer stayed empty for that screen → late answers fill slots still below the screen | done |

Device QA: `integration_test/custom_ads_qa_test.dart` with
`--dart-define=FOOTRDC_ADS_BASE=http://127.0.0.1:8472/wp-json/rdcfootball/v1 --dart-define=FOOTRDC_PUSH_BASE=https://127.0.0.1:9/qa-no-registration`
and `QA_EXPECT_ADS=true|false`, against the dev stack seeded with QA campaigns (`rdcf-dev wp` + images in
`wp-content/uploads/rdcf-qa/`). Screens: `screens/`.

Not done: Production install (owner approval), physical phones, statistics (deliberately none).
