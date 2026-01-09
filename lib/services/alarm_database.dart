import 'package:alarm_walker/models/alarm_db_entry.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class AlarmDatabase {
  static Database? _db;

  static Future<void> _createAllTables(Database db) async {
    await db.execute('''
    CREATE TABLE user_profile (
      user_id TEXT PRIMARY KEY,
      name TEXT,
      language TEXT,
      theme TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE alarm (
  alarm_id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  hour INTEGER,
  minute INTEGER,
  days TEXT,                -- JSON array
  enabled INTEGER,
  is_once INTEGER,
  sound TEXT,
  volume INTEGER,
  vibration INTEGER,
  fade_in INTEGER,
  disarm_mode TEXT,
  user_id TEXT
)
  ''');

    await db.execute('''
    CREATE TABLE wake_log (
      log_id INTEGER PRIMARY KEY AUTOINCREMENT,
      alarm_id INTEGER,
      wake_time TEXT,
      snooze_count INTEGER,
      success INTEGER,
      disarm_mode TEXT,
      disarm_duration INTEGER,
      FOREIGN KEY (alarm_id) REFERENCES alarm(alarm_id)
    )
  ''');
  }

  static Future<void> initialize() async {
    final dir = await getDatabasesPath();
    final path = '$dir/alarms.db';
    _db = await openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS wake_log');
        await db.execute('DROP TABLE IF EXISTS alarm_day');
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
