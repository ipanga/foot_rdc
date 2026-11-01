# Release checklist

No upload without explicit owner approval.

- [ ] Git tree clean, on the approved branch
- [ ] `flutter analyze` no errors or warnings; `flutter test` green
- [ ] Integration QA green on iOS and Android
- [ ] `SPORTSPRESS_USAGE_REMAINING: 0`
- [ ] Version and build number valid and unique
- [ ] Release notes ready
- [ ] Bundle and package IDs correct; signing identity correct
- [ ] Explicit target track confirmed: TestFlight or Play Internal, never public by default
