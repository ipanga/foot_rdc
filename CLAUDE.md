# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter app (Dart SDK `^3.9.2`) for FootRDC — a football news / matches / rankings reader backed by the public WordPress + SportsPress REST API at `footrdc.com`. Targets Android, iOS, web, macOS, Windows, Linux. Push via OneSignal, ads via Google Mobile Ads, crash/auth init via Firebase, local storage via Hive.

## Commands

```bash
flutter pub get                                    # install deps
flutter run                                        # run on the connected device/simulator
flutter analyze                                    # static analysis (uses analysis_options.yaml)
flutter test                                       # run all tests (test/ is currently mostly empty)
flutter test test/path/to/file_test.dart           # run a single test file
flutter test --name "substring"                    # run tests whose name contains substring

# Code generation — REQUIRED after changing any @riverpod provider or @HiveType model
flutter pub run build_runner build --delete-conflicting-outputs
flutter pub run build_runner watch --delete-conflicting-outputs   # keep regenerating during dev

flutter build apk                                  # release Android build
flutter build ios                                  # release iOS build
```

Generated files (`*.g.dart`) live next to their sources and are checked in — keep them in sync with the source after edits. Current generated files: `features/news/data/models/article_model.g.dart`, `features/news/presentation/providers/news_providers.g.dart`, `features/matches/presentation/providers/match_providers.g.dart`, `features/rankings/data/models/ranking_model.g.dart`.

## Architecture

### Feature-first Clean Architecture
`lib/` is split into three top-level layers:
- `lib/core/` — cross-cutting infra: `constants/` (API URLs, league/season IDs, AdMob unit IDs), `network/` (`DioClient`, `NetworkExceptionHandler`, sealed `NetworkException` hierarchy with French user-facing messages), `errors/` (`Failure` for `Either`-returning repos, `LoggerRiverpod` provider observer), `theme/` (Material 3 light/dark), `utils/`.
- `lib/shared/` — UI/state shared across features: `providers/` (theme, notifications), `widgets/` (`PremiumBottomNavBar`, `PremiumTabBar`, `AppDrawer`, `CustomSearchBar`, `AppCard`, `AppSnackbar`, `NewsAppBar`, `AnimatedWidgets`).
- `lib/features/<feature>/` — one folder per feature (`home`, `news`, `editorial`, `matches`, `rankings`, `saved_articles`, `search`), each with `data/{datasources,models,repositories}`, `domain/{entities,repositories,usecases}`, `presentation/{providers,screens,widgets}`. Some feature folders (e.g. `matches`, `saved_articles`, `editorial`) keep the data/domain shells but currently put their fetching logic directly in `presentation/providers/` — follow the existing pattern within a feature when extending it. The `editorial` feature reuses the `Article` entity from `news/` for its content stream — keep them in sync if `Article` shape changes.

Some features expose a barrel file (`features/home/home.dart`, `features/saved_articles/saved_articles.dart`); `core/core.dart` and `shared/shared.dart` are partial barrels — prefer importing the concrete file when the export isn't listed there.

### State management — Riverpod (mixed styles)
- **Code-gen providers** (`@riverpod` from `riverpod_annotation`) are used for async fetchers, e.g. `fetchArticlesProvider`, `fetchMatchesProvider`, `fetchMatchesByLeagueProvider`. After editing these, re-run `build_runner` so the `.g.dart` regenerates.
- **Manual providers** (`Provider`, `StateProvider`, `StateNotifierProvider`) are used for singletons and UI state, e.g. `dioClientProvider` in `core/network/dio_client.dart`, `currentPageProvider` in `features/home/presentation/providers/home_providers.dart`, the cache notifiers (`articleCacheProvider`, `matchCacheProvider`, `rankingCacheProvider`).
- The cache `StateNotifier`s (one per data feature) hold the paginated list, `currentPage`, `hasReachedEnd`, and `lastRefreshTime`, and expose `isCacheValid({validDuration})`. `HomeScreen` invalidates them on tab switch and on `AppLifecycleState.resumed` if the cache is older than ~2 minutes — follow this pattern when adding new list features.
- `ProviderScope` is registered with `LoggerRiverpod` as an observer in `main.dart`.

### Networking
All HTTP traffic goes through `DioClient` (`core/network/dio_client.dart`), exposed as `dioClientProvider`. It sets `baseUrl = ApiConstants.baseUrl` (`https://footrdc.com/wp-json`), 30s timeouts, a debug-only `LogInterceptor`, and a `_RetryInterceptor` that retries connection/timeout errors with **exponential backoff** (1s → 2s → 4s, max 3 retries). Errors are caught and converted via `NetworkExceptionHandler.handle` into the sealed `NetworkException` types (`NoInternetException`, `TimeoutException`, `ServerException`, `ClientException`, `NotFoundException`, `UnauthorizedException`, `RequestCancelledException`, `UnknownException`) with French messages — surface those messages directly in UI. `core/network/http_client_provider.dart` is a deprecated re-export shim; new code should import `dio_client.dart` directly.

### Connectivity
OS-level network state is exposed by `ConnectivityService` (`core/network/connectivity_service.dart`) via `connectivity_plus`, mapped to a binary `ConnectivityStatus` (`connected` / `disconnected`). The Riverpod entry point is `connectivityStatusProvider` (`shared/providers/connectivity_provider.dart`) — a `StreamProvider<ConnectivityStatus>` that emits the current state on subscribe and re-emits on every interface change. `HomeScreen` `ref.listen`s on it and triggers a single-edge cache refresh of the active tab on `disconnected → connected`. The `ConnectivityBanner` widget (`shared/widgets/connectivity_banner.dart`) renders above the persistent ad in `HomeScreen`'s bottomNavigationBar Column — height 0 dp online, ~32 dp red "Pas de connexion internet" when offline, briefly green "Connexion rétablie" on restore. Per-screen empty/error states already cover the no-cache offline case via existing retry buttons.

API endpoints and the active league/season IDs (`currentSeasonId`, `groupeALeagueId`, `groupeBLeagueId`, `playOffLeagueId`, `currentPhaseLeagueId`, `bonASavoirCategorySlug`) live in `core/constants/api_constants.dart` — update there, not inline. The editorial feature resolves `bonASavoirCategorySlug` to a numeric category ID at runtime via `editorialCategoryIdProvider` (`features/editorial/presentation/providers/editorial_providers.dart`); the result is cached for the session.

### Local storage — Hive
`main()` calls `Hive.initFlutter`, registers `ArticleModelAdapter` (typeId 0), and opens `Box<ArticleModel>('articles')` before `runApp`. Saved articles flow: `ArticleLocalDataSource` (raw box access) → `ArticleRepositoryImpl` (returns `Either<Failure, T>` via `dartz`) → use cases in `features/news/domain/usecases/`. Box keys are `article.id` (legacy entries used auto-generated keys — `deleteArticle`/`isArticleSaved` already handle both). If you add a new Hive model, bump `typeId`, register its adapter in `main`, and re-run `build_runner` for the `.g.dart`.

### Navigation & shell
There is no router package. `HomeScreen` (`features/home/presentation/screens/home_screen.dart`) is the root; it holds an `IndexedPages`-style list driven by `currentPageProvider` (a `StateProvider<int>`) and renders `PremiumBottomNavBar` with five tabs: **Accueil (0) → À Savoir (1) → Matchs (2) → Classement (3) → Enregistrés (4)**. Tab order is wired to the cache-refresh logic in `HomeScreen`'s lifecycle observer (`switch (currentPage) { case 0: articles; case 1: editorial; case 2: matches; case 3: rankings; }`) and to the `onTap` handler — keep them aligned if you reorder.

`SearchScreen` is **not** a tab — it's a standalone route pushed via `Navigator.push` from `NewsAppBar`'s search icon (visible on Accueil). Don't add it back to the bottom nav.

The **Matchs** and **Classement** tabs are themselves tab-bars with three sub-tabs each: **Play-off (0) → Groupe A (1) → Groupe B (2)**. Play-off is the default because the competition is in Play-Off phase. The mapping is centralised at `_tabLeagueIds` inside each screen and ultimately backed by `ApiConstants.currentPhaseLeagueId` (= `playOffLeagueId` today). Bump that constant when the phase rotates.

### Third-party services initialized in `main.dart`
- **Firebase** — `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` from generated `firebase_options.dart`; config in `firebase.json`.
- **OneSignal** — initialized with a hardcoded app ID; subscription/permission/foreground/click listeners are attached in debug only.
- **Google Mobile Ads** — `MobileAds.instance.initialize()`. Ad unit IDs are in `core/constants/ad_constants.dart` and switch automatically between Google's test IDs in debug and the real IDs in release based on `kReleaseMode`.

## Conventions

- Lints in `analysis_options.yaml` extend `flutter_lints` and additionally enforce `prefer_const_*` rules — keep widgets and literals `const` wherever possible.
- The app version in `pubspec.yaml` follows a date-based scheme (`YY.MM.DD+build`, e.g. `5.12.09+29`); bump both parts when shipping.
- The codebase uses Lato/Poppins/Saira/Oswald/OpenSans fonts (declared in `pubspec.yaml`); reference them via `AppTextStyles` / `AppTheme`, not by string.
- User-facing strings are in French (e.g. `NetworkException` messages, nav labels). Match that when adding UI copy.

## Outdated docs

`MATCH_FEATURE.md` and `SWIPE_REFRESH_LOAD_MORE.md` predate the feature-first refactor — they reference paths like `lib/features/domain/` and a `fetchMatchesProvider` in `main.dart`. The matches feature now lives under `lib/features/matches/` and the provider is in `features/matches/presentation/providers/match_providers.dart`. Trust the code over those docs.

## Project tracker

`PROGRESS.md` at the repo root is the source of truth for what's shipped vs. pending across the active work batches (AdMob fix, UX restructure, audit fixes, CI/CD). Update it as items move; it's how a fresh session resumes mid-task.
