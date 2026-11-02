# Internal beta test plan

For build `5.12.10 (31)` or later, installed from TestFlight or Google Play internal testing. Nothing here publishes anything.

Record results in `TEST_MATRIX.md`: device model, OS version, build number, pass or fail, and a screenshot of any problem.

## 1. Physical phone checklist

Run once on an iPhone (iPhone 11 or newer preferred) and once on an Android phone.

| # | Check | Expected |
|---|---|---|
| 1 | First launch | Opens without a crash; tabs read Accueil, Édito, Matchs, Linafoot, Plus |
| 2 | Accueil | Headline, match strip, news, Linafoot snapshot; "Tout voir" opens Matchs; "Classements" opens standings |
| 3 | Édito | Only Édito articles, different from the Accueil feed |
| 4 | Matchs | Aujourd'hui, À venir and Résultats all load; open a finished match and see its events |
| 5 | Linafoot | Standings for the current season, Groupe A and Groupe B; compact and full table |
| 6 | Season | Switch to 2025–2026 and back; every Linafoot tab follows |
| 7 | Club | Open a club; check Aperçu, Actualités, Résultats, Calendrier, Classement, Effectif |
| 8 | Squad and player | On a club with a squad, such as TP Mazembe or Tanganyika, open a player |
| 9 | Follow | Star a club, close the app, reopen; it is still in Plus > Clubs suivis; unstar it |
| 10 | Search | Plus > Recherche, "Mazembe": clubs and articles appear; open each |
| 11 | Article | Open one from Accueil and one from Édito; images load; back returns to the same place |
| 12 | Club news | Open an article from a club's Actualités; it opens in the app |
| 13 | Deep links | Open these from Notes or Messages: `footrdc://club/2221`, `footrdc://standings`, and any footrdc.com article link |
| 14 | Tab state | In Matchs choose Résultats, go to Édito, come back; Résultats is still selected |
| 15 | Resume | Leave the app for a few minutes, return; the screen is intact and data refreshes |
| 16 | Offline | Turn on airplane mode, reopen a visited screen; saved data with a notice, not a raw error. Turn it off; data returns |
| 17 | Ads | Real ads appear, not "Test mode". Do not tap them repeatedly |
| 18 | Large text | Raise the system text size; nothing overlaps and tab labels stay whole |

Android only: the system back button leaves a pushed screen, then leaves the app from a tab.

A club with no squad, a missing crest or no live match today is a data gap, not an app defect, as long as the screen shows a clean message or initials.

## 2. One controlled push notification

Needs a phone with the internal build and notifications allowed. Uses the OneSignal dashboard. No API key goes into this repository, and no football notification is enabled.

1. In OneSignal, Audience > Subscriptions: find your test phone by device model and last-seen time, and add it to Test Subscriptions.
2. Messages > New Push. Choose Send to Test Subscriptions and select only that phone. Confirm the recipient count is 1 before sending.
3. Title and message: "Test interne FootRDC".
4. Under Additional Data, add key `link` with a current article link from footrdc.com. Leave Launch URL empty, because it can open the browser instead of the app.
5. Send, with the app in the background. Repeat once with the app fully closed.

| Step | Expected |
|---|---|
| Received | The notification arrives on the test phone only |
| Tap | The app opens |
| Destination | That article opens, whichever tab was last open |

## 3. Live match, first useful fixtures 4 Nov 2026 12:00 UTC

Never mark this PASS without a real match. If none is played, record NOT AVAILABLE.

Prepare before kickoff: open the match from Matchs > À venir, and note the time.

| # | Check | Expected |
|---|---|---|
| 1 | Pre-match | Scheduled state and correct kickoff time |
| 2 | Kickoff | Changes to live without reopening the app |
| 3 | Score | Follows the real score within about a minute |
| 4 | Events | Goals and cards appear in order, with correct clubs |
| 5 | Live on Matchs and Accueil | The match appears at the top of both |
| 6 | Background | Leave the app for 5 minutes, return; it catches up |
| 7 | Other tab | Go to Édito for 2 minutes, return to Matchs; it catches up |
| 8 | Full time | Changes to finished; the score stops updating |
| 9 | Results | The match appears in Résultats |
| 10 | Linafoot | The match appears in results; standings follow once the server recalculates |

Take a screenshot at steps 1, 2, 4 and 8.

When something looks wrong, compare with the same match on the footrdc.com website, then classify it:

| Observation | Classification |
|---|---|
| Website is also late or wrong | Provider or server data, not an app defect |
| Website is right, app is wrong after 2 minutes of refresh | App defect |
| Events missing for the whole match on both | Provider data gap |

SportsPress has no code path left in the app: `SPORTSPRESS_USAGE_REMAINING: 0`, enforced by the release gate.

## 4. Performance on physical phones

Enough to spot an obvious regression. Do not tune anything unless a result is clearly poor.

| Measure | How | Look for |
|---|---|---|
| Cold start | Stopwatch from tap to Accueil content, three times | Over 5 seconds on Wi-Fi |
| Warm return | Reopen after a minute | Any full reload spinner |
| Scrolling | Accueil, Résultats, full standings | Visible stutter |
| Images | Scroll Édito on mobile data | Blank images that never load |

For precise figures, connect the phone and run `flutter run --profile` on the release commit, then open DevTools.
