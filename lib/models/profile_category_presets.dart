import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/dismiss_settings.dart';
import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/models/snooze_settings.dart';

class ProfileCategoryPresets {
  const ProfileCategoryPresets._();

  static DismissSettings dismissSettingsFor(ProfileCategory category) {
    return switch (category) {
      ProfileCategory.child => const DismissSettings(
        mode: AlarmDisarmMode.shake,
        mathDifficulty: 1,
        mathProblemCount: 2,
        mathAllowSkip: true,
        shakeCount: 18,
        shakeIntensity: 1,
        walkSteps: 20,
        reTypeText: 'Wake up',
        reTypeCaseSensitive: false,
      ),
      ProfileCategory.adult => const DismissSettings(
        mode: AlarmDisarmMode.shake,
        mathDifficulty: 2,
        mathProblemCount: 3,
        mathAllowSkip: true,
        shakeCount: 30,
        shakeIntensity: 2,
        walkSteps: 30,
        reTypeText: 'I am awake',
        reTypeCaseSensitive: false,
      ),
      ProfileCategory.senior => const DismissSettings(
        mode: AlarmDisarmMode.shake,
        mathDifficulty: 1,
        mathProblemCount: 1,
        mathAllowSkip: true,
        shakeCount: 12,
        shakeIntensity: 1,
        walkSteps: 15,
        reTypeText: 'Wake up',
        reTypeCaseSensitive: false,
      ),
    };
  }

  static SnoozeSettings snoozeSettingsFor(ProfileCategory category) {
    return switch (category) {
      ProfileCategory.child => const SnoozeSettings(
        enabled: true,
        durationMinutes: 5,
        maxCount: 2,
      ),
      ProfileCategory.adult => const SnoozeSettings(
        enabled: true,
        durationMinutes: 5,
        maxCount: 3,
      ),
      ProfileCategory.senior => const SnoozeSettings(
        enabled: true,
        durationMinutes: 5,
        maxCount: 2,
      ),
    };
  }
}
