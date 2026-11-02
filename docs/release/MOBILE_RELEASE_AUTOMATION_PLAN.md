# Mobile release automation

Internal beta only: TestFlight internal testers and Google Play internal testing. No lane can reach App Review or a public Google Play track, and `test/release_safety_test.dart` fails if one is added. Public release is not authorized.

## Commands

Run from the repository root, on the Mac's default Ruby. Run `bundle install` once first.

| Command | Does |
|---|---|
| `bundle exec fastlane ios beta` | Gates, signed IPA, TestFlight internal only |
| `bundle exec fastlane android internal` | Gates, signed AAB, Google Play internal testing only |
| `bundle exec fastlane beta_all` | Both, from one source revision |

Add `dry_run:true` to any of them to run the gates and builds without uploading. It needs no store credentials, and when they are set it also runs the read-only store gates.

To raise the build number: `tool/set_build_number.sh <number>`, commit, push. Do not edit the number by hand: the push extension must carry the same version.

## Gates

Any failure stops the lane before upload.

| Gate | When |
|---|---|
| Store credentials present, private file, paths valid | First, before any build |
| Clean tree, release branch, HEAD equals the pushed commit | Always |
| Release notes present; no SportsPress or debug endpoint in `lib`; Production API default | Always |
| `flutter analyze`, `flutter test` (includes release safety tests) | Always |
| iOS release build; bundle IDs, version and minimum iOS 15.0 on app and extension | Always |
| Signed AAB; signature equals the FootRDC upload certificate, never the debug key | Always |
| Build number above every TestFlight build and Google Play track | Before any build, when credentials are set |
| Apple portal access, local certificate on the portal, push and App Group capabilities | Before any build, when credentials are set |
| IPA push entitlement is `production` | Upload only |
| Owner has confirmed export compliance | Before any build, when credentials are set |

## Owner setup

Values go only in `~/.footrdc-release/release.env`, outside the repository. Never paste them in chat.

```bash
mkdir -m 700 ~/.footrdc-release
touch ~/.footrdc-release/release.env
chmod 600 ~/.footrdc-release/release.env
open -e ~/.footrdc-release/release.env
```

Contents, with your own values:

```text
ASC_KEY_ID=
ASC_ISSUER_ID=
ASC_KEY_PATH=
FOOTRDC_EXPORT_COMPLIANCE_CONFIRMED=
PLAY_JSON_PATH=
```

**Apple**

1. In App Store Connect, Users and Access > Integrations > Team Keys, choose or create a key with the App Manager role. Note its Key ID and the Issuer ID shown above the list.
2. Put the `.p8` file somewhere private and set `ASC_KEY_PATH` to it. If one of the four keys already in `~/.appstoreconnect/private_keys` is a suitable team key, you may name that one. They were not assumed to be for FootRDC.
3. Set `FOOTRDC_EXPORT_COMPLIANCE_CONFIRMED=yes` only if you confirm the app uses no encryption beyond standard HTTPS. The lane declares this to Apple.
4. Confirm the FootRDC app record exists for `com.tootiyesolutions.footrdc`.
5. In Certificates, Identifiers & Profiles, confirm the app and `com.tootiyesolutions.footrdc.OneSignalNotificationServiceExtension` both have the App Group `group.com.tootiyesolutions.footrdc.onesignal`, and the app has Push Notifications.
6. In TestFlight, have an internal group with automatic distribution turned on. Builds reach internal groups only that way.

**Google**

1. In Google Cloud, create a service account for FootRDC and download its JSON key. The Teka service account on this Mac was not used and should stay with Teka.
2. In Play Console, Users and permissions, invite that account with access to FootRDC only and permission to release to testing tracks.
3. Set `PLAY_JSON_PATH` to the JSON file.
4. Under Test and release > Testing > Internal testing, add testers.
5. Under App integrity, confirm the upload key SHA-256 equals:
   `85:E1:96:1C:E0:A2:43:A7:6C:72:C6:8B:E4:B6:64:ED:FB:80:B1:33:F2:6A:50:84:27:1C:51:67:71:EF:CE:A7`

Then run:

```bash
bundle exec fastlane beta_all
```

Both lanes have uploaded for real, with `5.12.11 (31)`.

## Apple version trains

A build number alone is not enough. Apple can close a version for new builds, and the App Store versions list does not show this. `5.12.10` was closed although it never appeared in that list. The only reliable answer is the upload itself: error 90186 means set a higher version in `pubspec.yaml`, run `tool/set_build_number.sh <number>`, commit and push.

## Security

Never commit `.p8` keys, keystores, keystore passwords, service-account JSON, certificates or private keys. `.gitignore` covers them, and a test fails if one is tracked.
