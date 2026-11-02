# FootRDC mobile app — project context

Permanent context. Live progress is in `DEVELOPMENT_STATUS.md`, decisions in `DECISIONS.md`.

## Resume rule

At the start of every session: read this file, `DEVELOPMENT_STATUS.md` and `DECISIONS.md`; run `git status`; continue from `NEXT_ACTION`. Do not re-audit from zero unless the docs say they are stale.

After every significant unit: run the relevant tests, update the docs, commit, update `NEXT_ACTION`.

## Purpose

FootRDC is a French-first news and football app for Congolese football. Football data comes from the RDC Football platform on footrdc.com; news comes from WordPress.

## Data authority

| Data | Source | Rule |
|---|---|---|
| Fixtures, results, standings, clubs, squads, players, events | RDC Football REST `https://footrdc.com/wp-json/rdcfootball/v1` | Server is authoritative. Flutter never calculates standings or match state. |
| Articles, categories, authors, media | WordPress REST `https://footrdc.com/wp-json/wp/v2` | Never moved into RDC Football. |
| SportsPress | removed | `SPORTSPRESS_USAGE_REMAINING: 0` |

Production is read-only for this project: public GET requests only.

## Identifiers

- iOS bundle: `com.tootiyesolutions.footrdc`; Android application id: `com.tootiyesolutions.footrdc`.
- Version `5.12.10+30`. Do not change the semantic version during development.
- Competition 1 (Linafoot). Seasons are discovered from the API, never hard-coded: current flag `is_current`.

## iOS support

**Minimum deployment target: iOS 15.0.** **Target device family: iPhone 11 and newer supported iPhones.**

## Stack

Flutter 3.44.2, Dart 3.12.2. Riverpod (code-gen and manual), Dio (`DioClient`), Hive (saved articles), SharedPreferences (football cache), Firebase core and messaging, OneSignal, Google Mobile Ads, connectivity_plus. No router package: `Navigator` plus `onGenerateRoute`. No analytics SDK.

## Directories

- `lib/core` network, theme, constants. `lib/shared` shared widgets and providers.
- `lib/features/football` RDC Football: `data` (API, cache, mappers, repository), `domain` (models), `presentation`.
- `lib/features/{news,editorial,search,saved_articles,home}` WordPress features.
- `integration_test/` device QA with screenshots; run with `tool/qa_drive.sh`.
- `test/fixtures/production_contract.json` sanitized live API snapshot; refresh with `node tool/capture_production_contract.mjs`.

## Environments

Production API by default. `RDCF_API_ORIGIN` remains for local work. iOS simulator and Android emulator `Pixel_8_Pro` for QA.

## Non-negotiable constraints

- No store upload without explicit owner approval.
- No secrets in Git or chat. Signing, Firebase config and `key.properties` stay untracked.
- No mutation of Production. No change to the Sportmonks scheduler.
- ActuRDC, SportRDC and Tootiye are out of scope.
- `ios/Podfile.lock` carried an uncommitted change before this work began; do not commit it by accident.
- Bottom tabs, in order: Accueil, Édito, Matchs, Linafoot, Plus. Name them with `AppTab`, never by position.
- Édito stays a bottom tab. Design is FootRDC's own; never copy another app's assets.
- macOS has no `timeout`; long commands use `tool/qa_drive.sh` or `perl -e 'alarm N; exec @ARGV'`.
