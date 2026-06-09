# Alarm Walker SRS Requirement Coverage Notes

This document maps the current implemented system to the main expected requirement areas. It can be used when preparing the final report, presentation slides, or viva explanation.

## 1. Requirement Coverage Summary

| Requirement area | Current implementation status | Notes |
| --- | --- | --- |
| Alarm creation | Covered | User can create alarms with time, repeat/one-time choice, sound, snooze, and dismiss mode. |
| Alarm editing | Covered | User can edit existing alarm settings; one-time alarms are re-enabled after edit. |
| Alarm deletion | Covered | Uses soft delete to hide/disable alarm while preserving analytics history. |
| Repeat alarm | Covered | Repeat-day alarms remain available after dismissal. |
| One-time alarm | Covered | One-time alarms are disabled after successful dismissal. |
| Snooze | Covered | Snooze schedules a future package alarm and supports Wake Now. |
| Active alarm dismissal | Covered | Math, Retype, Shake, and Walk modes require user action before dismissal. |
| Failed attempt tracking | Covered | Wrong Math/Retype attempts are counted as failed attempts while the final wake log can still be successful. |
| Wake analytics | Covered | Wake logs support success/failure-related history, disarm time, snooze-related behaviour, and profile-aware analysis. |
| Adaptive difficulty | Covered | Difficulty can adjust based on wake-up behaviour and profile category. |
| User profile category | Covered | Child, Adult, and Senior categories are supported. |
| Weather-aware support | Covered | Weather information and cached fallback are available as supportive context. |
| Backup and restore | Covered | App data can be exported/restored, including soft-deleted alarms needed by historical wake logs. |
| Help and feedback | Covered | User can submit Help & Feedback tickets. |
| Admin issue/support monitoring | Covered | Admin panel can view and manage issue logs and support tickets. |
| Malay localization | Covered for main flows | Main user app flows have Malay translations; English remains default for final screenshots. |
| Responsive/overflow handling | Partially covered and tested progressively | Known overflow areas were fixed; remaining overflow should be caught through final testing and issue logs. |

## 2. Objective Alignment

### Objective 1: Support active wake-up behaviour

Alarm Walker supports active wake-up by requiring the user to complete a selected dismiss task before the alarm can be dismissed. The supported tasks include Math, Retype, Shake, and Walk.

### Objective 2: Address passive dismissal and snoozing behaviour

The system supports snooze but still returns the user to an active wake-up flow. Wake Now allows the user to end snooze early, while wake logs and adaptive difficulty can consider snooze behaviour.

Use careful wording in final documentation:

```text
supports active wake-up behaviour
addresses passive dismissal
discourages repeated passive snoozing
encourages alertness
```

Avoid overclaiming that the system proves it reduces or prevents oversleeping unless supported by long-term user study data.

### Objective 3: Provide profile-based difficulty support

The system supports profile categories such as Child, Adult, and Senior. These categories influence default challenge difficulty and help make the app more suitable for different users.

### Objective 4: Provide wake-up analytics

The Wake Analytics feature records wake-up behaviour and displays user performance history. U7 soft delete protects wake history when alarm setups are removed from the Home screen.

## 3. Important Testing Evidence to Mention

The final report/demo can mention that testing covered:

- alarm creation, editing, enabling, disabling, and deletion
- repeat and one-time alarm behaviour
- snooze and Wake Now behaviour
- notification swipe recovery
- duplicate AlarmGate prevention
- Math, Retype, Shake, and Walk dismissal modes
- Wake Analytics updates
- Malay localization and small-screen overflow checks
- Help & Feedback submission
- Admin login/access guard
- Admin issue and support ticket triage
- backup and restore behaviour

## 4. Requirement Boundaries

Some features are intentionally limited to keep the project realistic and defensible:

- Weather is supportive context, not the main dismissal mechanism.
- Malay localization is implemented through a helper-based approach instead of full ARB migration.
- Soft delete preserves wake history, but individual Wake Analytics delete UI is not added to avoid changing final documented UI.
- Admin access guard is suitable for project/demo use, while final production hardening would require stricter Firestore rules and possibly custom admin claims.

## 5. Recommended Final Report Wording

Use:

```text
The system supports active wake-up behaviour through task-based alarm dismissal.
The system encourages users to engage with the alarm instead of only dismissing it passively.
Wake Analytics allows users to review their wake-up performance history.
The system was tested through functional testing and user acceptance testing.
```

Avoid:

```text
The system proves that it reduces oversleeping.
The system guarantees users will wake up.
The system prevents oversleeping completely.
```
