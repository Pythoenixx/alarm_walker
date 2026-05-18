import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/wake_log_model.dart';
import 'package:sqflite/sqflite.dart';

class WakeLogRepository {
  final Database db;
  WakeLogRepository(this.db);

  // ── write ──────────────────────────────────────────────────────────────────

  /// Called the moment the alarm fires. Returns the new logId.
  Future<int> startLog({
    required int alarmId,
    required AlarmDisarmMode disarmMode,
  }) async {
    return db.insert('wake_log', {
      'alarm_id': alarmId,
      'wake_time': DateTime.now().toIso8601String(),
      'snooze_count': 0,
      'success': 0,
      'disarm_mode': disarmMode.dbValue,
      'disarm_duration': 0,
    });
  }

  /// Called each time the user snoozes.
  Future<void> incrementSnooze(int logId) async {
    await db.rawUpdate(
      '''
      UPDATE wake_log
      SET snooze_count = snooze_count + 1
      WHERE log_id = ?
    ''',
      [logId],
    );
  }

  /// Called when the user cancels a snooze. Clamps at 0 to avoid negatives.
  Future<void> decrementSnooze(int logId) async {
    await db.rawUpdate(
      '''
    UPDATE wake_log
    SET snooze_count = MAX(0, snooze_count - 1)
    WHERE log_id = ?
  ''',
      [logId],
    );
  }

  /// Called when the user fully dismisses (success or abandoned).
  Future<void> completeLog({
    required int logId,
    required bool success,
    required int disarmDurationMs,
  }) async {
    await db.update(
      'wake_log',
      {'success': success ? 1 : 0, 'disarm_duration': disarmDurationMs},
      where: 'log_id = ?',
      whereArgs: [logId],
    );
  }

  // ── read ───────────────────────────────────────────────────────────────────

  Future<List<WakeLog>> getAllLogs() async {
    final rows = await db.query('wake_log', orderBy: 'wake_time DESC');
    return rows.map(WakeLog.fromMap).toList();
  }

  Future<List<WakeLog>> getLogsForAlarm(int alarmId) async {
    final rows = await db.query(
      'wake_log',
      where: 'alarm_id = ?',
      whereArgs: [alarmId],
      orderBy: 'wake_time DESC',
    );
    return rows.map(WakeLog.fromMap).toList();
  }

  Future<Map<String, dynamic>> getSummary() async {
    final result = await db.rawQuery('''
      SELECT
        COUNT(*)              AS total,
        SUM(success)          AS successes,
        AVG(disarm_duration)  AS avg_duration,
        AVG(snooze_count)     AS avg_snooze
      FROM wake_log
    ''');
    return result.first;
  }

  /// Per-alarm summary — useful for a stats screen per alarm.
  Future<Map<String, dynamic>> getSummaryForAlarm(int alarmId) async {
    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*)              AS total,
        SUM(success)          AS successes,
        AVG(disarm_duration)  AS avg_duration,
        AVG(snooze_count)     AS avg_snooze
      FROM wake_log
      WHERE alarm_id = ?
    ''',
      [alarmId],
    );
    return result.first;
  }
}
