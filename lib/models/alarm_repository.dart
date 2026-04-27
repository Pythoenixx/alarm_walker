import 'package:alarm_walker/models/alarm_db_entry.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class AlarmRepository {
  final Database db;

  AlarmRepository(this.db);

  /// Fetch alarms + days and map to AlarmModel
  Future<List<AlarmModel>> getAlarms() async {
    final alarmRows = await db.query('alarm');

    final List<AlarmModel> alarms = [];

    for (final row in alarmRows) {
      final alarmEntry = AlarmDbEntry.fromMap(row);

      // 🔁 DB → Domain mapping happens HERE
      alarms.add(_toModel(alarmEntry));
    }

    return alarms;
  }

  Future<AlarmModel?> getAlarmById(int alarmId) async {
    final rows = await db.query(
      'alarm',
      where: 'alarm_id = ?',
      whereArgs: [alarmId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final alarmEntry = AlarmDbEntry.fromMap(rows.first);

    return _toModel(alarmEntry);
  }

  /// Domain → DB mapping
  Future<int> saveOrUpdate(AlarmModel model, String userId) async {
    final entry = _toDbEntry(model, userId);
    int alarmId;

    if (model.alarmId == null) {
      alarmId = await db.insert('alarm', entry.toMap());
    } else {
      alarmId = model.alarmId!;
      await db.update(
        'alarm',
        entry.toMap(),
        where: 'alarm_id = ?',
        whereArgs: [model.alarmId],
      );
    }
    return alarmId;
  }

  Future<void> deleteAlarm(int alarmId) async {
    await db.delete('alarm', where: 'alarm_id = ?', whereArgs: [alarmId]);
  }

  Future<void> updateAlarmEnabled(int alarmId, bool enabled) async {
    await db.update(
      'alarm',
      {'enabled': enabled ? 1 : 0},
      where: 'alarm_id = ?',
      whereArgs: [alarmId],
    );
  }

  Future<void> updateAlarmDays(
    int alarmId,
    List<int> days,
    bool enabled,
  ) async {
    // Update alarm
    await db.update(
      'alarm',
      {'enabled': enabled ? 1 : 0},
      where: 'alarm_id = ?',
      whereArgs: [alarmId],
    );
  }

  // Future<List<Map<String, dynamic>>> getAlarmOverview() async {
  //   return await db.rawQuery('''
  //   SELECT
  //     a.alarm_id,
  //     a.hour,
  //     a.minute,
  //     a.enabled,
  //     a.is_once,
  //     a.sound,
  //     a.volume,
  //     a.vibration,
  //     a.fade_in,
  //     a.disarm_mode,
  //     group_concat(d.day) AS days
  //   FROM alarm a
  //   LEFT JOIN alarm_day d ON a.alarm_id = d.alarm_id
  //   GROUP BY a.alarm_id
  //   ORDER BY a.hour, a.minute
  // ''');
  // }

  // =======================
  // ADMIN / DEBUG METHODS
  // =======================

  /// Ignore SQLite system tables
  Future<List<String>> getUserTables() async {
    final result = await db.rawQuery('''
      SELECT name FROM sqlite_master
      WHERE type='table'
      AND name NOT LIKE 'sqlite_%'
      AND name != 'android_metadata'
    ''');

    return result.map((e) => e['name'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getTableColumns(String table) async {
    return db.rawQuery('PRAGMA table_info($table)');
  }

  Future<List<Map<String, dynamic>>> getTableRows(String table) async {
    return db.query(table);
  }

  /// Auto-detect PRIMARY KEY column
  Future<String?> getPrimaryKeyColumn(String table) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final pk = info.where((c) => c['pk'] == 1).map((c) => c['name']).toList();
    return pk.isEmpty ? null : pk.first as String;
  }

  Future<void> deleteByPrimaryKey({
    required String table,
    required String pkColumn,
    required dynamic pkValue,
  }) async {
    await db.delete(table, where: '$pkColumn = ?', whereArgs: [pkValue]);
  }

  /// ---------- PRIVATE MAPPERS ----------

  AlarmModel _toModel(AlarmDbEntry entry) {
    return AlarmModel(
      alarmId: entry.alarmId!,
      title: entry.title,
      time: TimeOfDay(hour: entry.hour, minute: entry.minute),
      days: entry.days,
      enabled: entry.enabled,
      isOnce: entry.isOnce,
      snoozeSettings: entry.snoozeSettings,
      soundSettings: entry.soundSettings,
      dismissSettings: entry.dismissSettings,
    );
  }

  AlarmDbEntry _toDbEntry(AlarmModel model, String userId) {
    return AlarmDbEntry(
      alarmId: model.alarmId,
      title: model.title,
      hour: model.time.hour,
      minute: model.time.minute,
      days: model.days,
      enabled: model.enabled,
      isOnce: model.isOnce,
      userId: userId,
      wakeupCheck: model.wakeupCheck,
      snoozeSettings: model.snoozeSettings,
      soundSettings: model.soundSettings,
      dismissSettings: model.dismissSettings,
    );
  }
}
