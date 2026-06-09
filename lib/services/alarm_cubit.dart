import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/alarm_repository.dart';
import 'package:alarm_walker/models/dismiss_settings.dart';
import 'package:alarm_walker/models/snooze_settings.dart';
import 'package:alarm_walker/models/sound_settings.dart';
import 'package:alarm_walker/models/user_profile_repository.dart';
import 'package:alarm_walker/models/wake_log_repository.dart';
import 'package:alarm_walker/services/shared_prefs_with_cache.dart';
import 'package:alarm_walker/services/app_issue_log_service.dart';
import 'package:alarm_walker/services/user_usage_stats_sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActiveAlarmRef {
  final int dbAlarmId;
  final int runtimeAlarmId;

  const ActiveAlarmRef({required this.dbAlarmId, required this.runtimeAlarmId});

  factory ActiveAlarmRef.from({
    required AlarmSettings alarmSettings,
    required AlarmModel alarmModel,
  }) {
    final dbIdFromModel = alarmModel.alarmId;
    final dbIdFromPayload = int.tryParse(alarmSettings.payload ?? '');

    if (dbIdFromModel == null) {
      throw StateError('AlarmModel.alarmId is null.');
    }

    if (dbIdFromPayload != null && dbIdFromPayload != dbIdFromModel) {
      throw StateError(
        'Alarm ID mismatch. Payload DB ID: $dbIdFromPayload, Model DB ID: $dbIdFromModel',
      );
    }

    return ActiveAlarmRef(
      dbAlarmId: dbIdFromModel,
      runtimeAlarmId: alarmSettings.id,
    );
  }
}

class AlarmCubit extends Cubit<List<AlarmModel>> {
  final UserProfileRepository userRepo;
  final AlarmRepository alarmRepo;
  final WakeLogRepository wakeLogRepo;
  final UserUsageStatsSyncService _usageStatsSyncService =
      UserUsageStatsSyncService();
  late final Stopwatch _ringStopwatch;

  static String _logIdKey(int alarmId) => 'wake_log_id_$alarmId';
  static String _snoozeCountKey(int alarmId) => 'snooze_count_$alarmId';
  static const String _vacationModeEnabledKey = 'vacationModeEnabled';

  bool get _vacationModeEnabled =>
      (SharedPreferencesWithCache.instance.get<int>(
            _vacationModeEnabledKey,
          ) ??
          0) ==
      1;

  String get currentOwnerId => FirebaseAuth.instance.currentUser?.uid ?? 'local';

  AlarmCubit({
    required this.alarmRepo,
    required this.wakeLogRepo,
    required this.userRepo,
  }) : super([]) {
    _ringStopwatch = Stopwatch();
    unawaited(_loadAlarms());
  }

  Future<void> reloadForCurrentOwner() => _loadAlarms();

  void _syncUsageStatsForAdmin() {
    unawaited(
      _usageStatsSyncService.syncCurrentUser(
        alarmRepo: alarmRepo,
        wakeLogRepo: wakeLogRepo,
        ownerId: currentOwnerId,
      ),
    );
  }

  Future<AlarmModel?> getAlarmForCurrentOwner(int alarmId) {
    return alarmRepo.getAlarmById(alarmId, userId: currentOwnerId);
  }

  Future<void> _loadAlarms({List<AlarmSettings>? presetAlarms}) async {
    final ownerId = currentOwnerId;
    final models = await alarmRepo.getAlarms(userId: ownerId);
    final modelIds = models.map((model) => model.alarmId).whereType<int>().toSet();
    final existingAlarms = presetAlarms ?? await Alarm.getAlarms();

    if (_vacationModeEnabled) {
      for (final alarm in existingAlarms) {
        final dbAlarmId = int.tryParse(alarm.payload ?? '');
        if (dbAlarmId != null && modelIds.contains(dbAlarmId)) {
          await stopRuntimeAlarm(alarm.id);
        }
      }
      emit(models);
      _syncUsageStatsForAdmin();
      return;
    }

    final Map<TimeOfDay, List<AlarmSettings>> alarmSettingsSet = {};

    for (final alarm in existingAlarms) {
      final dbAlarmId = int.tryParse(alarm.payload ?? '');

      // Runtime alarms belong to the Android alarm package. If another local
      // user/account owns the DB row, stop it so it does not ring for the
      // current user.
      if (dbAlarmId == null || !modelIds.contains(dbAlarmId)) {
        await stopRuntimeAlarm(alarm.id);
        continue;
      }

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

    emit(models);
    _syncUsageStatsForAdmin();
  }

  Future<AlarmSettings?> _setAlarm(
    int id,
    DateTime scheduledDate, {
    required String title,
    required AlarmModel alarmModel,
  }) async {
    try {
      final sound = alarmModel.soundSettings;

      final volumeSettings =
          sound.overrideVolume
              ? (sound.gradualVolumeIncrease
                  ? VolumeSettings.fade(
                    fadeDuration: Duration(
                      seconds: sound.gradualIncreaseDurationSeconds,
                    ),
                    volume: sound.volume,
                    volumeEnforced: !sound.allowMidAlarmVolumeChange,
                  )
                  : VolumeSettings.fixed(
                    volume: sound.volume,
                    volumeEnforced: !sound.allowMidAlarmVolumeChange,
                  ))
              : const VolumeSettings.fixed();

      final alarmSetting = AlarmSettings(
        id: id,
        dateTime: scheduledDate,
        assetAudioPath: sound.soundPath ?? 'assets/alarm_ringtone.mp3',
        vibrate: sound.vibrate,
        volumeSettings: volumeSettings,
        androidStopAlarmOnTermination: false,
        notificationSettings: NotificationSettings(
          title: 'Alarm',
          body: title,
          icon: 'ic_stat_alarm_walker_noti_icon',
          iconColor: Colors.white,
        ),
        payload: alarmModel.alarmId.toString(),
      );

      final alarmSet = await Alarm.set(alarmSettings: alarmSetting);
      if (alarmSet) return alarmSetting;
    } catch (error, stackTrace) {
      debugPrint('Error setting alarm: $error');
      unawaited(
        AppIssueLogService.recordError(
          error,
          stackTrace,
          source: 'alarm_scheduler',
          screen: 'AlarmCubit._setAlarm',
          fatal: false,
        ),
      );
    }
    return null;
  }

  DateTime _nextOneTimeDate(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  bool _runtimeAlarmMatchesModelOnDate(
    AlarmSettings alarm,
    AlarmModel model,
    DateTime dateTime,
  ) {
    return _runtimeAlarmBelongsToModel(alarm, model) &&
        alarm.dateTime.year == dateTime.year &&
        alarm.dateTime.month == dateTime.month &&
        alarm.dateTime.day == dateTime.day &&
        alarm.dateTime.hour == dateTime.hour &&
        alarm.dateTime.minute == dateTime.minute;
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

    if (currentAlarmModel.isOnce) {
      final dateTime = _nextOneTimeDate(timeOfDay);
      final runtimeAlarms = current.values.expand((alarms) => alarms);
      final exists = runtimeAlarms.any(
        (alarm) => _runtimeAlarmMatchesModelOnDate(
          alarm,
          currentAlarmModel,
          dateTime,
        ),
      );

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
      return;
    }

    for (var i = 0; i < 7; i++) {
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        timeOfDay.hour,
        timeOfDay.minute,
      ).add(Duration(days: i));
      // if next day isnt toggled in the alarm then continue
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

  Future<void> setPeriodicAlarms({
    int? alarmId,
    required TimeOfDay timeOfDay,
    List<int> days = const [
      DateTime.sunday,
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
    ],
    String title = '',
    required SnoozeSettings snoozeSettings,
    required SoundSettings soundSettings,
    required DismissSettings dismissSettings,
    required bool wakeupCheck,
    required bool isOnce,
  }) async {
    final uid = currentOwnerId;

    // Handle potential null ID safely. Existing alarms are scoped to the
    // current local/Firebase user so another account cannot edit them.
    final existingAlarm =
        (alarmId != null)
            ? await alarmRepo.getAlarmById(alarmId, userId: uid)
            : null;

    final updatedDays = isOnce ? <int>[] : days.toSet().toList();
    // A saved one-time alarm should be ready to ring again after edits.
    // Repeat alarms keep their previous enabled/disabled state.
    final enabled = isOnce ? true : (existingAlarm?.enabled ?? true);

    if (existingAlarm != null) {
      final runtimeAlarms = await Alarm.getAlarms();
      for (final alarm in runtimeAlarms) {
        if (_runtimeAlarmBelongsToModel(alarm, existingAlarm)) {
          await stopRuntimeAlarm(alarm.id);
        }
      }
    }

    final updatedAlarm = AlarmModel(
      alarmId: existingAlarm?.alarmId, // 🔥 null for new
      title: title,
      time: timeOfDay,
      days: updatedDays,
      enabled: enabled,
      snoozeSettings: snoozeSettings,
      soundSettings: soundSettings,
      dismissSettings: dismissSettings,
      wakeupCheck: wakeupCheck,
      isOnce: isOnce,
    );

    final modelId = await alarmRepo.saveOrUpdate(updatedAlarm, uid);

    final modelWithId = updatedAlarm.copyWith(alarmId: modelId);

    if (enabled && !_vacationModeEnabled) {
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

  /// Called from _ringingAlarmsChanged, before pushing AlarmGateScreen.
  Future<int> startWakeSession({
    required ActiveAlarmRef alarmRef,
    required AlarmDisarmMode disarmMode,
  }) async {
    final dbAlarmId = alarmRef.dbAlarmId;

    _ringStopwatch
      ..reset()
      ..start();

    final existingLogId = SharedPreferencesWithCache.instance.get<int>(
      _logIdKey(dbAlarmId),
    );

    if (existingLogId != null) return existingLogId;

    final logId = await wakeLogRepo.startLog(
      alarmId: dbAlarmId,
      disarmMode: disarmMode,
    );

    await SharedPreferencesWithCache.instance.setInt(
      _logIdKey(dbAlarmId),
      logId,
    );

    await SharedPreferencesWithCache.instance.setInt(
      _snoozeCountKey(dbAlarmId),
      0,
    );

    return logId;
  }

  Future<void> snoozeAlarm({
    required AlarmSettings alarmSettings,
    required ActiveAlarmRef alarmRef,
    int snoozeMinutes = 5,
  }) async {
    final dbAlarmId = alarmRef.dbAlarmId;

    final logId = SharedPreferencesWithCache.instance.get<int>(
      _logIdKey(dbAlarmId),
    );

    if (logId != null) {
      await wakeLogRepo.incrementSnooze(logId);
    }

    final current =
        SharedPreferencesWithCache.instance.get<int>(
          _snoozeCountKey(dbAlarmId),
        ) ??
        0;

    await SharedPreferencesWithCache.instance.setInt(
      _snoozeCountKey(dbAlarmId),
      current + 1,
    );

    await Alarm.set(
      alarmSettings: alarmSettings.copyWith(
        dateTime: DateTime.now().add(Duration(minutes: snoozeMinutes)),
      ),
    );
  }

  Future<void> cancelSnooze({required ActiveAlarmRef alarmRef}) async {
    final dbAlarmId = alarmRef.dbAlarmId;
    final runtimeAlarmId = alarmRef.runtimeAlarmId;

    await Alarm.stop(runtimeAlarmId);

    final current =
        SharedPreferencesWithCache.instance.get<int>(
          _snoozeCountKey(dbAlarmId),
        ) ??
        0;

    if (current <= 0) return;

    await SharedPreferencesWithCache.instance.setInt(
      _snoozeCountKey(dbAlarmId),
      current - 1,
    );

    final logId = SharedPreferencesWithCache.instance.get<int>(
      _logIdKey(dbAlarmId),
    );

    if (logId != null) {
      await wakeLogRepo.decrementSnooze(logId);
    }
  }

  Future<void> wakeSnoozedAlarmNow({
    required AlarmSettings alarmSettings,
    required ActiveAlarmRef alarmRef,
  }) async {
    // End the waiting period early or reactivate after the snooze countdown.
    // Re-use the original AlarmSettings so the user's selected sound, volume,
    // vibration, and notification settings are preserved. AlarmGateRouteGuard
    // prevents the Home listener from stacking another AlarmGate route.
    await Alarm.set(
      alarmSettings: alarmSettings.copyWith(
        dateTime: DateTime.now().add(const Duration(seconds: 1)),
      ),
    );
  }

  Future<void> restoreActiveAlarmSound({
    required AlarmSettings alarmSettings,
  }) async {
    try {
      await Alarm.set(
        alarmSettings: alarmSettings.copyWith(
          dateTime: DateTime.now().add(const Duration(seconds: 1)),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Error restoring active alarm sound: $error');
      unawaited(
        AppIssueLogService.recordError(
          error,
          stackTrace,
          source: 'alarm_runtime_watchdog',
          screen: 'AlarmCubit.restoreActiveAlarmSound',
          fatal: false,
        ),
      );
    }
  }

  Future<void> recordFailedDisarmAttempt({
    required ActiveAlarmRef alarmRef,
  }) async {
    final dbAlarmId = alarmRef.dbAlarmId;
    final logId = SharedPreferencesWithCache.instance.get<int>(
      _logIdKey(dbAlarmId),
    );

    if (logId == null) return;

    await wakeLogRepo.incrementFailedAttempt(logId);
    _syncUsageStatsForAdmin();
  }

  Future<void> finishRingingAlarm({
    required ActiveAlarmRef alarmRef,
    required AlarmResult result,
  }) async {
    final dbAlarmId = alarmRef.dbAlarmId;
    final runtimeAlarmId = alarmRef.runtimeAlarmId;

    await Alarm.stop(runtimeAlarmId);

    final durationMs = _ringStopwatch.elapsedMilliseconds;

    _ringStopwatch
      ..stop()
      ..reset();

    final logId = SharedPreferencesWithCache.instance.get<int>(
      _logIdKey(dbAlarmId),
    );

    if (logId != null) {
      await wakeLogRepo.completeLog(
        logId: logId,
        success: result == AlarmResult.success,
        disarmDurationMs: durationMs,
      );
    }

    if (result == AlarmResult.success) {
      final completedAlarm = await alarmRepo.getAlarmById(
        dbAlarmId,
        userId: currentOwnerId,
      );
      if (completedAlarm?.isOnce == true && completedAlarm!.enabled) {
        await alarmRepo.updateAlarmEnabled(
          dbAlarmId,
          false,
          userId: currentOwnerId,
        );
        final updated = await alarmRepo.getAlarms(userId: currentOwnerId);
        emit(updated);
      }
    }

    _syncUsageStatsForAdmin();

    await SharedPreferencesWithCache.instance.remove(_logIdKey(dbAlarmId));
    await SharedPreferencesWithCache.instance.remove(
      _snoozeCountKey(dbAlarmId),
    );
  }

  Future<void> stopRuntimeAlarm(int id) async {
    await Alarm.stop(id);
    // await Alarm.stopAll(); //debug
  }

  bool _runtimeAlarmBelongsToModel(
    AlarmSettings alarm,
    AlarmModel alarmModel,
  ) {
    final dbAlarmId = alarmModel.alarmId;
    if (dbAlarmId == null) return false;

    return int.tryParse(alarm.payload ?? '') == dbAlarmId;
  }

  DateTime toDateTime(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  Future<void> deleteAlarmModel(AlarmModel alarmModel) async {
    final alarmId = alarmModel.alarmId;
    if (alarmId == null) return;

    // 1. Stop runtime alarms
    final runtimeAlarms = await Alarm.getAlarms();

    for (final alarm in runtimeAlarms) {
      if (_runtimeAlarmBelongsToModel(alarm, alarmModel)) {
        await stopRuntimeAlarm(alarm.id);
      }
    }

    // 2. Delete from DB
    await alarmRepo.deleteAlarm(alarmId, userId: currentOwnerId);

    // 3. Update state
    emit(state.where((e) => e.alarmId != alarmId).toList());
    _syncUsageStatsForAdmin();
  }

  Future<void> toggleAlarmEnabled(AlarmModel alarmModel, bool enabled) async {
    final alarmId = alarmModel.alarmId;
    if (alarmId == null) return;

    // 1. Update DB
    await alarmRepo.updateAlarmEnabled(
      alarmId,
      enabled,
      userId: currentOwnerId,
    );

    // 2. Runtime alarms
    if (!enabled) {
      final runtimeAlarms = await Alarm.getAlarms();

      for (final alarm in runtimeAlarms) {
        if (_runtimeAlarmBelongsToModel(alarm, alarmModel)) {
          await stopRuntimeAlarm(alarm.id);
        }
      }
    } else if (!_vacationModeEnabled) {
      await _ensureUpcomingWeek(
        alarmModel,
        alarmModel.time,
        alarmModel.days,
        {},
        title: alarmModel.title,
      );
    }

    // 3. Reload state
    emit(await alarmRepo.getAlarms(userId: currentOwnerId));
    _syncUsageStatsForAdmin();
  }

  Future<void> updateAlarmDays(AlarmModel alarmModel, List<int> days) async {
    final bool enabled = days.isNotEmpty && alarmModel.enabled;

    final alarmId = alarmModel.alarmId;
    if (alarmId == null) return;

    // 1. Persist changes
    await alarmRepo.updateAlarmDays(
      alarmId,
      days,
      enabled,
      userId: currentOwnerId,
    );

    // 2. Cancel existing runtime alarms for this alarm
    final runtimeAlarms = await Alarm.getAlarms();
    final Map<TimeOfDay, List<AlarmSettings>> remaining = {};

    for (final alarm in runtimeAlarms) {
      final alarmTime = TimeOfDay.fromDateTime(alarm.dateTime);

      if (_runtimeAlarmBelongsToModel(alarm, alarmModel)) {
        await stopRuntimeAlarm(alarm.id);
      } else {
        remaining.putIfAbsent(alarmTime, () => []).add(alarm);
      }
    }

    // 3. Re-schedule if still enabled
    if (enabled && !_vacationModeEnabled) {
      await _ensureUpcomingWeek(
        alarmModel,
        alarmModel.time,
        days,
        remaining,
        title: alarmModel.title,
      );
    }

    // 4. Reload state
    final updated = await alarmRepo.getAlarms(userId: currentOwnerId);
    emit(updated);
    _syncUsageStatsForAdmin();
  }

  Future<void> updateAudioPathForAll(String audioPath) async {
    final ownerAlarms = await alarmRepo.getAlarms(userId: currentOwnerId);
    final ownerAlarmIds =
        ownerAlarms.map((alarm) => alarm.alarmId).whereType<int>().toSet();

    final alarms = await Alarm.getAlarms();
    for (final alarm in alarms) {
      final dbAlarmId = int.tryParse(alarm.payload ?? '');
      if (dbAlarmId == null || !ownerAlarmIds.contains(dbAlarmId)) continue;

      await Alarm.set(alarmSettings: alarm.copyWith(assetAudioPath: audioPath));
    }
    await _loadAlarms();
  }
}
