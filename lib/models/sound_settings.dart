class SoundSettings {
  static const defaultSoundPath = 'assets/sounds/alarm_1.mp3';
  static const defaultSoundName = 'Alarm 1';

  final String? soundPath;
  final String? soundName;
  final bool overrideVolume;
  final double volume; // 0.0–1.0, used only if overrideVolume is true
  final bool allowMidAlarmVolumeChange;
  final bool gradualVolumeIncrease;
  final int gradualIncreaseDurationSeconds;
  final bool vibrate;
  final bool flashlight;

  const SoundSettings({
    this.soundPath = defaultSoundPath,
    this.soundName = defaultSoundName,
    this.overrideVolume = false,
    this.volume = 0.8,
    this.allowMidAlarmVolumeChange = true,
    this.gradualVolumeIncrease = false,
    this.gradualIncreaseDurationSeconds = 30,
    this.vibrate = true,
    this.flashlight = false,
  });

  SoundSettings copyWith({
    String? soundPath,
    String? soundName,
    bool? overrideVolume,
    double? volume,
    bool? allowMidAlarmVolumeChange,
    bool? gradualVolumeIncrease,
    int? gradualIncreaseDurationSeconds,
    bool? vibrate,
    bool? flashlight,
    bool clearSound = false,
  }) => SoundSettings(
    soundPath: clearSound ? null : soundPath ?? this.soundPath,
    soundName: clearSound ? null : soundName ?? this.soundName,
    overrideVolume: overrideVolume ?? this.overrideVolume,
    volume: volume ?? this.volume,
    allowMidAlarmVolumeChange:
        allowMidAlarmVolumeChange ?? this.allowMidAlarmVolumeChange,
    gradualVolumeIncrease: gradualVolumeIncrease ?? this.gradualVolumeIncrease,
    gradualIncreaseDurationSeconds:
        gradualIncreaseDurationSeconds ?? this.gradualIncreaseDurationSeconds,
    vibrate: vibrate ?? this.vibrate,
    flashlight: flashlight ?? this.flashlight,
  );

  Map<String, dynamic> toJson() => {
    'soundPath': soundPath,
    'soundName': soundName,
    'overrideVolume': overrideVolume,
    'volume': volume,
    'allowMidAlarmVolumeChange': allowMidAlarmVolumeChange,
    'gradualVolumeIncrease': gradualVolumeIncrease,
    'gradualIncreaseDurationSeconds': gradualIncreaseDurationSeconds,
    'vibrate': vibrate,
    'flashlight': flashlight,
  };

  factory SoundSettings.fromJson(Map<String, dynamic> json) => SoundSettings(
    soundPath:
        json.containsKey('soundPath')
            ? json['soundPath'] as String?
            : defaultSoundPath,
    soundName:
        json.containsKey('soundName')
            ? json['soundName'] as String?
            : defaultSoundName,
    overrideVolume: json['overrideVolume'] as bool? ?? false,
    volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
    allowMidAlarmVolumeChange:
        json['allowMidAlarmVolumeChange'] as bool? ?? true,
    gradualVolumeIncrease: json['gradualVolumeIncrease'] as bool? ?? false,
    gradualIncreaseDurationSeconds:
        json['gradualIncreaseDurationSeconds'] as int? ?? 30,
    vibrate: json['vibrate'] as bool? ?? true,
    flashlight: json['flashlight'] as bool? ?? false,
  );
}
