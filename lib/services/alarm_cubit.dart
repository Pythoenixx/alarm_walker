import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm_walker/models/alarm_db_entry.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/alarm_repository.dart';
import 'package:alarm_walker/models/user_profile_repository.dart';
import 'package:alarm_walker/models/wake_log_model.dart';
import 'package:alarm_walker/models/wake_log_repository.dart';
import 'package:alarm_walker/services/alarm_database.dart';
import 'package:alarm_walker/services/shared_prefs_with_cache.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AlarmCubit extends Cubit<List<AlarmModel>> {
  final UserProfileRepository userRepo;
  final AlarmRepository alarmRepo;
  final WakeLogRepository wakeLogRepo;

  late final Stopwatch _ringStopwatch;
  int _snoozeCount = 0;

  AlarmCubit({
    required this.alarmRepo,
    required this.wakeLogRepo,
    required this.userRepo,
  }) : super([]) {
    _ringStopwatch = Stopwatch();
    unawaited(_loadAlarms());
  }

  Future<void> _loadAlarms({List<AlarmSettings>? presetAlarms}) async {
    final models = await alarmRepo.getAlarms();
    final existingAlarms = presetAlarms ?? await Alarm.getAlarms();

    final Map<TimeOfDay, List<AlarmSettings>> alarmSettingsSet = {};

    for (final alarm in existingAlarms) {
      final alarmTime = TimeOfDay.fromDateTime(alarm.dateTime);
      alarmSettingsSet.putIfAbsent(alarmTime, () => []).add(alarm);
    }

    for (final model in models) {
      if (model.enabled) {
        await _ensureUpcomingWeek(
          //refactor cara dptkan attribute model
          model,
          title: model.title,
          model.time,
          model.days,
          alarmSettingsSet,
        );
      } else {
        alarmSettingsSet.putIfAbsent(model.time, () => []);
      }
    }

    final updatedModels =
        models.map((model) {
          // return AlarmModel(
          //   timeOfDay: model.timeOfDay,
          //   days: model.days,
          //   enabled: model.enabled,
          //   body: model.body,
          //   alarmSettings: alarmSettingsSet[model.timeOfDay] ?? [],
          // );
          return AlarmModel(
            alarmId: model.alarmId,
            title: model.title,
            time: model.time,
            days: model.days,
            disarmMode: model.disarmMode,
          );
        }).toList();

    emit(updatedModels);
  }

  Future<AlarmSettings?> _setAlarm(
    int id,
    DateTime scheduledDate, {
    required String title,
    required AlarmModel alarmModel,
  }) async {
    try {
      final vibrate =
          (SharedPreferencesWithCache.instance.get<int>('vibrationEnabled') ??
              1) ==
          1;
      final fadeIn =
          (SharedPreferencesWithCache.instance.get<int>('fadeInAlarm') ?? 0) ==
          1;
      final volume =
          SharedPreferencesWithCache.instance.get<double>('alarmVolume') ?? 1.0;
      final audioPath =
          SharedPreferencesWithCache.instance.get<String>('alarmAudioPath') ??
          'assets/alarm_ringtone.mp3';
      final volumeSettings =
          fadeIn
              ? VolumeSettings.fade(
                fadeDuration: const Duration(seconds: 60),
                volume: volume,
                volumeEnforced: true,
              )
              : VolumeSettings.fixed(volume: volume, volumeEnforced: true);
      final alarmSetting = AlarmSettings(
        id: id,
        dateTime: scheduledDate,
        assetAudioPath: audioPath,
        vibrate: vibrate,
        volumeSettings: volumeSettings,
        androidStopAlarmOnTermination: false,
        notificationSettings: NotificationSettings(
          title: 'Alarm',
          body: title,
          icon: 'notification_icon',
          iconColor: Colors.white,
        ),
        payload: alarmModel.alarmId.toString(),
      );
      final alarmSet = await Alarm.set(alarmSettings: alarmSetting);
      if (alarmSet) {
        return alarmSetting;
      }
    } catch (e) {
      debugPrint("Error setting alarm: $e");
    }
    return null;
  }

  //refactor later
  Future<void> _ensureUpcomingWeek(
    AlarmModel currentAlarmModel,
    TimeOfDay timeOfDay,
    List<int> days,
    Map<TimeOfDay, List<AlarmSettings>> current, {
    required String title,
  }) async {
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        timeOfDay.hour,
        timeOfDay.minute,
      ).add(Duration(days: i));

      if (!days.contains(dateTime.weekday)) continue;
      if (i == 0 &&
          (now.hour > timeOfDay.hour ||
              (now.hour == timeOfDay.hour && now.minute >= timeOfDay.minute))) {
        continue;
      }
      final exists =
          current[timeOfDay]?.any(
            (a) =>
                a.dateTime.year == dateTime.year &&
                a.dateTime.month == dateTime.month &&
                a.dateTime.day == dateTime.day,
          ) ??
          false;
      if (!exists) {
        final newAlarm = await _setAlarm(
          dateTime.millisecondsSinceEpoch.hashCode,
          dateTime,
          title: title,
          alarmModel: currentAlarmModel,
        );
        if (newAlarm != null) {
          current.putIfAbsent(timeOfDay, () => []).add(newAlarm);
        }
      }
    }
  }

  Future<void> snoozeAlarm({
    required AlarmSettings alarmSettings,
    int snoozeMinutes = 5,
  }) async {
    await Alarm.set(
      alarmSettings: alarmSettings.copyWith(
        dateTime: DateTime.now().add(Duration(minutes: snoozeMinutes)),
      ),
    );
  }

  Future<void> setPeriodicAlarms({
    int? alarmId,
    required TimeOfDay timeOfDay,
    List<int> days = const [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    ],
    String title = '',
  }) async {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    final uid = firebaseUid ?? 'local';
    // firebaseUid != null && await userRepo.exists(firebaseUid)
    //     ? firebaseUid
    //     : 'local';

    // Handle potential null ID safely
    final existingAlarm =
        (alarmId != null) ? await alarmRepo.getAlarmById(alarmId) : null;

    final updatedDays = days.toSet().toList();
    final enabled = existingAlarm?.enabled ?? true;

    final updatedAlarm = AlarmModel(
      alarmId: existingAlarm?.alarmId, // 🔥 null for new
      title: title,
      time: timeOfDay,
      days: updatedDays,
      enabled: enabled,
      sound: existingAlarm?.sound ?? 'default',
      volume: existingAlarm?.volume ?? 5,
      vibration: existingAlarm?.vibration ?? true,
      fadeIn: existingAlarm?.fadeIn ?? true,
      disarmMode: existingAlarm?.disarmMode ?? 'math',
    );

    final modelId = await alarmRepo.saveOrUpdate(updatedAlarm, uid);

    final modelWithId = AlarmModel(
      alarmId: modelId,
      title: updatedAlarm.title,
      time: updatedAlarm.time,
      days: updatedAlarm.days,
      disarmMode: updatedAlarm.disarmMode,
    );

    if (enabled) {
      final existing = await Alarm.getAlarms();
      final Map<TimeOfDay, List<AlarmSettings>> current = {};

      for (final alarm in existing) {
        final alarmTime = TimeOfDay.fromDateTime(alarm.dateTime);
        current.putIfAbsent(alarmTime, () => []).add(alarm);
      }

      await _ensureUpcomingWeek(
        modelWithId,
        timeOfDay,
        updatedDays,
        current,
        title: title,
      );

      await _loadAlarms(presetAlarms: current.values.expand((e) => e).toList());
    } else {
      await _loadAlarms();
    }
  }

  Future<void> completeAlarm({
    required int alarmId,
    required AlarmResult result,
    required AlarmDisarmMode disarmMode,
  }) async {
    final durationMs = _ringStopwatch.elapsedMilliseconds;
    final model = await alarmRepo.getAlarmById(alarmId);
    final modelTime = model?.time;
    final int durationInMilliseconds =
        (modelTime != null)
            ? DateTime.now().difference(toDateTime(modelTime)).inMilliseconds
            : durationMs;
    await wakeLogRepo.insertWakeLog(
      WakeLog(
        alarmId: alarmId,
        wakeTime: DateTime.now(),
        snoozeCount: _snoozeCount,
        success: result == AlarmResult.success,
        disarmMode: disarmMode,
        disarmDurationMs: durationInMilliseconds,
      ),
    );

    _ringStopwatch.reset();
    _snoozeCount = 0;
  }

  Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
    // await Alarm.stopAll(); //debug
  }

  DateTime toDateTime(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  Future<void> deleteAlarmModel(AlarmModel alarmModel) async {
    final alarmId = alarmModel.alarmId;
    if (alarmId == null) return; // safety guard

    // 1. Stop runtime alarms
    final runtimeAlarms = await Alarm.getAlarms();

    for (final alarm in runtimeAlarms) {
      final alarmTime = TimeOfDay.fromDateTime(alarm.dateTime);
      if (alarmTime == alarmModel.time) {
        await stopAlarm(alarm.id);
      }
    }

    // 2. Delete from DB
    await alarmRepo.deleteAlarm(alarmId);

    // 3. Update state
    emit(state.where((e) => e.alarmId != alarmId).toList());
  }

  Future<void> toggleAlarmEnabled(AlarmModel alarmModel, bool enabled) async {
    final alarmId = alarmModel.alarmId;
    if (alarmId == null) return;

    // 1. Update DB
    await alarmRepo.updateAlarmEnabled(alarmId, enabled);

    // 2. Runtime alarms
    if (!enabled) {
      final runtimeAlarms = await Alarm.getAlarms();

      for (final alarm in runtimeAlarms) {
        // improve this later alarm_cubit.dart line 332 atau sume yg guna TimeOfDay.fromDateTime(alarm.dateTime)
        // maybe better dpt store and match guna id lebih better drpd check sama ada time sama tak dgn alarm model?
        final alarmTime = TimeOfDay.fromDateTime(alarm.dateTime);
        if (alarmTime == alarmModel.time) {
          await stopAlarm(alarm.id);
        }
      }
    } else {
      await _ensureUpcomingWeek(
        alarmModel,
        alarmModel.time,
        alarmModel.days,
        {},
        title: alarmModel.title,
      );
    }

    // 3. Reload state
    emit(await alarmRepo.getAlarms());
  }

  Future<void> updateAlarmDays(AlarmModel alarmModel, List<int> days) async {
    final bool enabled = days.isNotEmpty && alarmModel.enabled;

    final alarmId = alarmModel.alarmId;
    if (alarmId == null) return;

    // 1. Persist changes
    await alarmRepo.updateAlarmDays(alarmId, days, enabled);

    // 2. Cancel existing runtime alarms for this alarm
    final runtimeAlarms = await Alarm.getAlarms();
    final Map<TimeOfDay, List<AlarmSettings>> remaining = {};

    for (final alarm in runtimeAlarms) {
      final alarmTime = TimeOfDay.fromDateTime(alarm.dateTime);

      if (alarmTime == alarmModel.time) {
        await stopAlarm(alarm.id);
      } else {
        remaining.putIfAbsent(alarmTime, () => []).add(alarm);
      }
    }

    // 3. Re-schedule if still enabled
    if (enabled) {
      await _ensureUpcomingWeek(
        alarmModel,
        alarmModel.time,
        days,
        remaining,
        title: alarmModel.title,
      );
    }

    // 4. Reload state
    final updated = await alarmRepo.getAlarms();
    emit(updated);
  }

  Future<void> updateVibrationForAll(bool vibrate) async {
    final alarms = await Alarm.getAlarms();
    for (final alarm in alarms) {
      await Alarm.set(alarmSettings: alarm.copyWith(vibrate: vibrate));
    }
    await _loadAlarms();
  }

  Future<void> updateVolumeSettingsForAll({
    required bool fadeIn,
    required double volume,
  }) async {
    final alarms = await Alarm.getAlarms();
    final volumeSettings =
        fadeIn
            ? VolumeSettings.fade(
              fadeDuration: const Duration(seconds: 5),
              volume: volume,
            )
            : VolumeSettings.fixed(volume: volume);
    for (final alarm in alarms) {
      await Alarm.set(
        alarmSettings: alarm.copyWith(volumeSettings: volumeSettings),
      );
    }
    await _loadAlarms();
  }

  Future<void> updateAudioPathForAll(String audioPath) async {
    final alarms = await Alarm.getAlarms();
    for (final alarm in alarms) {
      await Alarm.set(alarmSettings: alarm.copyWith(assetAudioPath: audioPath));
    }
    await _loadAlarms();
  }
}
