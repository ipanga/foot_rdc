# Test matrix

Results on commit `5f79298`, 1 Nov 2026.

| Layer | Scope | Result |
|---|---|---|
| Unit and widget | Mapping, repository, cache, status, states, polling, deep links, favorites | 66 passed, 0 failed |
| API contract | `test/fixtures/production_contract.json`, sanitized live capture | Pass, inside the 66 |
| Responsive widget | 320, 360, 768 wide; text 100% and 130%; light and dark; 60 px message; tall keyboard | Pass, inside the 66 |
| Integration iOS | iPhone 18 Pro, 20 steps | Pass, 0 exceptions, 0 overflows |
| Integration iOS small, dark | Second iPhone simulator, 20 steps | Pass, 0 exceptions, 0 overflows |
| Integration iPad | iPad simulator, 20 steps, portrait | Pass, 0 exceptions, 0 overflows |
| Integration Android | Pixel 8 Pro, 20 steps | Pass, 0 exceptions, 0 overflows |
| Integration Android narrow | 360x640 dp, text 130%, 20 steps | Pass, 0 exceptions, 0 overflows |
| Failure states iOS and Android | Stale cache, offline, timeout, HTTP 500, invalid response | Pass, no raw error text |

The 20 steps cover Home, Matchs (three views), match detail, the Linafoot tabs, compact and full standings, club directory, club search, club overview and squad, season 2025–2026, Édito, article, Plus, unified search, and club and standings deep links.

Failure states are injected at the HTTP layer on the device. The cache and screens are real; the network was not physically cut.

## Not exercised on a device

- A match in progress: none was being played. Polling is covered by widget tests.
- A delivered push notification, and tapping one.
- Following a club, opening a player page, and opening an article from club news: widget tests only.
- Landscape.
- Physical phones. All runs used simulators and emulators.
