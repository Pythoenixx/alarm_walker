import 'package:alarm_walker/services/shared_prefs_with_cache.dart';

/// Local-only debug unlock for the database viewer.
///
/// This is not a replacement for real admin security. It only controls whether
/// the hidden local SQLite viewer is shown in the mobile app settings screen.
class DatabaseDebugAccessService {
  const DatabaseDebugAccessService._();

  static const String _unlockKey = 'database_debug_access_unlocked';

  static bool get isUnlocked {
    try {
      return (SharedPreferencesWithCache.instance.get<int>(_unlockKey) ?? 0) ==
          1;
    } catch (_) {
      return false;
    }
  }

  static Future<void> unlock() async {
    await SharedPreferencesWithCache.instance.setInt(_unlockKey, 1);
  }

  static Future<void> lock() async {
    await SharedPreferencesWithCache.instance.remove(_unlockKey);
  }
}
