# UI/UX audit

## State before the redesign

Bottom tabs: Accueil, À Savoir, Matchs, Classement, Enregistrés. Matchs and Classement each have Play-off, Groupe A, Groupe B sub-tabs driven by hard-coded SportsPress IDs. Search is pushed from the app bar. Drawer holds theme and notification settings.

## Problems

- No Édito destination; À Savoir takes a primary tab for a 12-article category.
- No clubs, players, match events or history in the released build.
- Football is split across two tabs with duplicated sub-tabs.
- Season is fixed in code; rotating a phase needs an app release.
- Heavy gradient navigation bar and card-in-card lists reduce density.
- Football data has only an in-memory cache, so a reopen shows a spinner.
- `requestPermission` blocks `main()` before the first frame.

## Keep

Theme tokens, connectivity banner, article detail, saved articles, ads placement, dark mode.

## Direction

See `docs/mobile-redesign/01-UX-AUDIT.md` and `02-TARGET-ARCHITECTURE.md`.

## Outcome

Tabs are now Accueil, Édito, Matchs, Linafoot, Plus. All the problems above are resolved except that notification permission is still requested at launch, though it no longer blocks the first frame. Before and after screens are in `docs/mobile-redesign/screens/`.
