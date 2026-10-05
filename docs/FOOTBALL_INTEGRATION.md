# RDC Football Core Integration

## Status

Phase6 stable non-live implementation and staging acceptance PASS. Operator-approved immutable backend `33f84cbfe798f98688c29bfe884fc0b37b6782fc` is deployed to staging (Core0.4.1, schema0.3.0 unchanged). Actual Group A/B/Playoff metadata and31teams across25+6distinct pages pass. Backend feature `codex/flutter-api-integration` and app feature `codex/rdc-football-integration` remain unmerged; no production distribution.

REAL LINAFOOT LIVE VALIDATION: PENDING

This branch extends the existing app, based on develop66fbc6c, not a replacement application. Editorial, news, saved articles, ads, connectivity, Firebase and OneSignal remain intact. No release/signing/notification configuration change.

## Run And Environments

```sh
flutter pub get --offline
flutter test --no-pub
flutter analyze --no-pub --no-fatal-infos
flutter run --dart-define=RDCF_ENV=staging
flutter build apk --debug --no-pub --dart-define=RDCF_ENV=staging
```

Staging origin defaults explicitly to `https://staging.sportrdc.com`, namespace `/wp-json/rdcfootball/v1`. Current local IDs1competition/1season can be specified with `RDCF_COMPETITION_ID`/`RDCF_SEASON_ID`. They are NOT provider league824/season26546. Device timezones apply only to displayed UTC kickoff.

For Local: `RDCF_ENV=development`, `RDCF_API_ORIGIN=http://sportrdc-dev.local`. Device/emulator DNS and network access to the Mac must be configured by the operator; localhost on a device is not the Mac. Production requires an explicitly approved Core HTTPS origin (`RDCF_ENV=production` plus `RDCF_API_ORIGIN`); staging/local cannot masquerade as production. No production backend/distribution enabled. Without a flag, `RDCF_ENV=off` leaves legacy football tabs in place.

## Modules

- `lib/features/football/data/`: fixed-origin allowlisted client, sanitized failures, bounded shared_preferences public-JSON cache, repository/relationship/pagination decoding.
- `domain/football_models.dart`: deeply immutable Core records, safe nullable integer/text accessors, UTC kickoff, null versus zero scores, numeric metrics, local phases/pages/context and central live gate.
- `presentation/`: Riverpod providers, French/English strings, five native screens and reusable lazy/paged lists, stable-size logos, partial/empty/retry/offline widgets.

No HTTP inside widgets. Existing Dio retry behavior remains; football payload logging is disabled. Public static CDN logos/photos are allowed, provider APIs are not. Business IDs and named Navigator routes are local Core IDs only.

Validated local SDK is Flutter3.44.2/Dart3.12.2. Offline resolution adjusts SDK-pinned matcher/meta/test_api (lock requires Dart>=3.10); no new package. Flutter automatically adds `android.builtInKotlin=false`/`android.newDsl=false` for the existing Android setup; no AGP/Kotlin/plugin upgrade or signing change.

Competition consumes competition detail, seasons, stages, groups, scoped paginated teams, filtered match collection and standings. Directory requests two25-row pages for31teams. Team uses detail plus matches/next-match/results/standings/squad/statistics. Schedule uses team matches `view=upcoming|finished`. Squad metrics are nested in the aggregate response, never one request per player. Match Center uses today/upcoming/finished; detail includes optional partial events. Dedicated events route is contract-tested; HTML `/match-center/view` is not a native mobile data source.

## French And Missing Data

App defaults French. FootballStrings delegates have French/English key parity, native Material/Cupertino date/localization delegates and presentation-only canonical status/event mappings. Unknown machine values remain safely generic. Null scores/metrics/fields never become invented zeros. Missing standings are shown as under review, and only `quality.publishable=true` rows render. Squads/events/statistics explicitly remain partial; no final/official standings claim.

Metadata/team/squad/history cache1hour, match/next-match2minutes; public non-live offline fallback24hours maximum with visible cached label. Cache is bounded100entries; expired/corrupt/future timestamp data is ignored. Refresh/retry/dedup handle poor networks; failures are curated French messages, not WordPress/provider/SQL internals. Directory is independent of phase endpoints; joined Match Center rows avoid extra metadata/team calls.

Standings always recheck Core and are never served from an offline cached approval. Responses containing live matches cannot become an old offline score. API redirects are disabled so the fixed-origin boundary cannot redirect to a provider.

## Live Gate

Live requires both explicit feature approval AND validated readiness. Phase6 environment configuration always remains unvalidated; no dart-define bypass. Live tab/current scores/minutes/events are hidden; ordinary FT results and today/upcoming/finished remain available. Future foreground live-detail polling is60seconds to Core only, cancels on background/dispose/completion, avoids overlap and warns on failure/staleness. Expired live detail is not served as offline current data. No scheduler/provider/readiness changes.

## Tests And Fixtures

```sh
node tool/capture_football_contract.mjs
# Optional explicit refresh of three public static logo fixtures:
node tool/capture_football_contract.mjs --images
flutter test --no-pub
# Explicit read-only actual staging decoder smoke:
flutter test --no-pub test/football_staging_smoke_test.dart --dart-define=RDCF_STAGING_SMOKE=true
# Full staging acceptance (approved API deployed):
# --dart-define=RDCF_STAGING_ACCEPTANCE=true
```

The capture tool performs21public read-only Core GETs only, rejects private fields, records UTC/per-response timing and keeps positive local IDs. Stage/group and phase-specific results are actual deployed staging captures. Logo mode requests only validated public CDN image URLs; no provider APIs. Regression tests use in-memory Dio transport/cache and captured JSON/logos, not live provider traffic. Synthetic next-match/events/live cases test future/absent behavior, not sporting evidence.

40regression tests PASS; the two actual network tests are opt-in/skipped by default, and separately both PASS against the immutable staging release (9seconds). Baseline smoke16Core GETs plus actual phase/full-directory acceptance. New module/tests/client analyzer0issues; whole app46existing informational findings, no errors/warnings. Android staging debug APK compilation PASS (11.4second incremental rebuild). No existing automated app tests were present. iOS bundle `com.tootiyesolutions.footrdc`, Runner15.6 discovered; iOS build/signing/distribution not claimed.

Backend full regression1,226assertions PASS. Staging161public GETs verify446results and all42ordinary TP Mazembe matches across pagination, every required metadata/team/Match Center section and valid empty/error states. Three existing validation pagesHTTP200, anonymous REST/admin writes rejected404/400. Public callback audit20routes attempts0HTTP; all Core/mapping/snapshot/conflict/configuration digests unchanged and existing scheduler advances without configuration change. Direct Sportmonks/API-Football API calls0; static logos are not provider API requests.

Widget tests use the app theme/Poppins/native icons and actual public logo pixels, verify widths320/375/768/1440 at text scales1/1.5, and output QA PNGs in `/private/tmp/rdcf-phase6-screenshots`. Request-count/cached-rebuild and fixture rendering/scroll measurements are smoke checks, not release-device performance certification. Live behavior remains gated in every normal build.

## Next Gate

Observe a genuine Linafoot live match and validate Sportmonks latency before later enabling mobile live scores. Do not merge either feature branch automatically, change scheduler/readiness/protected data, or begin iOS release/device distribution or production/FootRDC deployment. Default build remains RDCF_ENV=off; explicit staging builds opt in.
