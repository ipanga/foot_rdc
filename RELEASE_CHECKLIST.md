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

## Internal beta state, 2 Nov 2026

| Item | State |
|---|---|
| Android upload key | Keystore and AAB signer equal the expected SHA-256 |
| Apple Distribution certificate | Team `YK6Z393A4D`, TOOTIYE ENTERPRISES LTD, valid to 3 Jul 2027 |
| Bundle IDs and local entitlements | Correct: push, and the OneSignal App Group on app and extension |
| Apple key candidates on this Mac | `8C5KR2Q4J4`, `N576C758F4`, `UATJB3DX55`, `W2NZKDGF6S`, `78KG84553N`. Type and role unknown |
| App Store Connect Issuer ID | Not in the Teka release files. Owner to supply |
| Apple API validation | Not run: it needs the Issuer ID |
| Google Play service account for FootRDC | None found in FootRDC folders. Owner to create |
| Build 31 free on each store | Unknown until the store credentials work |
| Export compliance technical review | Standard HTTPS only. Owner confirmation pending |
| `~/.footrdc-release/release.env` | Created, private, values empty |
| Physical iPhone and Android, real push, live match | Not run |
