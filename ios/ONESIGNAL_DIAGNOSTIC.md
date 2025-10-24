# OneSignal iOS Diagnostic Checklist

## The app builds successfully but notifications don't work?

Follow this checklist **in order**. Each step is critical for iOS push notifications.

---

## ✅ Step 1: Verify Xcode Capabilities (MOST COMMON ISSUE)

**This is the #1 reason OneSignal fails on iOS after successful builds.**

1. **Open Xcode workspace**:
   ```bash
   cd /Users/Apple/Documents/AppDev/Flutter/foot_rdc/ios
   open Runner.xcworkspace  # ← Must be .xcworkspace, not .xcodeproj
   ```

2. **In Xcode Navigator** (left sidebar):
   - Click on "Runner" (the blue project icon at the top)

3. **Select the Runner TARGET** (not the project):
   - In the middle pane, under TARGETS, select "Runner"

4. **Go to "Signing & Capabilities" tab**

5. **Verify ALL these capabilities exist**:

   **a) Push Notifications**
   - ✓ Should see "Push Notifications" capability
   - If missing: Click "+ Capability" → Add "Push Notifications"

   **b) Background Modes**
   - ✓ Should see "Background Modes" capability
   - ✓ Check "Remote notifications" checkbox is enabled
   - If missing: Click "+ Capability" → Add "Background Modes" → Check "Remote notifications"

   **c) App Groups**
   - ✓ Should see "App Groups" capability
   - ✓ Should have: `group.com.tootiyesolutions.footrdc.onesignal`
   - If missing: Click "+ Capability" → Add "App Groups" → Add the group ID

6. **Repeat for OneSignalNotificationServiceExtension target**:
   - Select "OneSignalNotificationServiceExtension" target
   - Verify it has **App Groups** with same `group.com.tootiyesolutions.footrdc.onesignal`

7. **Save in Xcode** (Cmd+S)

**After adding capabilities, you MUST:**
```bash
cd /Users/Apple/Documents/AppDev/Flutter/foot_rdc
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

---

## ✅ Step 2: Check Provisioning Profile

**Your provisioning profile MUST include Push Notifications entitlement.**

### If you accidentally deleted it:

1. Go to **Apple Developer Portal**: https://developer.apple.com/account
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → Select your app ID: `com.tootiyesolutions.footrdc`
4. Verify **Push Notifications** is checked
5. If not checked:
   - Enable it
   - Configure it (Development/Production certificates)
6. Go to **Profiles**
7. Find your development profile for this app
8. Click "Edit" → Regenerate
9. Download the new profile
10. In Xcode: **Preferences** → **Accounts** → Select your Apple ID → **Download Manual Profiles**

### Alternative: Let Xcode manage automatically
1. In Xcode → Runner target → Signing & Capabilities
2. Set "Automatically manage signing" to ON
3. Select your Team
4. Xcode will create a new profile with required capabilities

---

## ✅ Step 3: Verify OneSignal Dashboard Configuration

1. Go to **OneSignal Dashboard**: https://dashboard.onesignal.com
2. Select your app
3. Go to **Settings** → **Platforms** → **Apple iOS (APNs)**
4. Verify you have configured **ONE** of these:

   **Option A: APNs Auth Key** (Recommended)
   - ✓ Key ID entered
   - ✓ Team ID entered
   - ✓ Bundle ID: `com.tootiyesolutions.footrdc`
   - ✓ .p8 file uploaded

   **Option B: APNs Certificate**
   - ✓ .p12 certificate uploaded
   - ✓ Password entered (if applicable)
   - ✓ Environment matches your build (Sandbox for development)

5. **Save** any changes

---

## ✅ Step 4: Check Build Configuration

In Xcode:
1. Select Runner target
2. Go to **Build Settings** tab
3. Search for: `CODE_SIGN_ENTITLEMENTS`
4. Verify it points to: `Runner/Runner.entitlements`

Check the entitlements file:
```bash
cat /Users/Apple/Documents/AppDev/Flutter/foot_rdc/ios/Runner/Runner.entitlements
```

Should contain:
```xml
<key>aps-environment</key>
<string>development</string>  <!-- or "production" for release -->
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.tootiyesolutions.footrdc.onesignal</string>
</array>
```

---

## ✅ Step 5: Run with Enhanced Debugging

**I've added enhanced logging to your app.** Now run it and check console output:

```bash
flutter run --release
```

**Watch for these log messages:**
```
🔔 OneSignal permission result: true/false
🔔 OneSignal Initial State:
  - Subscription ID: xxx (should not be null)
  - Token: xxx (should not be null)
  - Opted In: true (should be true)
```

**If you see:**
```
⚠️ WARNING: OneSignal subscription failed!
```

**Then the issue is one of:**
- Missing Xcode capabilities (go back to Step 1)
- Invalid provisioning profile (go to Step 2)
- Incorrect OneSignal dashboard config (go to Step 3)

---

## ✅ Step 6: Test on Real Device (Not Simulator)

**iOS Simulator CANNOT receive push notifications.**

1. Build on a real iOS device
2. Allow notifications when prompted
3. Check console logs for subscription status
4. Check OneSignal dashboard → Audience → All Users
5. Your device should appear

---

## ✅ Step 7: Send Test Notification

1. In OneSignal dashboard → Messages → New Push
2. Target: Select your test user or "Send to Test Device"
3. Add notification content
4. Click "Send Message"
5. Notification should appear on device

---

## 🔍 Common Error Messages

### "No valid aps-environment entitlement"
- Missing Push Notifications capability in Xcode
- Provisioning profile doesn't include push entitlement
- → Go to Step 1 & 2

### "Token is null" in logs
- APNs configuration wrong in OneSignal dashboard
- Device doesn't have valid provisioning
- → Go to Step 2 & 3

### "Permission denied"
- User didn't allow notifications
- Re-install app to re-prompt
- Or go to iOS Settings → Your App → Notifications → Enable

### "Opted In: false"
- OneSignal initialized but subscription failed
- Usually means APNs key/certificate issue
- → Go to Step 3

---

## 🎯 Quick Verification Commands

Run these to verify your setup:

```bash
# Check if capabilities file exists (should exist after adding in Xcode)
ls -la /Users/Apple/Documents/AppDev/Flutter/foot_rdc/ios/Runner.xcodeproj/project.pbxproj

# Check entitlements
cat /Users/Apple/Documents/AppDev/Flutter/foot_rdc/ios/Runner/Runner.entitlements

# Check OneSignal pod installed
grep -r "OneSignal" /Users/Apple/Documents/AppDev/Flutter/foot_rdc/ios/Podfile.lock

# Rebuild clean
cd /Users/Apple/Documents/AppDev/Flutter/foot_rdc
flutter clean && flutter pub get && cd ios && pod install && cd .. && flutter run --release
```

---

## 📞 Still Not Working?

If you've completed ALL steps above and it still doesn't work:

1. **Capture full console logs** when running the app
2. **Check Xcode console** for any APNs-related errors
3. **Screenshot** your Xcode Signing & Capabilities tab
4. **Verify** your OneSignal dashboard shows the APNs configuration correctly

The issue is almost always one of:
- ❌ Missing Push Notifications capability in Xcode (Step 1)
- ❌ Invalid provisioning profile (Step 2)  
- ❌ Wrong APNs key/certificate in OneSignal (Step 3)
- ❌ Testing on iOS Simulator instead of real device (Step 6)
