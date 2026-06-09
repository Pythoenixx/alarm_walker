# Alarm Walker Feature Architecture Notes

This document summarizes the current Alarm Walker feature architecture for final report, demo, and viva preparation. It is written as a practical reference for explaining how the main modules work together.

## 1. System Overview

Alarm Walker is a Flutter-based Android alarm application with a Flutter Web admin panel. The mobile application focuses on alarm scheduling, active wake-up challenges, snooze handling, wake-up analytics, user profile settings, weather-aware support, backup/restore, and Help & Feedback. The admin panel focuses on issue/support monitoring, reports, and app maintenance visibility.

The system is designed to support active wake-up behaviour by requiring users to complete a selected task before dismissing an alarm. This helps address passive alarm dismissal and supports better awareness of wake-up habits through analytics.

## 2. Main Runtime Components

| Component | Main responsibility |
| --- | --- |
| Mobile app (`lib/main.dart`) | Normal user-facing Alarm Walker application. |
| Admin web app (`lib/main_admin.dart`) | Admin dashboard for support, issue logs, and reports. |
| Alarm scheduling layer | Creates, updates, snoozes, restores, and cancels package alarms. |
| AlarmGate screen | Controls the active ringing/snoozing alarm session shown to the user. |
| Dismiss mode screens | Provides Math, Retype, Shake, and Walk challenge flows. |
| Local database | Stores alarms, wake logs, profile-related settings, and backup data. |
| Firebase/Firestore | Stores remote user/admin data, support tickets, issue logs, and summaries. |
| Localization helper | Provides English/Malay UI text using `context.tr(...)`. |

## 3. Alarm Flow

1. User creates an alarm and selects time, repeat/one-time option, snooze setting, sound, and disarm mode.
2. The app schedules the alarm through the alarm package.
3. When the alarm rings, AlarmGate opens.
4. User may snooze or complete the selected dismiss challenge.
5. On successful dismissal, the app records wake analytics data.
6. For one-time alarms, the alarm is disabled after successful dismissal.
7. Repeat alarms remain available for the next scheduled day.

## 4. Snooze Flow

The snooze flow uses the package alarm as the source of truth:

1. User taps Snooze.
2. The app schedules a future package alarm for the snooze time.
3. AlarmGate shows a countdown while the user remains in the snooze session.
4. When the countdown finishes, AlarmGate returns to active ringing state without calling a second immediate `Alarm.set()`.
5. If the user taps Wake Now, the app intentionally ends snooze early and wakes the alarm session.

This prevents duplicate ringing sessions and keeps the snooze behaviour easier to explain during testing.

## 5. Notification Swipe Recovery

Android notification behaviour can stop package alarm audio when the notification is dismissed. Alarm Walker handles this with an AlarmGate watchdog:

1. AlarmGate checks whether the expected alarm is still active while the alarm screen is open.
2. If the package alarm appears stopped unexpectedly, the app restores the original alarm sound.
3. A cooldown prevents repeated restore loops.
4. Duplicate AlarmGate screens are avoided by checking whether the same database alarm already has an active gate.

This feature improves reliability during real Android use, especially when users swipe notifications during an active alarm.

## 6. Wake Analytics and Soft Delete

Wake Analytics stores historical wake-up records. Alarm deletion uses soft delete so that removing an alarm setup does not remove previous wake history.

Current rule:

```text
Delete alarm = hide and disable the alarm setup
Wake history = preserve historical analytics records
```

A deleted alarm receives a `deleted_at` value and is hidden from normal Home alarm lists. It remains internally available so previous wake logs can still reference it for analytics and backup/restore consistency.

No individual Wake Analytics delete UI is added at this stage to avoid changing the documented final UI.

## 7. Disarming Modes

| Mode | Purpose |
| --- | --- |
| Math | Requires solving a math question before dismissal. |
| Retype | Requires typing a displayed phrase before dismissal. |
| Shake | Requires physical phone movement before dismissal. |
| Walk | Requires walking/step movement before dismissal. |

The system supports skipping generated problems where configured, but adaptive difficulty does not automatically turn skip on/off. This keeps user control separate from difficulty adjustment.

## 8. Adaptive Difficulty

Adaptive difficulty uses recent wake-up performance to adjust task difficulty. The logic considers success rate, failed attempts, disarm duration, and snooze behaviour.

General rule:

- Make easier when the user appears to struggle.
- Make firmer when the user can complete tasks but delays wake-up through snoozing.
- Keep unchanged when the recent pattern is mixed or unclear.

This supports the project objective of matching wake-up task difficulty to the user profile and behaviour.

## 9. Profile Categories

Alarm Walker supports profile categories such as Child, Adult, and Senior. These categories influence default task difficulty and help make the system more suitable for different user groups.

The current design keeps profile-based defaults simple and explainable for FYP/demo use.

## 10. Weather-Aware Support

Weather support provides contextual weather information when available. If fresh weather cannot be retrieved, the app can use cached weather information from a previous successful load.

The app avoids overclaiming weather accuracy. Weather is treated as supportive context, not as the core alarm dismissal mechanism.

## 11. Backup and Restore

Backup/restore protects app data such as alarms and history. Soft-deleted alarms are included in backup so that restored wake logs can still reference their related alarm setup.

This is important because Wake Analytics depends on preserving historical relationships between wake logs and alarms.

## 12. Help, Feedback, and Issue Monitoring

The user app provides Help & Feedback, while the admin panel provides Support Tickets and Issue Logs. Issue logging captures useful debugging context such as message, source, stack trace, platform, app area, and build information.

Sensitive information such as passwords, tokens, and private identity data should not be stored in issue logs.

## 13. Localization

Alarm Walker supports Malay localization using a helper-based approach. This was chosen because it is simple, practical, and suitable for FYP/demo readiness without a large ARB migration.

Current locale patches cover the main user app flows, high-traffic screens, dismiss modes, settings, onboarding, weather, and Wake Analytics. English remains the stable default for final screenshots and documentation.

## 14. Final Scope Decisions

- Keep the current Wake Analytics UI unchanged for final documentation consistency.
- Keep U7 soft delete as the final alarm delete behaviour.
- Avoid further UI changes unless final regression finds a real bug.
- Prefer documentation and regression patches at this stage.
