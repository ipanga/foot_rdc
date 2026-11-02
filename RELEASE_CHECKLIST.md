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

## Internal beta state, 3 Nov 2026 local validation

| Item | State |
|---|---|
| Apple authentication, FootRDC record | Pass |
| Highest Apple build | 30 (5.12.10). App Store live version is 1.1.3, so the 5.12.10 train is open |
| TestFlight internal group | Main testers, automatic distribution on |
| Apple portal access | **Blocked: Account Holder must accept the latest Program License Agreement** |
| Google authentication, FootRDC record | Pass, service account `footrdc-play-internal` |
| Highest Google versionCode | 30, on production. Internal, alpha and beta are empty |
| Testing tracks | Accepted in a discarded draft edit |
| Production | Refused: `The caller does not have permission` |
| Android upload key | Local keystore and AAB equal the expected SHA-256. Google confirms its side at first upload |
| Export compliance gate | Pass, owner confirmed |
| Build number | 31, unused on both stores |
| Physical iPhone and Android, real push, live match | Not run |
