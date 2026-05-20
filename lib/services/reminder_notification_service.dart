import 'dart:async';

import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:alarm_walker/services/shared_prefs_with_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ReminderNotificationService {
  ReminderNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _nextAlarmNotificationId = 7001;
  static const int _bedtimeNotificationId = 7002;
  static const int _weekendNotificationId = 7003;

  static const String _channelId = 'alarm_walker_reminders';
  static const String _channelName = 'Alarm Walker Reminders';
  static const String _channelDescription =
      'Bedtime, weekend, and next-alarm reminder notifications.';

  static const String _bedtimeShownKey = 'reminder_bedtime_shown_date';
  static const String _weekendShownKey = 'reminder_weekend_shown_date';

  static bool _initialized = false;
  static Timer? _bedtimeTimer;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    _initialized = true;
  }

  static Future<void> sync({
    required SettingsState settings,
    required List<AlarmModel> alarms,
  }) async {
    await initialize();

    if (settings.vacationModeEnabled) {
      await cancelNextAlarmNotification();
      _bedtimeTimer?.cancel();
      return;
    }

    if (settings.stickyAlarmTimeEnabled) {
      await showNextAlarmNotification(alarms, settings);
    } else {
      await cancelNextAlarmNotification();
    }

    await _checkBedtimeReminder(settings);
    _scheduleBedtimeCheck(settings);
    await _checkWeekendReminder(settings, alarms);
  }

  static Future<void> cancelAllReminderNotifications() async {
    await initialize();
    await cancelNextAlarmNotification();
    await _plugin.cancel(id: _bedtimeNotificationId);
    await _plugin.cancel(id: _weekendNotificationId);
    _bedtimeTimer?.cancel();
  }

  static Future<void> cancelNextAlarmNotification() async {
    await initialize();
    await _plugin.cancel(id: _nextAlarmNotificationId);
  }

  static Future<void> showNextAlarmNotification(
    List<AlarmModel> alarms,
    SettingsState settings,
  ) async {
    final nextAlarm = _findNextAlarm(alarms);

    if (nextAlarm == null) {
      await cancelNextAlarmNotification();
      return;
    }

    final details = _notificationDetails(
      ongoing: true,
      silent: true,
      importance: Importance.low,
      priority: Priority.low,
    );

    await _plugin.show(
      id: _nextAlarmNotificationId,
      title: 'Next alarm is ready',
      body: _nextAlarmDescription(nextAlarm, settings),
      notificationDetails: details,
    );
  }

  static Future<void> _checkBedtimeReminder(SettingsState settings) async {
    if (!settings.bedtimeAlertEnabled) return;

    final now = DateTime.now();
    final todayBedtime = DateTime(
      now.year,
      now.month,
      now.day,
      settings.bedtimeAlertTime.hour,
      settings.bedtimeAlertTime.minute,
    );

    if (now.isBefore(todayBedtime)) return;

    final todayKey = _dateKey(now);
    final lastShown = SharedPreferencesWithCache.instance.get<String>(
      _bedtimeShownKey,
    );

    if (lastShown == todayKey) return;

    await SharedPreferencesWithCache.instance.setString(
      _bedtimeShownKey,
      todayKey,
    );

    await _plugin.show(
      id: _bedtimeNotificationId,
      title: 'Bedtime reminder',
      body: 'It is close to your bedtime. Prepare your alarm and get ready to rest.',
      notificationDetails: _notificationDetails(),
    );
  }

  static void _scheduleBedtimeCheck(SettingsState settings) {
    _bedtimeTimer?.cancel();
    if (!settings.bedtimeAlertEnabled || settings.vacationModeEnabled) return;

    final now = DateTime.now();
    var bedtime = DateTime(
      now.year,
      now.month,
      now.day,
      settings.bedtimeAlertTime.hour,
      settings.bedtimeAlertTime.minute,
    );

    if (!bedtime.isAfter(now)) {
      bedtime = bedtime.add(const Duration(days: 1));
    }

    final delay = bedtime.difference(now);
    _bedtimeTimer = Timer(delay, () async {
      await _checkBedtimeReminder(settings);
    });
  }

  static Future<void> _checkWeekendReminder(
    SettingsState settings,
    List<AlarmModel> alarms,
  ) async {
    if (!settings.weekendReminderEnabled) return;

    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    if (!isWeekend) return;

    final todayKey = _dateKey(now);
    final lastShown = SharedPreferencesWithCache.instance.get<String>(
      _weekendShownKey,
    );
    if (lastShown == todayKey) return;

    final hasWeekdayAlarm = alarms.any(
      (alarm) =>
          alarm.enabled &&
          alarm.days.any(
            (day) => day >= DateTime.monday && day <= DateTime.friday,
          ),
    );

    if (hasWeekdayAlarm) return;

    await SharedPreferencesWithCache.instance.setString(
      _weekendShownKey,
      todayKey,
    );

    await _plugin.show(
      id: _weekendNotificationId,
      title: 'No weekday alarm set',
      body: 'You do not have an active Monday to Friday alarm for next week. Set one now to avoid oversleeping.',
      notificationDetails: _notificationDetails(),
    );
  }

  static NotificationDetails _notificationDetails({
    bool ongoing = false,
    bool silent = false,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: importance,
        priority: priority,
        autoCancel: !ongoing,
        ongoing: ongoing,
        silent: silent,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  static AlarmModel? _findNextAlarm(List<AlarmModel> alarms) {
    final enabled = alarms.where((alarm) => alarm.enabled).toList();
    if (enabled.isEmpty) return null;

    enabled.sort((a, b) => _nextOccurrence(a).compareTo(_nextOccurrence(b)));
    return enabled.first;
  }

  static DateTime _nextOccurrence(AlarmModel alarm) {
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.time.hour,
        alarm.time.minute,
      ).add(Duration(days: i));

      if (!alarm.days.contains(candidate.weekday)) continue;
      if (candidate.isBefore(now)) continue;
      return candidate;
    }

    return DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    ).add(const Duration(days: 1));
  }

  static String _nextAlarmDescription(
    AlarmModel alarm,
    SettingsState settings,
  ) {
    final next = _nextOccurrence(alarm);
    final time = _formatTime(alarm.time, settings.use24HourFormat);
    final dayLabel = _relativeDayLabel(next);
    final title = alarm.title.trim().isEmpty ? 'Alarm' : alarm.title.trim();

    return '$title · $time $dayLabel';
  }

  static String _formatTime(TimeOfDay time, bool use24HourFormat) {
    if (use24HourFormat) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  static String _relativeDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    return 'on ${_weekdayName(date.weekday)}';
  }

  static String _weekdayName(int weekday) => switch (weekday) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    DateTime.sunday => 'Sunday',
    _ => 'soon',
  };

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
