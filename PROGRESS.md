# FootRDC Progress Tracker

Status markers: `TODO` · `IN_PROGRESS` · `DONE` · `DEFERRED`.
Update this file as work moves between batches. The goal is resumability — a fresh Claude (or a fresh dev) should be able to read this file and know exactly what's left.

---

## Batch A — AdMob policy fix (✅ shipped)

**Trigger:** Google AdMob flagged `com.tootiyesolutions.footrdc` for "Modification du code d'une annonce : redimensionnement du cadre d'une annonce" on 2026-04-15. Reviewed version: `5.10.26`. Status was *Diffusion restreinte*.

| Status | Item | Notes |
|--------|------|-------|
| DONE | Centralize one banner in `HomeScreen` above `PremiumBottomNavBar` | New `lib/shared/widgets/persistent_banner_ad.dart` |
| DONE | Anchored adaptive banner; pre-allocate height before load | No more layout shift on `onAdLoaded` |
| DONE | Remove per-tab banners from News, Matches, Saved, Search | One banner instance instead of five |
| DONE | Drop in-body native ad on `ArticleDetailScreen` | Bottom banner only on the detail screen |
| DONE | Unify native-ad placeholder/loaded `Container` decoration | Only the child swaps; no visual snap |
| DONE | Delay first native-ad insertion until index ≥ 4 | Defensive guard in all four feeds |
| TODO | Bump `pubspec.yaml` version, build release AAB, upload to Play Console | Owner action |
| TODO | Click "Démarrer le processus d'examen" in AdMob Policy Center | Owner action; ~1 week review window |

---

## Batch B — UX restructure (✅ shipped)

**Goal:** Reflect that the competition is in Play-Off phase and re-balance the bottom nav.

| Status | Item | Notes |
|--------|------|-------|
| DONE | Reorder tabs in `MatchesListScreen` and `RankingsScreen` so Play-Off is index 0 | Group A and Group B remain reachable as tabs 1 and 2 |
| DONE | Replace `RankingsScreen` hardcoded league IDs with `ApiConstants.*` | Single source of truth |
| DONE | Add `ApiConstants.currentPhaseLeagueId` (= `playOffLeagueId` for now) | Future-proof for next phase rotation |
| DONE | New feature folder `lib/features/editorial/` (À Savoir tab) | Sources WP category `bon-a-savoir` |
| DONE | Resolver: `editorialCategoryIdProvider` | One-time `/wp/v2/categories?slug=...` lookup, cached for session |
| DONE | `fetchEditorialArticlesProvider` + `editorialCacheProvider` (per-category cache) | Mirrors news pagination + pull-to-refresh patterns |
| DONE | `EditorialListScreen` — slim copy of `NewsListScreen` minus carousel | Reuses `ArticleListItem` widget |
| DONE | HomeScreen 5-tab layout: `Accueil · À Savoir · Matchs · Classement · Enregistrés` | Recherche tab dropped; lifecycle refresh logic bumped accordingly |
| DONE | Search remains accessible via `NewsAppBar` icon (already routes to `SearchScreen`) | No new search UI; minimal change |
| DONE | Update `CLAUDE.md` to reflect the new structure | Tabs, editorial feature, default tab |
| DONE | `flutter analyze` clean | 60 pre-existing `info` lints; 0 new |
| TODO | Owner: smoke test on device — every tab, search icon, Play-Off default load, editorial pull-to-refresh | Manual verification before release |

---

## Batch C — Audit fixes (✅ shipped)

Findings from prior audit, scoped to "high-impact, low-risk" only.

| Status | Item | Why |
|--------|------|-----|
| DONE | `ranking_repository_impl.dart` — typed `on NetworkException catch (e)` returns `e.message` (French); fallback logs in debug + stable French generic | Surfaces clean French message instead of raw stack |
| DONE | `article_repository_impl.dart` — three local-Hive failure paths now return French messages; raw error logged in debug only | Same; this repo is local DB so no NetworkException path |
| SKIPPED | Remove brittle `error.toString().contains('socketexception')` checks in matches/news/search | Kept as defensive belt-and-braces — typed checks already run first; removing them risks false negatives. Revisit if a unified `Failure` hierarchy lands. |
| DONE | `@override` annotations on overridden fields in `ranking_model.dart` (11 fields across `RankingModel` + `TeamDataModel`) | Cleared 11 `annotate_overrides` lints |
| DONE | `saved_articles_screen.dart:202` — `if (!mounted)` → `if (!context.mounted)` in `Dismissible.onDismissed` | Cleared `use_build_context_synchronously` |
| DEFERRED | Move `firebase_options.dart` + `google-services.json` + `GoogleService-Info.plist` out of repo OR rotate keys | Security; needs owner decision before action — keys are exposed in repo history regardless |
| DEFERRED | `prefer_const_constructors`, `withOpacity` deprecation, `AutoDisposeFutureProviderRef` deprecation lints | Mechanical, ~30 sites; safer as a dedicated PR. Re-running `build_runner` clears the `.g.dart` ones. |
| DEFERRED | `overridden_fields` (11 sites in `ranking_model.dart`) | Requires restructuring the entity to use abstract getters; non-trivial. |

**Lint trend:** 60 issues → 46 issues. Zero new issues introduced; zero errors at any point.

---

## Batch E — Connectivity management (✅ shipped)

**Goal:** Detect online/offline state, surface a global UI signal, and auto-refresh the active tab when the network is restored.

| Status | Item | Notes |
|--------|------|-------|
| DONE | Add `connectivity_plus ^6.0.0` (resolved to 6.1.5) | Cross-platform interface state |
| DONE | `ConnectivityService` + `ConnectivityStatus` enum (binary) | `lib/core/network/connectivity_service.dart` |
| DONE | `connectivityStatusProvider` (Riverpod `StreamProvider`) | `lib/shared/providers/connectivity_provider.dart` — single OS subscription, deduped |
| DONE | `ConnectivityBanner` widget | Animated 0 ↔ 32dp; red offline / green "Connexion rétablie" on restore (~2s) |
| DONE | `HomeScreen` integration: banner above `PersistentBannerAd`; `ref.listen` for `disconnected → connected` triggers active-tab refresh | Single-edge trigger, no aggressive loops |
| DONE | DioClient retry: fixed 1s × 2 → exponential 1s/2s/4s × 3 | Better blip resilience without long waits when truly offline |
| DEFERRED | Disk-persistent caches for articles / matches / rankings (Hive boxes) | Big change; existing in-memory caches + saved-articles Hive box already cover the core offline UX |
| DEFERRED | Active reachability probing (captive portals, DNS) | Out of scope; interface state is sufficient for v1 |
| DEFERRED | "Slow connection" detection | Requires active probes; defer until there's a real signal it matters |

## Batch D — CI/CD setup (✅ workflow shipped, owner steps remain)

| Status | Item | Notes |
|--------|------|-------|
| DONE | `.github/workflows/ci.yml` | Triggers on push + PR to `develop` and `main`. Steps: checkout → Java 17 → Flutter stable (with cache) → `pub get` → `flutter analyze` → `flutter test --no-pub` → `flutter build apk --debug`. Concurrency group cancels older runs of the same ref. |
| TODO (owner) | Create `develop` branch from `main` and push it | Currently the remote has only `main`; locally there's also `dev01`. `git checkout -b develop main && git push -u origin develop` |
| TODO (owner) | Set branch protection on `main` requiring PR + green CI | GitHub UI: Settings → Branches → Add rule for `main` → require PR review + status check `flutter` |
| TODO (owner) | Verify the workflow runs on the first push to `develop` and read the logs | If `flutter analyze` fails on CI but passes locally, the most likely cause is a Flutter version drift — pin `flutter-version` in the workflow |
| DEFERRED | `dart format --set-exit-if-changed .` step | Existing code probably isn't `dart format`-clean; would block CI on first run. Add as a standalone "format the codebase" PR first. |
| TODO | Add a smoke test (`test/smoke_test.dart`) and remove the conditional in the workflow's test step | Currently CI skips `flutter test` when no `*_test.dart` files exist (Git doesn't track the empty `test/` skeleton). Drop the guard once real tests land. |
| DEFERRED | Pre-commit guard against committing Firebase config files to the index | Local hook; needs `husky_dart` or a shell script in `.git/hooks/pre-commit`. Tied to the deferred secrets work. |

---

## How to resume

If a Claude session is interrupted mid-batch:

1. Read this file top-to-bottom.
2. Find the first `IN_PROGRESS` row in the active batch — that's where the previous session stopped.
3. Use `git status` and `git diff` to see what files were already touched.
4. Resume from the next `TODO` after that row.
5. Mark each item `DONE` as it ships; bump the next one to `IN_PROGRESS` before starting it.
