import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/alarm_repository.dart';
import 'package:alarm_walker/models/wake_log_model.dart';
import 'package:alarm_walker/models/wake_log_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserUsageStatsSyncService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserUsageStatsSyncService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> syncCurrentUser({
    required AlarmRepository alarmRepo,
    required WakeLogRepository wakeLogRepo,
    required String ownerId,
  }) async {
    final user = _auth.currentUser;
    if (user == null || ownerId == 'local') return;

    try {
      final alarms = await alarmRepo.getAlarms(userId: ownerId);
      final wakeLogs = await wakeLogRepo.getAllLogs(userId: ownerId);
      final summary = _buildSummary(
        userId: ownerId,
        email: user.email,
        alarms: alarms,
        wakeLogs: wakeLogs,
      );

      await _firestore
          .collection('user_usage_summaries')
          .doc(ownerId)
          .set(summary, SetOptions(merge: true));

      await _firestore.collection('users').doc(ownerId).set({
        'usageSummaryUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      // Usage stats should never break alarm flow. Admin reports can still show
      // older data if sync fails.
      // ignore: avoid_print
      print('Usage stats sync failed: $error');
    }
  }

  Map<String, dynamic> _buildSummary({
    required String userId,
    required String? email,
    required List<AlarmModel> alarms,
    required List<WakeLog> wakeLogs,
  }) {
    final disarmModeCounts = <String, int>{};
    var enabledAlarms = 0;
    var repeatAlarms = 0;
    var oneTimeAlarms = 0;

    for (final alarm in alarms) {
      if (alarm.enabled) enabledAlarms++;
      if (alarm.isOnce) {
        oneTimeAlarms++;
      } else {
        repeatAlarms++;
      }
      final mode = alarm.dismissSettings.mode.name;
      disarmModeCounts[mode] = (disarmModeCounts[mode] ?? 0) + 1;
    }

    var successfulWakeLogs = 0;
    var totalSnoozeCount = 0;
    var totalDisarmDurationMs = 0;
    DateTime? latestWakeAt;

    for (final log in wakeLogs) {
      if (log.success) successfulWakeLogs++;
      totalSnoozeCount += log.snoozeCount;
      totalDisarmDurationMs += log.disarmDurationMs;
      if (latestWakeAt == null || log.wakeTime.isAfter(latestWakeAt!)) {
        latestWakeAt = log.wakeTime;
      }
    }

    return {
      'userId': userId,
      'email': email,
      'totalAlarms': alarms.length,
      'enabledAlarms': enabledAlarms,
      'disabledAlarms': alarms.length - enabledAlarms,
      'repeatAlarms': repeatAlarms,
      'oneTimeAlarms': oneTimeAlarms,
      'disarmModeCounts': disarmModeCounts,
      'totalWakeLogs': wakeLogs.length,
      'successfulWakeLogs': successfulWakeLogs,
      'failedWakeLogs': wakeLogs.length - successfulWakeLogs,
      'totalSnoozeCount': totalSnoozeCount,
      'totalDisarmDurationMs': totalDisarmDurationMs,
      'latestWakeAt': latestWakeAt?.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
