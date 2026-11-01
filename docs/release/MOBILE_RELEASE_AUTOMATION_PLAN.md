# Mobile release automation plan

Status: plan only. Nothing here has been executed, and no credential has been requested or stored. TestFlight and Google Play uploads need explicit owner approval.

## Current state

| Item | Value |
|---|---|
| Version | `5.12.10+30` in `pubspec.yaml` |
| iOS bundle ID | `com.tootiyesolutions.footrdc` |
| Android application ID | `com.tootiyesolutions.footrdc` |
| iOS team | `YK6Z393A4D`; extension `...OneSignalNotificationServiceExtension` also needs signing |
| Android signing | `android/key.properties` when present; local and untracked |
| CI | `.github/workflows/ci.yml`: analyze, test, debug build; no release |
| Fastlane | Gem present on this Mac; not configured in the project |

## Target commands

| Command | Does | Never does |
|---|---|---|
| `release ios-beta` | Tests, signed IPA, upload to TestFlight | Submit to App Review |
| `release android-internal` | Tests, signed AAB, upload to Play Internal testing | Promote to Production |
| `release beta-all` | Validation, then both of the above | Anything public |

`release` alone must fail with a usage message. Public submission stays a separate manual action.

## Fastlane lanes

```ruby
platform :ios do
  lane :beta do
    # guard, tests, flutter build ipa, upload_to_testflight(skip_submission: true)
  end
end

platform :android do
  lane :internal do
    # guard, tests, flutter build appbundle, upload_to_play_store(track: "internal", release_status: "draft")
  end
end

lane :beta_all do
  # shared validation once, then ios beta and android internal
end
```

## Guards before any upload

All must pass, or the script stops before building:

- Git tree clean, branch is the approved release branch
- `flutter analyze` has no errors or warnings; `flutter test` passes; device QA passes
- Version valid; build number greater than the last uploaded one
- Release notes file exists for this version
- Bundle and package IDs match this document
- Signing identity present; credentials found outside the repository
- Target track named explicitly, and confirmation typed

Missing credentials fail closed with a message naming the variable, never its value.

## Versioning

The semantic version changes only by owner decision. The build number is the same integer on both stores (`+31`, `+32`, ...), taken from the highest value in `App Store Connect` and Play, then written with `--build-number`, so every upload is unique. iOS `CFBundleVersion` and Android `versionCode` both come from it.

## What the owner will need to provide

Keep these outside the repository, in macOS Keychain or a local `~/.footrdc-release/` folder with mode 700. Never paste them into chat.

**Apple**
- App Store Connect API key with App Manager access: the `.p8` file, Key ID and Issuer ID
- Distribution certificate and provisioning profiles for the app and the OneSignal extension, or automatic signing under team `YK6Z393A4D`
- Confirmation that the TestFlight app record exists, and the internal tester group

**Google**
- Google Play Developer API enabled and linked to the Play Console
- Service account JSON with release permissions for this app only
- Upload keystore, alias and passwords, matching `android/key.properties`
- Internal testing track created with testers

## Security

Never commit `.p8` keys, keystores, keystore passwords, service-account JSON, certificates or private keys. `.gitignore` must cover them before Fastlane is added. Logs must not print secrets. If CI is added later, use its secret store with environment protection and a required reviewer.

## Rollout order

1. Add a Fastlane config, no credentials, dry-run the guards.
2. Owner provides credentials locally.
3. First manual `ios beta` to TestFlight with owner present.
4. First manual `android internal`.
5. Only then consider `beta_all`, and CI much later.
