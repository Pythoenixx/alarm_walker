import 'package:sqflite/sqflite.dart';

class AlarmDatabase {
  static Database? _db;

  static Future<void> initialize() async {
    final dir = await getDatabasesPath();
    final path = '$dir/alarms.db';
    _db = await openDatabase(
      path,
      version: 14,
      onCreate: (db, version) => _createAllTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS wake_log');
        await db.execute('DROP TABLE IF EXISTS alarm');
        await db.execute('DROP TABLE IF EXISTS user_profile');
        await _createAllTables(db);
      },
    );
  }

  static Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE user_profile (
        user_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        language TEXT NOT NULL DEFAULT 'en',
        theme TEXT NOT NULL DEFAULT 'system'
      )
    ''');
    await db.execute('''
      CREATE TABLE alarm (
        alarm_id        INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id         TEXT    NOT NULL DEFAULT 'local',
        title           TEXT    NOT NULL,
        hour            INTEGER NOT NULL CHECK(hour BETWEEN 0 AND 23),
        minute          INTEGER NOT NULL CHECK(minute BETWEEN 0 AND 59),
        days            TEXT    NOT NULL,
        enabled         INTEGER NOT NULL DEFAULT 1,
        is_once         INTEGER NOT NULL DEFAULT 0,
        wakeup_check    INTEGER NOT NULL DEFAULT 0,
        snooze_settings TEXT    NOT NULL,
        sound_settings  TEXT    NOT NULL,
        dismiss_settings TEXT   NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profile(user_id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE wake_log (
        log_id          INTEGER PRIMARY KEY AUTOINCREMENT,
        alarm_id        INTEGER NOT NULL,
        wake_time       TEXT    NOT NULL,
        snooze_count    INTEGER NOT NULL DEFAULT 0,
        success         INTEGER NOT NULL,
        disarm_mode     TEXT    NOT NULL,
        disarm_duration INTEGER NOT NULL,
        FOREIGN KEY (alarm_id) REFERENCES alarm(alarm_id) ON DELETE CASCADE
      )
    ''');
  }

  static Database get database {
    final db = _db;
    if (db == null) throw StateError('AlarmDatabase not initialized');
    return db;
  }
}
