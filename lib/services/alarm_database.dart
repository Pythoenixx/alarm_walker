import 'package:alarm_walker/models/alarm_db_entry.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class AlarmDatabase {
  static Database? _db;

  static Future<void> _createAllTables(Database db) async {
    await db.execute('''
    CREATE TABLE user_profile (
  user_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  language TEXT NOT NULL DEFAULT 'en',
  theme TEXT NOT NULL DEFAULT 'system'
);
  ''');

    await db.execute('''
    CREATE TABLE alarm (
  alarm_id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL DEFAULT 'local',

  title TEXT NOT NULL,
  hour INTEGER NOT NULL CHECK(hour BETWEEN 0 AND 23),
  minute INTEGER NOT NULL CHECK(minute BETWEEN 0 AND 59),

  days TEXT NOT NULL,              -- JSON array: [1,2,3]
  enabled INTEGER NOT NULL DEFAULT 1,
  is_once INTEGER NOT NULL DEFAULT 0,

  sound TEXT NOT NULL,
  volume INTEGER NOT NULL,
  vibration INTEGER NOT NULL,
  fade_in INTEGER NOT NULL,
  disarm_mode TEXT NOT NULL,

  FOREIGN KEY (user_id)
    REFERENCES user_profile(user_id)
    ON DELETE CASCADE
);
  ''');

    await db.execute('''
    CREATE TABLE wake_log (
  log_id INTEGER PRIMARY KEY AUTOINCREMENT,
  alarm_id INTEGER NOT NULL,

  wake_time TEXT NOT NULL,          -- ISO8601
  snooze_count INTEGER NOT NULL DEFAULT 0,
  success INTEGER NOT NULL,
  disarm_mode TEXT NOT NULL,
  disarm_duration INTEGER NOT NULL,

  FOREIGN KEY (alarm_id)
    REFERENCES alarm(alarm_id)
    ON DELETE CASCADE
);

  ''');
  }

  static Future<void> initialize() async {
    final dir = await getDatabasesPath();
    final path = '$dir/alarms.db';
    _db = await openDatabase(
      path,
      version: 10,
      onCreate: (db, version) async {
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS wake_log');
        await db.execute('DROP TABLE IF EXISTS alarm');
        await db.execute('DROP TABLE IF EXISTS user_profile');

        await _createAllTables(db);
      },
    );
  }

  static Database get _database {
    final database = _db;
    if (database == null) {
      throw Exception('AlarmDatabase not initialized');
    }
    return database;
  }

  static Future<List<AlarmDbEntry>> allAlarms() async {
    final rows = await _database.query('alarms');
    return rows.map(AlarmDbEntry.fromMap).toList();
  }

  static Future<AlarmDbEntry?> getAlarm(TimeOfDay time) async {
    final key = '${time.hour}:${time.minute}';
    final rows = await _database.query(
      'alarms',
      where: 'time = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return AlarmDbEntry.fromMap(rows.first);
  }

  static Future<void> insertOrUpdate(AlarmDbEntry entry) async {
    await _database.insert(
      'alarms',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Database get database => _database;

  static Future<void> delete(TimeOfDay time) async {
    final key = '${time.hour}:${time.minute}';
    await _database.delete('alarms', where: 'time = ?', whereArgs: [key]);
  }
}
