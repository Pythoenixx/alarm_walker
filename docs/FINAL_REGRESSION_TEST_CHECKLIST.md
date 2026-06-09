# Alarm Walker Final Regression Test Checklist

Use this checklist before final submission, final demo recording, or APK/build handoff. Mark each item as Pass/Fail/Notes during testing.

## 1. Setup

| Test item | Result | Notes |
| --- | --- | --- |
| `flutter analyze` passes |  |  |
| App launches with `flutter run -t lib/main.dart` |  |  |
| Admin web launches with `flutter run -d chrome -t lib/main_admin.dart` |  |  |
| Correct VS Code launch config opens normal app on Android |  |  |
| App version is visible in Settings |  |  |

## 2. Authentication and Profile

| Test item | Result | Notes |
| --- | --- | --- |
| Login works |  |  |
| Sign-up works |  |  |
| Forgot password flow shows proper message |  |  |
| Profile page loads |  |  |
| Edit display name works |  |  |
| Change profile category works |  |  |
| Wake Analytics refreshes after profile/category change |  |  |

## 3. Alarm CRUD

| Test item | Result | Notes |
| --- | --- | --- |
| Create one-time alarm |  |  |
| Create repeat alarm |  |  |
| Edit alarm time |  |  |
| Edit alarm title |  |  |
| Edit sound |  |  |
| Edit dismiss mode |  |  |
| Enable/disable alarm |  |  |
| Delete alarm hides it from Home |  |  |
| Wake history remains after alarm delete |  |  |
| Alarm list remains sorted by time-of-day |  |  |

## 4. Alarm Ringing and Gate Behaviour

| Test item | Result | Notes |
| --- | --- | --- |
| Alarm rings at scheduled time |  |  |
| AlarmGate opens once |  |  |
| No duplicate AlarmGate after alarm starts |  |  |
| Selected alarm sound plays |  |  |
| Normal dismiss works |  |  |
| One-time alarm disables after successful dismiss |  |  |
| Repeat alarm remains available after successful dismiss |  |  |

## 5. Snooze and Recovery

| Test item | Result | Notes |
| --- | --- | --- |
| Snooze button schedules snooze alarm |  |  |
| Snooze countdown displays correctly |  |  |
| Countdown finish returns to active mode |  |  |
| Countdown finish does not cause duplicate `Alarm.set()` behaviour |  |  |
| Wake Now ends snooze early |  |  |
| Wake Now does not create duplicate gate |  |  |
| Swipe alarm notification during active gate |  |  |
| Watchdog restores alarm sound after notification swipe |  |  |
| Restore cooldown prevents rapid restore loop |  |  |

## 6. Dismiss Modes

| Test item | Result | Notes |
| --- | --- | --- |
| Math mode displays question |  |  |
| Wrong Math answer increments failed attempt count |  |  |
| Math skip works when enabled |  |  |
| Retype mode displays phrase |  |  |
| Wrong Retype input increments failed attempt count |  |  |
| Retype skip works when enabled |  |  |
| Shake mode counts movement |  |  |
| Shake difficulty feels acceptable for Child/Adult/Senior |  |  |
| Walk mode opens safely |  |  |
| Walk permission message is understandable |  |  |
| Challenge completion dismisses alarm |  |  |

## 7. Wake Analytics

| Test item | Result | Notes |
| --- | --- | --- |
| Wake log created after successful dismiss |  |  |
| Wake log records disarm time |  |  |
| Wake log reflects failed attempts where applicable |  |  |
| Snooze-related analytics update correctly |  |  |
| Empty state displays correctly |  |  |
| Analytics still display after deleting related alarm |  |  |
| Analytics page has no visible overflow |  |  |

## 8. Adaptive Difficulty

| Test item | Result | Notes |
| --- | --- | --- |
| Adaptive difficulty setting can be enabled/disabled |  |  |
| Difficulty can become easier after struggling pattern |  |  |
| Difficulty can become firmer after strong/snooze-heavy pattern |  |  |
| Skip setting is not automatically turned on/off by adaptive difficulty |  |  |
| Profile category remains consistent after adaptive update |  |  |

## 9. Weather, Sound, and Backup

| Test item | Result | Notes |
| --- | --- | --- |
| Weather card loads or shows friendly fallback |  |  |
| Cached weather fallback appears after previous successful load |  |  |
| Weather refresh message is understandable |  |  |
| Sound preview works |  |  |
| System default preview uses fallback app sound |  |  |
| Custom audio selection works if available |  |  |
| Backup export works |  |  |
| Backup restore works |  |  |
| Soft-deleted alarm data does not reappear on Home after restore |  |  |
| Wake logs remain visible after restore |  |  |

## 10. Help, Feedback, and Admin

| Test item | Result | Notes |
| --- | --- | --- |
| Help & Feedback page opens |  |  |
| User can submit support ticket |  |  |
| Admin login page opens on web |  |  |
| Non-admin access is blocked |  |  |
| Admin account can access dashboard |  |  |
| Support Tickets tab loads |  |  |
| Support ticket search does not lose focus |  |  |
| Support ticket resolve/reopen/delete works |  |  |
| Issue Logs tab loads |  |  |
| Issue status filter defaults to Open |  |  |
| Issue stack trace is hidden by default |  |  |
| Copy Summary / Copy Full Debug works |  |  |
| Bulk issue/support actions work |  |  |

## 11. Localization and Overflow

| Test item | Result | Notes |
| --- | --- | --- |
| English remains normal/default |  |  |
| Malay language can be selected |  |  |
| Login/sign-up Malay text displays correctly |  |  |
| Settings Malay text displays correctly |  |  |
| Add/Edit Alarm Malay text displays correctly |  |  |
| Dismiss mode settings Malay text displays correctly |  |  |
| AlarmGate Malay text displays correctly |  |  |
| Wake Analytics Malay text displays correctly |  |  |
| Weather Malay text displays correctly |  |  |
| Onboarding Malay text displays correctly |  |  |
| No overflow on small Android screen |  |  |
| No overflow with larger system font size |  |  |
| No overflow with long alarm title |  |  |

## 12. Final Demo Readiness

| Test item | Result | Notes |
| --- | --- | --- |
| Demo account prepared |  |  |
| Demo alarms prepared |  |  |
| Admin account marker exists |  |  |
| Screenshots match current documented UI |  |  |
| No debug-only noisy logs visible in normal demo explanation |  |  |
| APK/build can be generated if needed |  |  |
| Final report screenshots still match app UI |  |  |
| Presentation/video script still matches feature flow |  |  |

## 13. Final Notes

Recommended final testing order:

1. Run static check with `flutter analyze`.
2. Test core mobile alarm flow.
3. Test snooze and notification swipe recovery.
4. Test Wake Analytics and soft delete.
5. Test localization and overflow.
6. Test admin web.
7. Recheck final screenshots and documentation.

At this stage, avoid UI changes unless a real regression appears. Small documentation or final checklist patches are safer than feature changes.
