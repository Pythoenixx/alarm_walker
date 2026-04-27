import 'dart:convert';

import 'package:alarm_walker/models/dismiss_settings.dart';
import 'package:alarm_walker/models/snooze_settings.dart';
import 'package:alarm_walker/models/sound_settings.dart';

class AlarmDbEntry {
  final int? alarmId;
  final String title;
  final int hour;
  final int minute;
  final List<int> days;
  final bool enabled;
  final bool isOnce;
  final bool wakeupCheck;
  final String userId;

  final SnoozeSettings snoozeSettings;
  final SoundSettings soundSettings;
  final DismissSettings dismissSettings;

  AlarmDbEntry({
    this.alarmId,
    required this.title,
    required this.hour,
    required this.minute,
    required this.days,
    required this.enabled,
    required this.isOnce,
    required this.wakeupCheck,
    required this.userId,
    required this.snoozeSettings,
    required this.soundSettings,
    required this.dismissSettings,
  });

  Map<String, dynamic> toMap() => {
    'alarm_id': alarmId,
    'title': title,
    'hour': hour,
    'minute': minute,
    'days': jsonEncode(days),
    'enabled': enabled ? 1 : 0,
    'is_once': isOnce ? 1 : 0,
    'wakeup_check': wakeupCheck ? 1 : 0,
    'user_id': userId,
    // Calling your .toJson() methods here
    'snooze_settings': jsonEncode(snoozeSettings.toJson()),
    'sound_settings': jsonEncode(soundSettings.toJson()),
    'dismiss_settings': jsonEncode(dismissSettings.toJson()),
  };

  factory AlarmDbEntry.fromMap(Map<String, dynamic> map) {
    return AlarmDbEntry(
      alarmId: map['alarm_id'] as int?,
      title: map['title'] ?? '',
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      days: List<int>.from(jsonDecode(map['days'] ?? '[]')),
      enabled: map['enabled'] == 1,
      isOnce: map['is_once'] == 1,
      wakeupCheck: map['wakeup_check'] == 1,
      userId: map['user_id'] ?? '',

      // Using your .fromJson() factories here
      snoozeSettings:
          map['snooze_settings'] != null
              ? SnoozeSettings.fromJson(jsonDecode(map['snooze_settings']))
              : const SnoozeSettings(),

      soundSettings:
          map['sound_settings'] != null
              ? SoundSettings.fromJson(jsonDecode(map['sound_settings']))
              : const SoundSettings(),

      dismissSettings:
          map['dismiss_settings'] != null
              ? DismissSettings.fromJson(jsonDecode(map['dismiss_settings']))
              : const DismissSettings(),
    );
  }
}
