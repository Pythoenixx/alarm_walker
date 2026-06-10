# Alarm Walker Final Regression Test Checklist

Use this checklist before final submission, final demo recording, APK release handoff, or admin web handoff.

This version is designed to be ticked directly in Markdown. Use:

- `[x]` = Pass
- `[ ]` = Not tested yet
- `Notes:` = write issue, device, account, or screenshot reference

## Test Session Details

- Tester:
- Date:
- Device:
- Android version:
- App version/build:
- APK source:
- Admin web URL:
- Git commit tested:
- Overall result: Pass / Fail / Needs retest

---

# A. Quick Final Demo Check

Use this first when time is limited. If all items pass, the build is safe for demo.

## A1. Build and Launch

- [ ] `flutter analyze` passes  
  Notes:
- [ ] Final release APK installs successfully  
  Notes:
- [ ] App launches from phone launcher without black screen  
  Notes:
- [ ] App version is visible in Settings  
  Notes:

## A2. Core Alarm Flow

- [ ] Create a one-time alarm 1 to 2 minutes ahead  
  Notes:
- [ ] Alarm rings at the scheduled time  
  Notes:
- [ ] Alarm screen opens only once  
  Notes:
- [ ] Selected sound plays  
  Notes:
- [ ] Selected dismiss task can be completed  
  Notes:
- [ ] Alarm stops after successful completion  
  Notes:

## A3. Snooze and Analytics

- [ ] Snooze button schedules snooze correctly  
  Notes:
- [ ] Wake Now ends snooze early  
  Notes:
- [ ] Wake history is created after dismiss  
  Notes:
- [ ] Wake Analytics updates after dismiss  
  Notes:

## A4. Admin Web and Release Links

- [ ] Render admin web opens  
  Notes:
- [ ] Admin login works  
  Notes:
- [ ] Issue Logs page loads  
  Notes:
- [ ] APK GitHub Release link opens  
  Notes:
- [ ] QR code opens the APK release/download page  
  Notes:

---

# B. Full Regression Checklist

Use this when preparing the final submission build.

## 1. Setup and Build

- [ ] `flutter analyze` passes  
  Notes:
- [ ] App launches with `flutter run -t lib/main.dart`  
  Notes:
- [ ] Admin web launches with `flutter run -d chrome -t lib/main_admin.dart`  
  Notes:
- [ ] Correct VS Code launch config opens normal app on Android  
  Notes:
- [ ] Correct VS Code launch config opens admin web on Chrome  
  Notes:
- [ ] Release APK builds with `flutter build apk --release -t lib/main.dart`  
  Notes:
- [ ] App version is visible in Settings  
  Notes:

## 2. Authentication and Profile

- [ ] Login works  
  Notes:
- [ ] Sign-up works  
  Notes:
- [ ] Forgot password flow shows proper message  
  Notes:
- [ ] Profile page loads  
  Notes:
- [ ] Edit display name works  
  Notes:
- [ ] Change profile category works  
  Notes:
- [ ] Wake Analytics refreshes after profile/category change  
  Notes:

## 3. Alarm CRUD

- [ ] Create one-time alarm  
  Notes:
- [ ] Create repeat alarm  
  Notes:
- [ ] Edit alarm time  
  Notes:
- [ ] Edit alarm title  
  Notes:
- [ ] Edit sound  
  Notes:
- [ ] Edit dismiss mode  
  Notes:
- [ ] Enable/disable alarm  
  Notes:
- [ ] Delete alarm hides it from Home  
  Notes:
- [ ] Wake history remains after alarm delete  
  Notes:
- [ ] Alarm list remains sorted by time-of-day  
  Notes:

## 4. Alarm Ringing and Gate Behaviour

- [ ] Alarm rings at scheduled time  
  Notes:
- [ ] AlarmGate opens once  
  Notes:
- [ ] No duplicate AlarmGate after alarm starts  
  Notes:
- [ ] Selected alarm sound plays  
  Notes:
- [ ] Notification appears without `invalid_icon` crash  
  Notes:
- [ ] Notification small icon displays correctly  
  Notes:
- [ ] Normal dismiss works  
  Notes:
- [ ] One-time alarm disables after successful dismiss  
  Notes:
- [ ] Repeat alarm remains available after successful dismiss  
  Notes:

## 5. Snooze and Recovery

- [ ] Snooze button schedules snooze alarm  
  Notes:
- [ ] Snooze countdown displays correctly  
  Notes:
- [ ] Countdown finish returns to active mode  
  Notes:
- [ ] Countdown finish does not cause duplicate `Alarm.set()` behaviour  
  Notes:
- [ ] Wake Now ends snooze early  
  Notes:
- [ ] Wake Now does not create duplicate gate  
  Notes:
- [ ] Swipe alarm notification during active gate  
  Notes:
- [ ] Watchdog restores alarm sound after notification swipe  
  Notes:
- [ ] Restore cooldown prevents rapid restore loop  
  Notes:

## 6. Dismiss Modes

- [ ] Math mode displays question  
  Notes:
- [ ] Wrong Math answer increments failed attempt count  
  Notes:
- [ ] Math skip works when enabled  
  Notes:
- [ ] Retype mode displays phrase  
  Notes:
- [ ] Wrong Retype input increments failed attempt count  
  Notes:
- [ ] Retype skip works when enabled  
  Notes:
- [ ] Shake mode counts movement  
  Notes:
- [ ] Shake difficulty feels acceptable for Child/Adult/Senior  
  Notes:
- [ ] Walk mode opens safely  
  Notes:
- [ ] Walk permission message is understandable  
  Notes:
- [ ] Challenge completion dismisses alarm  
  Notes:

## 7. Wake Analytics

- [ ] Wake log created after successful dismiss  
  Notes:
- [ ] Wake log records disarm time  
  Notes:
- [ ] Wake log reflects failed attempts where applicable  
  Notes:
- [ ] Snooze-related analytics update correctly  
  Notes:
- [ ] Empty state displays correctly  
  Notes:
- [ ] Analytics still display after deleting related alarm  
  Notes:
- [ ] Analytics page has no visible overflow  
  Notes:

## 8. Adaptive Difficulty

- [ ] Adaptive difficulty setting can be enabled/disabled  
  Notes:
- [ ] Difficulty can become easier after struggling pattern  
  Notes:
- [ ] Difficulty can become firmer after strong/snooze-heavy pattern  
  Notes:
- [ ] Skip setting is not automatically turned on/off by adaptive difficulty  
  Notes:
- [ ] Profile category remains consistent after adaptive update  
  Notes:

## 9. Weather, Sound, and Backup

- [ ] Weather card loads or shows friendly fallback  
  Notes:
- [ ] Cached weather fallback appears after previous successful load  
  Notes:
- [ ] Weather refresh message is understandable  
  Notes:
- [ ] Sound preview works  
  Notes:
- [ ] System default preview uses fallback app sound  
  Notes:
- [ ] Custom audio selection works if available  
  Notes:
- [ ] Backup export works  
  Notes:
- [ ] Backup restore works  
  Notes:
- [ ] Soft-deleted alarm data does not reappear on Home after restore  
  Notes:
- [ ] Wake logs remain visible after restore  
  Notes:

## 10. Help, Feedback, and Admin

- [ ] Help & Feedback page opens  
  Notes:
- [ ] User can submit support ticket  
  Notes:
- [ ] Admin login page opens on web  
  Notes:
- [ ] Non-admin access is blocked  
  Notes:
- [ ] Admin account can access dashboard  
  Notes:
- [ ] Support Tickets tab loads  
  Notes:
- [ ] Support ticket search does not lose focus  
  Notes:
- [ ] Support ticket resolve/reopen/delete works  
  Notes:
- [ ] Issue Logs tab loads  
  Notes:
- [ ] Issue status filter defaults to Open  
  Notes:
- [ ] Issue stack trace is hidden by default  
  Notes:
- [ ] Copy Summary / Copy Full Debug works  
  Notes:
- [ ] Bulk issue/support actions work  
  Notes:

## 11. Localization and Overflow

- [ ] English remains normal/default  
  Notes:
- [ ] Malay language can be selected  
  Notes:
- [ ] Login/sign-up Malay text displays correctly  
  Notes:
- [ ] Settings Malay text displays correctly  
  Notes:
- [ ] Add/Edit Alarm Malay text displays correctly  
  Notes:
- [ ] Dismiss mode settings Malay text displays correctly  
  Notes:
- [ ] AlarmGate Malay text displays correctly  
  Notes:
- [ ] Wake Analytics Malay text displays correctly  
  Notes:
- [ ] Weather Malay text displays correctly  
  Notes:
- [ ] Onboarding Malay text displays correctly  
  Notes:
- [ ] No overflow on small Android screen  
  Notes:
- [ ] No overflow with larger system font size  
  Notes:
- [ ] No overflow with long alarm title  
  Notes:

## 12. Final Demo Readiness

- [ ] Demo account prepared  
  Notes:
- [ ] Demo alarms prepared  
  Notes:
- [ ] Admin account marker exists  
  Notes:
- [ ] Screenshots match current documented UI  
  Notes:
- [ ] No debug-only noisy logs visible in normal demo explanation  
  Notes:
- [ ] APK/build can be generated if needed  
  Notes:
- [ ] Final report screenshots still match app UI  
  Notes:
- [ ] Presentation/video script still matches feature flow  
  Notes:
- [ ] Render admin web URL is saved  
  Notes:
- [ ] GitHub APK release URL is saved  
  Notes:
- [ ] QR code is tested with a phone camera  
  Notes:

---

# C. Final Testing Order

Recommended final testing order:

1. Run `flutter analyze`.
2. Test the quick final demo check in Section A.
3. Test core mobile alarm CRUD.
4. Test alarm ringing, snooze, and notification swipe recovery.
5. Test dismiss modes.
6. Test Wake Analytics and soft delete.
7. Test localization and overflow.
8. Test admin web on Render.
9. Test APK release link and QR code.
10. Recheck screenshots, report, poster, and presentation script.

# D. Final Sign-Off

- [ ] All required tests passed
- [ ] Known issues documented
- [ ] Final APK backed up
- [ ] Final source code pushed
- [ ] Admin web deployment confirmed live
- [ ] Report/poster/presentation match the final app

Final decision: Ready for submission / Needs retest

At this stage, avoid UI changes unless a real regression appears. Documentation updates are safer than feature changes.
