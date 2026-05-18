import 'package:alarm_walker/models/dismiss_settings.dart';
import 'package:alarm_walker/models/snooze_settings.dart';
import 'package:alarm_walker/models/sound_settings.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AlarmModel {
  final int? alarmId;
  final String title;
  final TimeOfDay time;
  final List<int> days;
  final bool enabled;
  final bool isOnce;
  final bool wakeupCheck;
  final SnoozeSettings snoozeSettings;
  final SoundSettings soundSettings;
  final DismissSettings dismissSettings;

  const AlarmModel({
    this.alarmId,
    required this.title,
    required this.time,
    required this.days,
    required this.enabled,
    required this.isOnce,
    required this.wakeupCheck,
    required this.snoozeSettings,
    required this.soundSettings,
    required this.dismissSettings,
  });

  factory AlarmModel.fromSettings(SettingsState s) => AlarmModel(
    alarmId: null,
    title: '',
    time: TimeOfDay.now(),
    days: const [],
    enabled: true,
    isOnce: false,
    wakeupCheck: false,
    snoozeSettings: const SnoozeSettings(),
    soundSettings: SoundSettings(
      overrideVolume: true,
      volume: s.defaultVolume,
      soundPath: s.defaultAudioPath,
      gradualVolumeIncrease: s.defaultFadeIn,
      vibrate: s.defaultVibration,
      flashlight: s.defaultFlashlight,
    ),
    dismissSettings: DismissSettings(mode: s.defaultAlarmDisarmMode),
  );

  AlarmModel copyWith({
    int? alarmId,
    String? title,
    TimeOfDay? time,
    List<int>? days,
    bool? enabled,
    bool? isOnce,
    bool? wakeupCheck,
    SnoozeSettings? snoozeSettings,
    SoundSettings? soundSettings,
    DismissSettings? dismissSettings,
  }) => AlarmModel(
    alarmId: alarmId ?? this.alarmId,
    title: title ?? this.title,
    time: time ?? this.time,
    days: days ?? this.days,
    enabled: enabled ?? this.enabled,
    isOnce: isOnce ?? this.isOnce,
    wakeupCheck: wakeupCheck ?? this.wakeupCheck,
    snoozeSettings: snoozeSettings ?? this.snoozeSettings,
    soundSettings: soundSettings ?? this.soundSettings,
    dismissSettings: dismissSettings ?? this.dismissSettings,
  );

  @override
  bool operator ==(Object other) =>
      other is AlarmModel &&
      other.alarmId == alarmId &&
      other.title == title &&
      other.time == time &&
      listEquals(other.days, days) &&
      other.enabled == enabled &&
      other.isOnce == isOnce &&
      other.wakeupCheck == wakeupCheck &&
      other.snoozeSettings == snoozeSettings &&
      other.soundSettings == soundSettings &&
      other.dismissSettings == dismissSettings;

  @override
  int get hashCode => Object.hashAll([
    alarmId,
    title,
    time,
    days,
    enabled,
    isOnce,
    wakeupCheck,
    snoozeSettings,
    soundSettings,
    dismissSettings,
  ]);
}

enum AlarmResult { success, failed, snoozed }

enum AlarmDisarmMode { walk, math, shake, retype, normal }

extension AlarmDisarmModeX on AlarmDisarmMode {
  String get dbValue => name;

  static AlarmDisarmMode fromDb(String value) => AlarmDisarmMode.values
      .firstWhere((e) => e.name == value, orElse: () => AlarmDisarmMode.normal);
}
