# OneSignal iOS Fix Applied

## Issues Fixed

### 1. ✅ Missing Profile.xcconfig
**Problem**: The Profile build configuration was referencing Release.xcconfig instead of Profile.xcconfig, causing CocoaPods warnings and potential linking issues.

**Fix**: Created `/ios/Flutter/Profile.xcconfig` and updated Xcode project to reference it correctly.

### 2. ✅ CocoaPods Configuration
**Problem**: Linker errors about `_OBJC_CLASS_$_FlutterMethodChannel` due to misconfigured build settings.

**Fix**: Cleaned and reinstalled CocoaPods with proper configuration references.

## Next Steps - Verify iOS Capabilities in Xcode

1. **Open Xcode Project**:
   ```bash
   cd /Users/Apple/Documents/AppDev/Flutter/foot_rdc/ios
   open Runner.xcworkspace
   ```

2. **Verify Push Notification Capability**:
   - Select Runner project in Navigator
   - Select Runner target
   - Go to "Signing & Capabilities" tab
   - Verify "Push Notifications" capability is present
   - If missing, click "+ Capability" and add "Push Notifications"

3. **Verify Background Modes**:
   - In same "Signing & Capabilities" tab
   - Verify "Background Modes" capability is present
   - Check that "Remote notifications" is enabled
   - If missing, add "Background Modes" capability

4. **Verify App Groups**:
   - Verify "App Groups" capability exists
   - Should have: `group.com.tootiyesolutions.footrdc.onesignal`
   - Both Runner and OneSignalNotificationServiceExtension targets need this

5. **Verify Provisioning Profile**:
   - Ensure your provisioning profile includes:
     - Push Notifications entitlement
     - App Groups entitlement
   - You may need to regenerate in Apple Developer Portal if changes were made

## Environment Settings

### Development Build
Your `Runner.entitlements` currently has:
```xml
<key>aps-environment</key>
<string>development</string>
```

This is correct for **development/TestFlight** builds.

### Production Build
For **App Store production** builds, change to:
```xml
<key>aps-environment</key>
<string>production</string>
```

Or better, use build configurations to automatically switch.

## Testing OneSignal Subscription

After rebuilding:

1. **Clean Build**:
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   ```

2. **Build and Run**:
   ```bash
   flutter run --release
   ```
   or build in Xcode

3. **Check OneSignal Dashboard**:
   - Go to OneSignal dashboard
   - Navigate to Audience → All Users
   - Your device should appear after launching the app
   - Check "Subscribed Users" - should show iOS device

4. **Test Push Notification**:
   - Send a test notification from OneSignal dashboard
   - Ensure it arrives on your iOS device

## Common Issues

### "Failed to be subscribed" Error
This usually means:
- Missing or incorrect provisioning profile
- Push notification capability not enabled in Xcode
- APNs certificate/key not properly configured in OneSignal dashboard
- App Group not matching between targets

### Linker Errors
If you still see linker errors:
1. In Xcode, clean build folder (Cmd+Shift+K)
2. Delete derived data
3. Run `pod deintegrate && pod install`

## OneSignal Configuration Summary

- **OneSignal App ID**: `e9096906-f601-4639-93a7-de95eb3c1db5`
- **Bundle ID**: `com.tootiyesolutions.footrdc`
- **App Group**: `group.com.tootiyesolutions.footrdc.onesignal`
- **Min iOS Version**: 15.6

## Files Modified
- ✅ Created: `/ios/Flutter/Profile.xcconfig`
- ✅ Updated: `/ios/Runner.xcodeproj/project.pbxproj`
- ✅ Cleaned and reinstalled: CocoaPods
