import 'package:alarm_walker/models/alarm_model.dart';

class DismissSettings {
  final AlarmDisarmMode mode;
  // Walk
  final int walkSteps;
  // Math
  final int mathDifficulty; // 1 = easy, 2 = medium, 3 = hard
  final int mathProblemCount;
  final bool mathAllowSkip;
  // Shake
  final int shakeCount;
  final int shakeIntensity; // 1–3
  // Retype
  final String reTypeText;
  final bool reTypeCaseSensitive;
  // General
  final int? taskTimerSeconds; // null = no timer per problem

  const DismissSettings({
    this.mode = AlarmDisarmMode.shake,
    this.walkSteps = 20,
    this.mathDifficulty = 1,
    this.mathProblemCount = 1,
    this.mathAllowSkip = true,
    this.shakeCount = 30,
    this.shakeIntensity = 1,
    this.reTypeText = '',
    this.reTypeCaseSensitive = true,
    this.taskTimerSeconds,
  });

  DismissSettings copyWith({
    AlarmDisarmMode? mode,
    int? walkSteps,
    int? mathDifficulty,
    int? mathProblemCount,
    bool? mathAllowSkip,
    int? shakeCount,
    int? shakeIntensity,
    String? reTypeText,
    bool? reTypeCaseSensitive,
    int? taskTimerSeconds,
    bool clearTaskTimer = false,
  }) => DismissSettings(
    mode: mode ?? this.mode,
    walkSteps: walkSteps ?? this.walkSteps,
    mathDifficulty: mathDifficulty ?? this.mathDifficulty,
    mathProblemCount: mathProblemCount ?? this.mathProblemCount,
    mathAllowSkip: mathAllowSkip ?? this.mathAllowSkip,
    shakeCount: shakeCount ?? this.shakeCount,
    shakeIntensity: shakeIntensity ?? this.shakeIntensity,
    reTypeText: reTypeText ?? this.reTypeText,
    reTypeCaseSensitive: reTypeCaseSensitive ?? this.reTypeCaseSensitive,
    taskTimerSeconds:
        clearTaskTimer ? null : taskTimerSeconds ?? this.taskTimerSeconds,
  );

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'walkSteps': walkSteps,
    'mathDifficulty': mathDifficulty,
    'mathProblemCount': mathProblemCount,
    'mathAllowSkip': mathAllowSkip,
    'shakeCount': shakeCount,
    'shakeIntensity': shakeIntensity,
    'reTypeText': reTypeText,
    'reTypeCaseSensitive': reTypeCaseSensitive,
    'taskTimerSeconds': taskTimerSeconds,
  };

  factory DismissSettings.fromJson(Map<String, dynamic> json) =>
      DismissSettings(
        mode: AlarmDisarmMode.values.firstWhere(
          (e) => e.name == json['mode'],
          orElse: () => AlarmDisarmMode.shake,
        ),
        walkSteps: json['walkSteps'] as int? ?? 20,
        mathDifficulty: json['mathDifficulty'] as int? ?? 1,
        mathProblemCount: json['mathProblemCount'] as int? ?? 1,
        mathAllowSkip: json['mathAllowSkip'] as bool? ?? true,
        shakeCount: json['shakeCount'] as int? ?? 30,
        shakeIntensity: json['shakeIntensity'] as int? ?? 1,
        reTypeText: json['reTypeText'] as String? ?? '',
        reTypeCaseSensitive: json['reTypeCaseSensitive'] as bool? ?? true,
        taskTimerSeconds: json['taskTimerSeconds'] as int?,
      );
}
