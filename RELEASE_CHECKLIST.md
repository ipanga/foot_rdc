# Release checklist

No upload without explicit owner approval.

- [x] Git tree clean, on the approved branch, pushed
- [x] `flutter analyze` no errors or warnings; `flutter test` green
- [x] Integration QA green on iOS and Android
- [x] `SPORTSPRESS_USAGE_REMAINING: 0`
- [x] Version and build number valid and unique
- [x] Release notes ready
- [x] Bundle and package IDs correct; signing identity correct
- [ ] Explicit target track confirmed: TestFlight or Play Internal, never public by default

## Internal beta state, 5.12.11 (31), commit `2925323`

| Item | State |
|---|---|
| TestFlight | Build 31 valid, `IN_BETA_TESTING` for internal testers |
| Main testers | Internal, automatic distribution on, 2 testers |
| Apple review submissions | None: no beta review, no new App Store version |
| Google Play internal | 5.12.11, versionCode 31, status completed |
| Google Play production | Unchanged: 5.12.10, versionCode 30 |
| Google Play alpha and beta | Empty |
| Android upload key | Accepted by Google at upload |
| Export compliance | Declared no non-exempt encryption, confirmed by the owner |
| Physical iPhone and Android, real push, live match | Not run |
