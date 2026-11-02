# Release checklist

No upload without explicit owner approval.

- [x] Git tree clean, on the approved branch, pushed
- [x] `flutter analyze` no errors or warnings; `flutter test` green
- [x] Integration QA green on iOS and Android
- [x] `SPORTSPRESS_USAGE_REMAINING: 0`
- [ ] Version and build number valid and unique (31 set; uniqueness is checked against the stores at upload)
- [x] Release notes ready
- [ ] Bundle and package IDs correct; signing identity correct
- [ ] Explicit target track confirmed: TestFlight or Play Internal, never public by default

## Internal beta state

| Item | State |
|---|---|
| Android upload keystore and `key.properties` | Present, opens, alias matches, AAB signed with it |
| Apple Distribution identity in Keychain | Present, TOOTIYE ENTERPRISES LTD |
| App Store Connect API keys | Four exist; none designated for FootRDC |
| App Store Connect Issuer ID | Not found on this Mac |
| FootRDC App Store provisioning profiles | Absent; the lane creates them once the key is set |
| Google Play service account for FootRDC | Absent. A Teka one exists and was not used |
| Export compliance confirmation | Owner to give |
| `~/.footrdc-release/release.env` | Absent |
| Physical iPhone | Known to Xcode but not connected |
| Physical Android phone | None connected |
| OneSignal test | Prepared in `docs/release/INTERNAL_BETA_TEST_PLAN.md`; not sent |
