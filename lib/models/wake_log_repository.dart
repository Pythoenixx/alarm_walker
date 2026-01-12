import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/wake_log_model.dart';
import 'package:sqflite/sqflite.dart';

class WakeLogRepository {
  final Database db;

  WakeLogRepository(this.db);

  Future<void> insertWakeLog(WakeLog log) async {
    await db.insert('wake_log', {
      'alarm_id': log.alarmId,
      'wake_time': log.wakeTime.toIso8601String(),
      'snooze_count': log.snoozeCount,
      'success': log.success ? 1 : 0,
      'disarm_mode': log.disarmMode.dbValue,
      'disarm_duration': log.disarmDurationMs,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<WakeLog>> getAllLogs() async {
    final rows = await db.query('wake_log', orderBy: 'wake_time DESC');

    return rows.map(WakeLog.fromMap).toList();
  }

  Future<Map<String, dynamic>> getSummary() async {
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) AS total,
        SUM(success) AS successes,
        AVG(disarm_duration) AS avg_duration,
        AVG(snooze_count) AS avg_snooze
      FROM wake_log
    ''');

    return result.first;
  }
}
