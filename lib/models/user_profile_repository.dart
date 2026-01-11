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

  Future<void> upsertLocalProfile(UserProfile profile) async {
    await db.insert('user_profile', {
      'user_id': profile.userId,
      'name': profile.name,
      'language': profile.language,
      'theme': profile.theme,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Update user's display name in local profile
  Future<void> updateName({
    required String userId,
    required String name,
  }) async {
    final count = await db.update(
      'user_profile',
      {'name': name},
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (count == 0) {
      throw Exception('User profile not found for userId=$userId');
    }
  }

  /// Get currently stored local profile
  Future<UserProfile?> getLocalProfile() async {
    final rows = await db.query('user_profile', limit: 1);

    if (rows.isEmpty) return null;

    final row = rows.first;

    return UserProfile(
      userId: row['user_id'] as String,
      name: row['name'] as String,
      language: row['language'] as String,
      theme: row['theme'] as String,
    );
  }

  /// Optional: clear profile on logout
  Future<void> clearLocalProfile() async {
    await db.delete('user_profile');
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
