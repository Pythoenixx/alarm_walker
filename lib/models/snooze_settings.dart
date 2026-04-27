class SnoozeSettings {
  final bool enabled;
  final int durationMinutes;
  final int maxCount; // 0 = unlimited

  const SnoozeSettings({
    this.enabled = true,
    this.durationMinutes = 5,
    this.maxCount = 3,
  });

  SnoozeSettings copyWith({
    bool? enabled,
    int? durationMinutes,
    int? maxCount,
  }) => SnoozeSettings(
    enabled: enabled ?? this.enabled,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    maxCount: maxCount ?? this.maxCount,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'durationMinutes': durationMinutes,
    'maxCount': maxCount,
  };

  factory SnoozeSettings.fromJson(Map<String, dynamic> json) => SnoozeSettings(
    enabled: json['enabled'] as bool? ?? true,
    durationMinutes: json['durationMinutes'] as int? ?? 5,
    maxCount: json['maxCount'] as int? ?? 3,
  );
}
