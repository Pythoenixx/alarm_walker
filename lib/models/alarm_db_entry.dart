import 'dart:convert';

class AlarmDbEntry {
  final int? alarmId;
  final String title;
  final int hour;
  final int minute;
  final List<int> days;
  final bool enabled;
  final bool isOnce;
  final String sound;
  final int volume;
  final bool vibration;
  final bool fadeIn;
  final String disarmMode;
  final String userId;

  AlarmDbEntry({
    this.alarmId,
    required this.title,
    required this.hour,
    required this.minute,
    required this.days,
    required this.enabled,
    required this.isOnce,
    required this.sound,
    required this.volume,
    required this.vibration,
    required this.fadeIn,
    required this.disarmMode,
    required this.userId,
  });

  Map<String, dynamic> toMap() => {
    'alarm_id': alarmId,
    'title': title,
    'hour': hour,
    'minute': minute,
    'days': jsonEncode(days),
    'enabled': enabled ? 1 : 0,
    'is_once': isOnce ? 1 : 0,
    'sound': sound,
    'volume': volume,
    'vibration': vibration ? 1 : 0,
    'fade_in': fadeIn ? 1 : 0,
    'disarm_mode': disarmMode,
    'user_id': userId,
  };

  factory AlarmDbEntry.fromMap(Map<String, dynamic> map) {
    return AlarmDbEntry(
      alarmId: map['alarm_id'] as int,
      title: map['title'],
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      days: List<int>.from(jsonDecode(map['days'])),
      enabled: map['enabled'] == 1,
      isOnce: map['is_once'] == 1,
      sound: map['sound'],
      volume: map['volume'],
      vibration: map['vibration'] == 1,
      fadeIn: map['fade_in'] == 1,
      disarmMode: map['disarm_mode'],
      userId: map['user_id'],
    );
  }
}
