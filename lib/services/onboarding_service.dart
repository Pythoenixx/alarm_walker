import 'package:alarm_walker/services/shared_prefs_with_cache.dart';

class OnboardingService {
  const OnboardingService._();

  static const _completedKey = 'onboardingCompleted';

  static bool get isCompleted {
    return (SharedPreferencesWithCache.instance.get<int>(_completedKey) ?? 0) == 1;
  }

  static Future<void> markCompleted() async {
    await SharedPreferencesWithCache.instance.setInt(_completedKey, 1);
  }
}
