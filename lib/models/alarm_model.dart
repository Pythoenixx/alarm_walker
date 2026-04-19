import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AlarmModel {
  final int? alarmId;
  final String title;
  final TimeOfDay time;
  final List<int> days; // 1–7
  final bool enabled;
  final bool isOnce;
  final String sound;
  final int volume;
  final bool vibration;
  final bool fadeIn;
  final String disarmMode;

  AlarmModel({
    required this.alarmId,
    required this.title,
    required this.time,
    required this.days,
    this.enabled = true,
    this.isOnce = false,
    this.sound = 'default',
    this.volume = 5,
    this.vibration = true,
    this.fadeIn = false,
    required this.disarmMode,
  });

  @override
  bool operator ==(Object other) {
    return other is AlarmModel &&
        other.alarmId == alarmId &&
        other.title == title &&
        other.time == time &&
        listEquals(other.days, days) &&
        other.enabled == enabled &&
        other.isOnce == isOnce &&
        other.sound == sound &&
        other.volume == volume &&
        other.vibration == vibration &&
        other.fadeIn == fadeIn &&
        other.disarmMode == disarmMode;
  }

  @override
  int get hashCode => Object.hash(
    alarmId,
    title,
    time,
    days,
    enabled,
    isOnce,
    sound,
    volume,
    vibration,
    fadeIn,
    disarmMode,
  );
}

enum AlarmResult { success, failed, snoozed }

enum AlarmDisarmMode { walk, math, shake, retype, normal }

extension AlarmDisarmModeX on AlarmDisarmMode {
  String get dbValue => name; // Dart enum name → string

  static AlarmDisarmMode fromDb(String value) {
    return AlarmDisarmMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlarmDisarmMode.normal,
    );
  }
}
