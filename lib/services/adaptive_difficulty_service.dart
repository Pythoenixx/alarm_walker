import 'package:alarm_walker/models/dismiss_settings.dart';
import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/models/wake_log_model.dart';
import 'package:alarm_walker/models/wake_log_repository.dart';
import 'package:alarm_walker/services/settings_cubit.dart';

/// Small rule-based adaptive difficulty engine.
///
/// This is intentionally simple and explainable for FYP testing:
/// - It looks at the latest completed wake logs.
/// - It only updates default dismiss settings for future alarms.
/// - It keeps all changes within the selected profile category's safe range.
class AdaptiveDifficultyService {
  const AdaptiveDifficultyService._();

  static const int minimumLogsRequired = 3;
  static const int latestLogsToAnalyze = 5;

  static Future<AdaptiveDifficultyResult> analyze({
    required WakeLogRepository wakeRepo,
    required SettingsCubit settingsCubit,
    required ProfileCategory category,
  }) {
    return _evaluate(
      wakeRepo: wakeRepo,
      settingsCubit: settingsCubit,
      category: category,
      applyChange: false,
    );
  }

  static Future<AdaptiveDifficultyResult> evaluateAndApply({
    required WakeLogRepository wakeRepo,
    required SettingsCubit settingsCubit,
    required ProfileCategory category,
  }) {
    return _evaluate(
      wakeRepo: wakeRepo,
      settingsCubit: settingsCubit,
      category: category,
      applyChange: true,
    );
  }

  static Future<AdaptiveDifficultyResult> _evaluate({
    required WakeLogRepository wakeRepo,
    required SettingsCubit settingsCubit,
    required ProfileCategory category,
    required bool applyChange,
  }) async {
    final logs = await wakeRepo.getAllLogs();
    final completedLogs =
        logs
            .where((log) => log.disarmDurationMs > 0)
            .take(latestLogsToAnalyze)
            .toList();

    if (completedLogs.length < minimumLogsRequired) {
      return AdaptiveDifficultyResult.insufficientData(
        analyzedLogs: completedLogs.length,
      );
    }

    final metrics = AdaptiveDifficultyMetrics.fromLogs(completedLogs);
    final current = settingsCubit.state.defaultDismissSettings;

    final decision = _decide(metrics);
    if (decision == AdaptiveDifficultyDecision.noChange) {
      return AdaptiveDifficultyResult(
        decision: decision,
        analyzedLogs: completedLogs.length,
        metrics: metrics,
        changed: false,
        message: 'Wake-up performance is stable. Difficulty remains unchanged.',
      );
    }

    final next = switch (decision) {
      AdaptiveDifficultyDecision.madeEasier => _makeEasier(current, category),
      AdaptiveDifficultyDecision.madeHarder => _makeHarder(current, category),
      _ => current,
    };

    if (_sameDismissSettings(current, next)) {
      return AdaptiveDifficultyResult(
        decision: AdaptiveDifficultyDecision.noChange,
        analyzedLogs: completedLogs.length,
        metrics: metrics,
        changed: false,
        message: 'Difficulty is already at the recommended range for this profile category.',
      );
    }

    if (applyChange) {
      await settingsCubit.setDefaultDismissSettings(next);
    }

    final actionText = applyChange ? 'updated' : 'recommends';

    return AdaptiveDifficultyResult(
      decision: decision,
      analyzedLogs: completedLogs.length,
      metrics: metrics,
      changed: true,
      message:
          decision == AdaptiveDifficultyDecision.madeHarder
              ? 'Adaptive difficulty $actionText a firmer default challenge for future alarms.'
              : 'Adaptive difficulty $actionText a lighter default challenge for future alarms.',
    );
  }

  static AdaptiveDifficultyDecision _decide(AdaptiveDifficultyMetrics metrics) {
    // If the user struggles to complete alarms, make future default tasks lighter.
    if (metrics.successRate < 0.7 || metrics.averageDisarmSeconds >= 180) {
      return AdaptiveDifficultyDecision.madeEasier;
    }

    // If the user snoozes often or completes tasks too easily, make future defaults firmer.
    if (metrics.averageSnoozeCount >= 2 ||
        (metrics.successRate >= 0.85 && metrics.averageDisarmSeconds <= 45)) {
      return AdaptiveDifficultyDecision.madeHarder;
    }

    return AdaptiveDifficultyDecision.noChange;
  }

  static DismissSettings _makeHarder(
    DismissSettings current,
    ProfileCategory category,
  ) {
    final bounds = _AdaptiveDifficultyBounds.forCategory(category);

    return current.copyWith(
      mathDifficulty: _clampInt(
        current.mathDifficulty + 1,
        bounds.minMathDifficulty,
        bounds.maxMathDifficulty,
      ),
      mathProblemCount: _clampInt(
        current.mathProblemCount + 1,
        bounds.minMathProblems,
        bounds.maxMathProblems,
      ),
      mathAllowSkip: false,
      shakeCount: _clampInt(
        current.shakeCount + 2,
        bounds.minShakeCount,
        bounds.maxShakeCount,
      ),
      shakeIntensity: _clampInt(
        current.shakeIntensity + 1,
        bounds.minShakeIntensity,
        bounds.maxShakeIntensity,
      ),
      walkSteps: _clampInt(
        current.walkSteps + 5,
        bounds.minWalkSteps,
        bounds.maxWalkSteps,
      ),
    );
  }

  static DismissSettings _makeEasier(
    DismissSettings current,
    ProfileCategory category,
  ) {
    final bounds = _AdaptiveDifficultyBounds.forCategory(category);

    return current.copyWith(
      mathDifficulty: _clampInt(
        current.mathDifficulty - 1,
        bounds.minMathDifficulty,
        bounds.maxMathDifficulty,
      ),
      mathProblemCount: _clampInt(
        current.mathProblemCount - 1,
        bounds.minMathProblems,
        bounds.maxMathProblems,
      ),
      mathAllowSkip: true,
      shakeCount: _clampInt(
        current.shakeCount - 2,
        bounds.minShakeCount,
        bounds.maxShakeCount,
      ),
      shakeIntensity: _clampInt(
        current.shakeIntensity - 1,
        bounds.minShakeIntensity,
        bounds.maxShakeIntensity,
      ),
      walkSteps: _clampInt(
        current.walkSteps - 5,
        bounds.minWalkSteps,
        bounds.maxWalkSteps,
      ),
      clearTaskTimer: true,
    );
  }

  static int _clampInt(int value, int min, int max) {
    return value.clamp(min, max).toInt();
  }

  static bool _sameDismissSettings(DismissSettings a, DismissSettings b) {
    return a.toJson().toString() == b.toJson().toString();
  }
}

class AdaptiveDifficultyMetrics {
  final double successRate;
  final double averageSnoozeCount;
  final double averageDisarmSeconds;

  const AdaptiveDifficultyMetrics({
    required this.successRate,
    required this.averageSnoozeCount,
    required this.averageDisarmSeconds,
  });

  factory AdaptiveDifficultyMetrics.fromLogs(List<WakeLog> logs) {
    final total = logs.length;
    final successes = logs.where((log) => log.success).length;
    final snoozeTotal = logs.fold<int>(0, (sum, log) => sum + log.snoozeCount);
    final durationTotalMs = logs.fold<int>(
      0,
      (sum, log) => sum + log.disarmDurationMs,
    );

    return AdaptiveDifficultyMetrics(
      successRate: total == 0 ? 0 : successes / total,
      averageSnoozeCount: total == 0 ? 0 : snoozeTotal / total,
      averageDisarmSeconds: total == 0 ? 0 : durationTotalMs / total / 1000,
    );
  }
}

enum AdaptiveDifficultyDecision {
  insufficientData,
  noChange,
  madeEasier,
  madeHarder,
}

class AdaptiveDifficultyResult {
  final AdaptiveDifficultyDecision decision;
  final int analyzedLogs;
  final AdaptiveDifficultyMetrics? metrics;
  final bool changed;
  final String message;

  const AdaptiveDifficultyResult({
    required this.decision,
    required this.analyzedLogs,
    required this.metrics,
    required this.changed,
    required this.message,
  });

  factory AdaptiveDifficultyResult.insufficientData({
    required int analyzedLogs,
  }) {
    return AdaptiveDifficultyResult(
      decision: AdaptiveDifficultyDecision.insufficientData,
      analyzedLogs: analyzedLogs,
      metrics: null,
      changed: false,
      message: 'At least $AdaptiveDifficultyService.minimumLogsRequired wake logs are required before adaptive difficulty can adjust defaults.',
    );
  }
}

class _AdaptiveDifficultyBounds {
  final int minMathDifficulty;
  final int maxMathDifficulty;
  final int minMathProblems;
  final int maxMathProblems;
  final int minShakeCount;
  final int maxShakeCount;
  final int minShakeIntensity;
  final int maxShakeIntensity;
  final int minWalkSteps;
  final int maxWalkSteps;

  const _AdaptiveDifficultyBounds({
    required this.minMathDifficulty,
    required this.maxMathDifficulty,
    required this.minMathProblems,
    required this.maxMathProblems,
    required this.minShakeCount,
    required this.maxShakeCount,
    required this.minShakeIntensity,
    required this.maxShakeIntensity,
    required this.minWalkSteps,
    required this.maxWalkSteps,
  });

  factory _AdaptiveDifficultyBounds.forCategory(ProfileCategory category) {
    return switch (category) {
      ProfileCategory.child => const _AdaptiveDifficultyBounds(
        minMathDifficulty: 1,
        maxMathDifficulty: 2,
        minMathProblems: 1,
        maxMathProblems: 3,
        minShakeCount: 6,
        maxShakeCount: 12,
        minShakeIntensity: 1,
        maxShakeIntensity: 2,
        minWalkSteps: 15,
        maxWalkSteps: 35,
      ),
      ProfileCategory.adult => const _AdaptiveDifficultyBounds(
        minMathDifficulty: 1,
        maxMathDifficulty: 3,
        minMathProblems: 1,
        maxMathProblems: 5,
        minShakeCount: 8,
        maxShakeCount: 18,
        minShakeIntensity: 1,
        maxShakeIntensity: 3,
        minWalkSteps: 20,
        maxWalkSteps: 50,
      ),
      ProfileCategory.senior => const _AdaptiveDifficultyBounds(
        minMathDifficulty: 1,
        maxMathDifficulty: 2,
        minMathProblems: 1,
        maxMathProblems: 2,
        minShakeCount: 4,
        maxShakeCount: 10,
        minShakeIntensity: 1,
        maxShakeIntensity: 2,
        minWalkSteps: 10,
        maxWalkSteps: 25,
      ),
    };
  }
}
