import 'package:alarm_walker/models/user_profile_db_entry.dart';
import 'package:alarm_walker/models/user_profile_model.dart';
import 'package:sqflite/sqflite.dart';

class UserProfileRepository {
  final Database db;

  UserProfileRepository(this.db);

  Future<UserProfile?> getProfile(String userId) async {
    final rows = await db.query(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final entry = UserProfileDbEntry.fromMap(rows.first);
    return _toModel(entry);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final entry = _toDbEntry(profile);

    await db.insert(
      'user_profile',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 🔁 Mapping
  UserProfile _toModel(UserProfileDbEntry entry) => UserProfile(
    userId: entry.userId,
    name: entry.name,
    language: entry.language,
    theme: entry.theme,
  );

  UserProfileDbEntry _toDbEntry(UserProfile model) => UserProfileDbEntry(
    userId: model.userId,
    name: model.name,
    language: model.language,
    theme: model.theme,
  );
}
