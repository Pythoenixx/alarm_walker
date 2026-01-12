import 'package:alarm_walker/models/alarm_model.dart';

class WakeLog {
  final int? logId;
  final int alarmId;
  final DateTime wakeTime;
  final int snoozeCount;
  final bool success;
  final AlarmDisarmMode disarmMode; // enum, not String
  final int disarmDurationMs;

  WakeLog({
    this.logId,
    required this.alarmId,
    required this.wakeTime,
    required this.snoozeCount,
    required this.success,
    required this.disarmMode,
    required this.disarmDurationMs,
  });

  Map<String, Object?> toMap() {
    return {
      'log_id': logId,
      'alarm_id': alarmId,
      'wake_time': wakeTime.toIso8601String(),
      'snooze_count': snoozeCount,
      'success': success ? 1 : 0,
      'disarm_mode': disarmMode.dbValue,
      'disarm_duration': disarmDurationMs,
    };
  }

  factory WakeLog.fromMap(Map<String, dynamic> map) {
    return WakeLog(
      logId: map['log_id'] as int?,
      alarmId: map['alarm_id'] as int,
      wakeTime: DateTime.parse(map['wake_time'] as String),
      snoozeCount: map['snooze_count'] as int,
      success: (map['success'] as int) == 1,
      disarmMode: AlarmDisarmModeX.fromDb(map['disarm_mode'] as String),
      disarmDurationMs: map['disarm_duration'] as int,
    );
  }
}
