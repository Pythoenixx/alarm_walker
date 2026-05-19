import 'package:sqflite/sqflite.dart';

class AlarmDatabase {
  static Database? _db;

  static Future<void> initialize() async {
    final dir = await getDatabasesPath();
    final path = '$dir/alarms.db';
    _db = await openDatabase(
      path,
      version: 16,
      onCreate: (db, version) => _createAllTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 16) {
          await _addColumnIfMissing(
            db,
            tableName: 'user_profile',
            columnName: 'profile_category',
            definition: "TEXT NOT NULL DEFAULT 'adult'",
          );
        }
      },
    );
  }

  static Future<void> _createAllTables(Database db) async {
    await db.execute('''
      CREATE TABLE user_profile (
        user_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        language TEXT NOT NULL DEFAULT 'en',
        theme TEXT NOT NULL DEFAULT 'system',
        profile_category TEXT NOT NULL DEFAULT 'adult'
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


  static Future<void> _addColumnIfMissing(
    Database db, {
    required String tableName,
    required String columnName,
    required String definition,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final exists = columns.any((column) => column['name'] == columnName);

    if (!exists) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $definition');
    }
  }

  static Database get database {
    final db = _db;
    if (db == null) throw StateError('AlarmDatabase not initialized');
    return db;
  }
}
