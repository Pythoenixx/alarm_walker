import 'dart:convert';
import 'dart:typed_data';

import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/models/user_profile_model.dart';
import 'package:alarm_walker/models/user_profile_repository.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';

class BackupRestoreResult {
  final bool success;
  final String message;

  const BackupRestoreResult({required this.success, required this.message});
}

class BackupRestoreService {
  static const String appId = 'alarm_walker';
  static const int backupVersion = 1;

  final Database db;
  final UserProfileRepository userRepo;
  final SettingsCubit settingsCubit;

  const BackupRestoreService({
    required this.db,
    required this.userRepo,
    required this.settingsCubit,
  });

  String get currentOwnerId => FirebaseAuth.instance.currentUser?.uid ?? 'local';

  Future<BackupRestoreResult> exportCurrentUserBackup() async {
    try {
      final ownerId = currentOwnerId;
      final backup = await _buildBackupMap(ownerId);
      final prettyJson = const JsonEncoder.withIndent('  ').convert(backup);
      final bytes = Uint8List.fromList(utf8.encode(prettyJson));
      final fileName = _backupFileName();

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Alarm Walker backup',
        fileName: fileName,
        bytes: bytes,
      );

      if (savedPath == null) {
        return const BackupRestoreResult(
          success: false,
          message: 'Backup export cancelled.',
        );
      }

      return BackupRestoreResult(
        success: true,
        message: 'Backup exported successfully.',
      );
    } catch (_) {
      return const BackupRestoreResult(
        success: false,
        message: 'Unable to export backup. Please try again.',
      );
    }
  }

  Future<BackupRestoreResult> importBackupForCurrentUser() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null) {
        return const BackupRestoreResult(
          success: false,
          message: 'Restore cancelled.',
        );
      }

      final file = result.files.single;
      final data = file.bytes;

      if (data == null || data.isEmpty) {
        return const BackupRestoreResult(
          success: false,
          message: 'Unable to read selected backup file.',
        );
      }

      final decoded = jsonDecode(utf8.decode(data));
      if (decoded is! Map<String, dynamic>) {
        return const BackupRestoreResult(
          success: false,
          message: 'Invalid backup file format.',
        );
      }

      await _restoreBackupMap(decoded, currentOwnerId);

      return const BackupRestoreResult(
        success: true,
        message: 'Backup restored successfully.',
      );
    } catch (_) {
      return const BackupRestoreResult(
        success: false,
        message: 'Unable to restore backup. Please select a valid backup file.',
      );
    }
  }

  Future<Map<String, dynamic>> _buildBackupMap(String ownerId) async {
    final profile =
        await userRepo.getProfile(ownerId) ??
        UserProfile(
          userId: ownerId,
          name: '',
          language: 'en',
          theme: 'system',
          profileCategory: ProfileCategory.fallback,
        );

    final alarms = await db.query(
      'alarm',
      where: 'user_id = ?',
      whereArgs: [ownerId],
      orderBy: 'alarm_id ASC',
    );

    final wakeLogs = await db.rawQuery(
      '''
      SELECT wake_log.*
      FROM wake_log
      INNER JOIN alarm ON alarm.alarm_id = wake_log.alarm_id
      WHERE alarm.user_id = ?
      ORDER BY wake_log.wake_time ASC
      ''',
      [ownerId],
    );

    return {
      'app': appId,
      'version': backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'ownerType': ownerId == 'local' ? 'local' : 'firebase',
      'profile': {
        'name': profile.name,
        'language': profile.language,
        'theme': profile.theme,
        'profileCategory': profile.profileCategory.name,
      },
      'settings': settingsCubit.state.toBackupJson(),
      'alarms': alarms,
      'wakeLogs': wakeLogs,
    };
  }

  Future<void> _restoreBackupMap(
    Map<String, dynamic> backup,
    String ownerId,
  ) async {
    if (backup['app'] != appId) {
      throw const FormatException('Not an Alarm Walker backup.');
    }

    if (backup['version'] != backupVersion) {
      throw const FormatException('Unsupported backup version.');
    }

    final profileMap = _asStringKeyedMap(backup['profile']);
    final settingsMap = _asStringKeyedMap(backup['settings']);
    final alarms = _asMapList(backup['alarms']);
    final wakeLogs = _asMapList(backup['wakeLogs']);

    await settingsCubit.restoreFromBackupJson(settingsMap);

    await userRepo.saveProfile(
      UserProfile(
        userId: ownerId,
        name: profileMap['name'] as String? ?? '',
        language: profileMap['language'] as String? ?? 'en',
        theme: profileMap['theme'] as String? ?? 'system',
        profileCategory: ProfileCategory.fromName(
          profileMap['profileCategory'] as String?,
        ),
      ),
    );

    await db.transaction((txn) async {
      final existingAlarmRows = await txn.query(
        'alarm',
        columns: const ['alarm_id'],
        where: 'user_id = ?',
        whereArgs: [ownerId],
      );
      final existingIds =
          existingAlarmRows
              .map((row) => row['alarm_id'])
              .whereType<int>()
              .toList();

      if (existingIds.isNotEmpty) {
        final placeholders = List.filled(existingIds.length, '?').join(',');
        await txn.delete(
          'wake_log',
          where: 'alarm_id IN ($placeholders)',
          whereArgs: existingIds,
        );
      }

      await txn.delete('alarm', where: 'user_id = ?', whereArgs: [ownerId]);

      final oldToNewAlarmIds = <int, int>{};

      for (final alarm in alarms) {
        final oldAlarmId = _readInt(alarm['alarm_id']);
        final row = <String, Object?>{
          'user_id': ownerId,
          'title': alarm['title'] as String? ?? '',
          'hour': _readInt(alarm['hour']) ?? 0,
          'minute': _readInt(alarm['minute']) ?? 0,
          'days': alarm['days'] as String? ?? '[]',
          'enabled': _readInt(alarm['enabled']) ?? 1,
          'is_once': _readInt(alarm['is_once']) ?? 0,
          'wakeup_check': _readInt(alarm['wakeup_check']) ?? 0,
          'snooze_settings': alarm['snooze_settings'] as String? ?? '{}',
          'sound_settings': alarm['sound_settings'] as String? ?? '{}',
          'dismiss_settings': alarm['dismiss_settings'] as String? ?? '{}',
        };

        final newAlarmId = await txn.insert('alarm', row);
        if (oldAlarmId != null) oldToNewAlarmIds[oldAlarmId] = newAlarmId;
      }

      for (final log in wakeLogs) {
        final oldAlarmId = _readInt(log['alarm_id']);
        if (oldAlarmId == null) continue;

        final newAlarmId = oldToNewAlarmIds[oldAlarmId];
        if (newAlarmId == null) continue;

        await txn.insert('wake_log', {
          'alarm_id': newAlarmId,
          'wake_time': log['wake_time'] as String? ?? DateTime.now().toIso8601String(),
          'snooze_count': _readInt(log['snooze_count']) ?? 0,
          'success': _readInt(log['success']) ?? 0,
          'disarm_mode': log['disarm_mode'] as String? ?? 'normal',
          'disarm_duration': _readInt(log['disarm_duration']) ?? 0,
        });
      }
    });
  }

  Map<String, dynamic> _asStringKeyedMap(Object? value) {
    if (value is! Map) return <String, dynamic>{};
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  List<Map<String, dynamic>> _asMapList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((row) => row.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
  }

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _backupFileName() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'alarm_walker_backup_'
        '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}.json';
  }
}
