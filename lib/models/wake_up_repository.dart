import 'package:sqflite/sqflite.dart';

class WakeLogRepository {
  final Database db;

  WakeLogRepository(this.db);

  Future<List<Map<String, Object?>>> getAllLogs({
    required String userId,
  }) async {
    return db.rawQuery(
      '''
      SELECT wl.*
      FROM wake_log wl
      JOIN alarm a ON a.alarm_id = wl.alarm_id
      WHERE a.user_id = ?
      ORDER BY wl.wake_time DESC
    ''',
      [userId],
    );
  }

  Future<Map<String, Object?>> getSummary({required String userId}) async {
    final result = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total,
        SUM(success) AS success_count,
        AVG(disarm_duration) AS avg_disarm_duration
      FROM wake_log wl
      JOIN alarm a ON a.alarm_id = wl.alarm_id
      WHERE a.user_id = ?
    ''',
      [userId],
    );

    return result.first;
  }
}
