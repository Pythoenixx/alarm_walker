// lib/services/settings_cubit.dart

import 'dart:convert';

import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/app_language.dart';
import 'package:alarm_walker/models/dismiss_settings.dart';
import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/models/profile_category_presets.dart';
import 'package:alarm_walker/models/snooze_settings.dart';
import 'package:alarm_walker/models/sound_settings.dart';
import 'package:alarm_walker/services/shared_prefs_with_cache.dart';
import 'package:alarm_walker/services/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


TimeOfDay? _settingsLoadOptionalTime(int? hour, int? minute) {
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

Map<String, int> _settingsTimeToJson(TimeOfDay time) => {
  'hour': time.hour,
  'minute': time.minute,
};

TimeOfDay _settingsTimeFromJson(Object? value, TimeOfDay fallback) {
  if (value is! Map) return fallback;
  final hour = value['hour'];
  final minute = value['minute'];
  if (hour is! num || minute is! num) return fallback;
  final parsedHour = hour.toInt();
  final parsedMinute = minute.toInt();
  if (parsedHour < 0 || parsedHour > 23) return fallback;
  if (parsedMinute < 0 || parsedMinute > 59) return fallback;
  return TimeOfDay(hour: parsedHour, minute: parsedMinute);
}

TimeOfDay? _settingsOptionalTimeFromJson(Object? value) {
  if (value == null) return null;
  return _settingsTimeFromJson(value, const TimeOfDay(hour: 0, minute: 0));
}

// ── Keys ──────────────────────────────────────────────────────────────────────

abstract final class _K {
  static const themeMode = 'themeMode';
  static const use24HourFormat = 'use24HourFormat';
  static const appLanguage = 'appLanguage';
  static const defaultVolume = 'defaultVolume';
  static const defaultAudioPath = 'defaultAudioPath';
  static const defaultFadeIn = 'defaultFadeIn';
  static const defaultVibration = 'defaultVibration';
  static const defaultDisarmMode = 'defaultDisarmMode';
  static const defaultFlashlight = 'defaultFlashlight';
  // ADD THESE:
  static const defaultSoundSettings = 'defaultSoundSettings';
  static const defaultDismissSettings = 'defaultDismissSettings';
  static const defaultSnoozeSettings = 'defaultSnoozeSettings';
  static const weatherAwareEnabled = 'weatherAwareEnabled';
  static const weatherLocationName = WeatherService.manualLocationNameKey;
  static const weatherLatitude = WeatherService.manualLatitudeKey;
  static const weatherLongitude = WeatherService.manualLongitudeKey;
  static const adaptiveDifficultyEnabled = 'adaptiveDifficultyEnabled';
  static const bedtimeAlertEnabled = 'bedtimeAlertEnabled';
  static const bedtimeAlertHour = 'bedtimeAlertHour';
  static const bedtimeAlertMinute = 'bedtimeAlertMinute';
  static const weekendReminderEnabled = 'weekendReminderEnabled';
  static const vacationModeEnabled = 'vacationModeEnabled';
  static const stickyAlarmTimeEnabled = 'stickyAlarmTimeEnabled';
  static const lastStickyAlarmHour = 'lastStickyAlarmHour';
  static const lastStickyAlarmMinute = 'lastStickyAlarmMinute';
}

// ── State ─────────────────────────────────────────────────────────────────────

class SettingsState {
  // UI / system
  final ThemeMode themeMode;
  final bool use24HourFormat;
  final AppLanguage appLanguage;

  // Defaults written into every new AlarmModel
  final double defaultVolume;
  final String defaultAudioPath;
  final bool defaultFadeIn;
  final bool defaultVibration;
  final bool defaultFlashlight;
  final AlarmDisarmMode defaultAlarmDisarmMode;
  final SoundSettings defaultSoundSettings;
  final DismissSettings defaultDismissSettings;
  final SnoozeSettings defaultSnoozeSettings;
  final bool weatherAwareEnabled;
  final String? weatherLocationName;
  final double? weatherLatitude;
  final double? weatherLongitude;
  final bool adaptiveDifficultyEnabled;
  final bool bedtimeAlertEnabled;
  final TimeOfDay bedtimeAlertTime;
  final bool weekendReminderEnabled;
  final bool vacationModeEnabled;
  final bool stickyAlarmTimeEnabled;
  final TimeOfDay? lastStickyAlarmTime;

  const SettingsState({
    required this.themeMode,
    required this.use24HourFormat,
    required this.appLanguage,
    required this.defaultVolume,
    required this.defaultAudioPath,
    required this.defaultFadeIn,
    required this.defaultVibration,
    required this.defaultFlashlight,
    required this.defaultAlarmDisarmMode,
    required this.defaultSoundSettings,
    required this.defaultDismissSettings,
    required this.defaultSnoozeSettings,
    required this.weatherAwareEnabled,
    required this.weatherLocationName,
    required this.weatherLatitude,
    required this.weatherLongitude,
    required this.adaptiveDifficultyEnabled,
    required this.bedtimeAlertEnabled,
    required this.bedtimeAlertTime,
    required this.weekendReminderEnabled,
    required this.vacationModeEnabled,
    required this.stickyAlarmTimeEnabled,
    required this.lastStickyAlarmTime,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? use24HourFormat,
    AppLanguage? appLanguage,
    double? defaultVolume,
    String? defaultAudioPath,
    bool? defaultFadeIn,
    bool? defaultVibration,
    bool? defaultFlashlight,
    AlarmDisarmMode? defaultAlarmDisarmMode,
    SoundSettings? defaultSoundSettings,
    DismissSettings? defaultDismissSettings,
    SnoozeSettings? defaultSnoozeSettings,
    bool? weatherAwareEnabled,
    String? weatherLocationName,
    double? weatherLatitude,
    double? weatherLongitude,
    bool clearWeatherLocation = false,
    bool? adaptiveDifficultyEnabled,
    bool? bedtimeAlertEnabled,
    TimeOfDay? bedtimeAlertTime,
    bool? weekendReminderEnabled,
    bool? vacationModeEnabled,
    bool? stickyAlarmTimeEnabled,
    TimeOfDay? lastStickyAlarmTime,
    bool clearLastStickyAlarmTime = false,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    use24HourFormat: use24HourFormat ?? this.use24HourFormat,
    appLanguage: appLanguage ?? this.appLanguage,
    defaultVolume: defaultVolume ?? this.defaultVolume,
    defaultAudioPath: defaultAudioPath ?? this.defaultAudioPath,
    defaultFadeIn: defaultFadeIn ?? this.defaultFadeIn,
    defaultVibration: defaultVibration ?? this.defaultVibration,
    defaultFlashlight: defaultFlashlight ?? this.defaultFlashlight,
    defaultAlarmDisarmMode:
        defaultAlarmDisarmMode ?? this.defaultAlarmDisarmMode,
    defaultSoundSettings: defaultSoundSettings ?? this.defaultSoundSettings,
    defaultDismissSettings:
        defaultDismissSettings ?? this.defaultDismissSettings,
    defaultSnoozeSettings: defaultSnoozeSettings ?? this.defaultSnoozeSettings,
    weatherAwareEnabled: weatherAwareEnabled ?? this.weatherAwareEnabled,
    weatherLocationName:
        clearWeatherLocation
            ? null
            : weatherLocationName ?? this.weatherLocationName,
    weatherLatitude:
        clearWeatherLocation ? null : weatherLatitude ?? this.weatherLatitude,
    weatherLongitude:
        clearWeatherLocation ? null : weatherLongitude ?? this.weatherLongitude,
    adaptiveDifficultyEnabled:
        adaptiveDifficultyEnabled ?? this.adaptiveDifficultyEnabled,
    bedtimeAlertEnabled: bedtimeAlertEnabled ?? this.bedtimeAlertEnabled,
    bedtimeAlertTime: bedtimeAlertTime ?? this.bedtimeAlertTime,
    weekendReminderEnabled:
        weekendReminderEnabled ?? this.weekendReminderEnabled,
    vacationModeEnabled: vacationModeEnabled ?? this.vacationModeEnabled,
    stickyAlarmTimeEnabled:
        stickyAlarmTimeEnabled ?? this.stickyAlarmTimeEnabled,
    lastStickyAlarmTime:
        clearLastStickyAlarmTime
            ? null
            : lastStickyAlarmTime ?? this.lastStickyAlarmTime,
  );

  Map<String, dynamic> toBackupJson() => {
    'themeMode': themeMode.name,
    'use24HourFormat': use24HourFormat,
    'appLanguage': appLanguage.name,
    'defaultVolume': defaultVolume,
    'defaultAudioPath': defaultAudioPath,
    'defaultFadeIn': defaultFadeIn,
    'defaultVibration': defaultVibration,
    'defaultFlashlight': defaultFlashlight,
    'defaultAlarmDisarmMode': defaultAlarmDisarmMode.name,
    'defaultSoundSettings': defaultSoundSettings.toJson(),
    'defaultDismissSettings': defaultDismissSettings.toJson(),
    'defaultSnoozeSettings': defaultSnoozeSettings.toJson(),
    'weatherAwareEnabled': weatherAwareEnabled,
    'weatherLocationName': weatherLocationName,
    'weatherLatitude': weatherLatitude,
    'weatherLongitude': weatherLongitude,
    'adaptiveDifficultyEnabled': adaptiveDifficultyEnabled,
    'bedtimeAlertEnabled': bedtimeAlertEnabled,
    'bedtimeAlertTime': _settingsTimeToJson(bedtimeAlertTime),
    'weekendReminderEnabled': weekendReminderEnabled,
    'vacationModeEnabled': vacationModeEnabled,
    'stickyAlarmTimeEnabled': stickyAlarmTimeEnabled,
    'lastStickyAlarmTime':
        lastStickyAlarmTime == null ? null : _settingsTimeToJson(lastStickyAlarmTime!),
  };

  /// Build a ready-to-use AlarmModel seeded with these defaults.
  AlarmModel buildDefaultAlarmModel() => AlarmModel.fromSettings(this);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(_load());

  static SettingsState _load() {
    final p = SharedPreferencesWithCache.instance;
    return SettingsState(
      themeMode:
          ThemeMode.values[p.get<int>(_K.themeMode) ?? ThemeMode.system.index],
      use24HourFormat: (p.get<int>(_K.use24HourFormat) ?? 0) == 1,
      appLanguage: AppLanguage.fromName(p.get<String>(_K.appLanguage)),
      defaultVolume: p.get<double>(_K.defaultVolume) ?? 0.8,
      defaultAudioPath:
          p.get<String>(_K.defaultAudioPath) ?? SoundSettings.defaultSoundPath,
      defaultFadeIn: (p.get<int>(_K.defaultFadeIn) ?? 0) == 1,
      defaultVibration: (p.get<int>(_K.defaultVibration) ?? 1) == 1,
      defaultFlashlight: (p.get<int>(_K.defaultFlashlight) ?? 0) == 1,
      defaultAlarmDisarmMode: AlarmDisarmMode.values.firstWhere(
        (e) => e.name == p.get<String>(_K.defaultDisarmMode),
        orElse: () => AlarmDisarmMode.shake,
      ),
      defaultSoundSettings: SoundSettings.fromJson(
        jsonDecode(p.get<String>(_K.defaultSoundSettings) ?? '{}')
            as Map<String, dynamic>,
      ),
      defaultDismissSettings: DismissSettings.fromJson(
        jsonDecode(p.get<String>(_K.defaultDismissSettings) ?? '{}')
            as Map<String, dynamic>,
      ),
      defaultSnoozeSettings: SnoozeSettings.fromJson(
        jsonDecode(p.get<String>(_K.defaultSnoozeSettings) ?? '{}')
            as Map<String, dynamic>,
      ),
      weatherAwareEnabled: (p.get<int>(_K.weatherAwareEnabled) ?? 1) == 1,
      weatherLocationName: p.get<String>(_K.weatherLocationName),
      weatherLatitude: p.get<double>(_K.weatherLatitude),
      weatherLongitude: p.get<double>(_K.weatherLongitude),
      adaptiveDifficultyEnabled:
          (p.get<int>(_K.adaptiveDifficultyEnabled) ?? 1) == 1,
      bedtimeAlertEnabled: (p.get<int>(_K.bedtimeAlertEnabled) ?? 0) == 1,
      bedtimeAlertTime: TimeOfDay(
        hour: p.get<int>(_K.bedtimeAlertHour) ?? 22,
        minute: p.get<int>(_K.bedtimeAlertMinute) ?? 0,
      ),
      weekendReminderEnabled:
          (p.get<int>(_K.weekendReminderEnabled) ?? 0) == 1,
      vacationModeEnabled: (p.get<int>(_K.vacationModeEnabled) ?? 0) == 1,
      stickyAlarmTimeEnabled:
          (p.get<int>(_K.stickyAlarmTimeEnabled) ?? 0) == 1,
      lastStickyAlarmTime: _settingsLoadOptionalTime(
        p.get<int>(_K.lastStickyAlarmHour),
        p.get<int>(_K.lastStickyAlarmMinute),
      ),
    );
  }

  // ── setters ────────────────────────────────────────────────────────────────

  Future<void> setTheme(ThemeMode v) async {
    await SharedPreferencesWithCache.instance.setInt(_K.themeMode, v.index);
    emit(state.copyWith(themeMode: v));
  }

  Future<void> setLanguage(AppLanguage v) async {
    await SharedPreferencesWithCache.instance.setString(_K.appLanguage, v.name);
    emit(state.copyWith(appLanguage: v));
  }

  Future<void> setUse24HourFormat(bool v) async {
    await SharedPreferencesWithCache.instance.setInt(
      _K.use24HourFormat,
      v ? 1 : 0,
    );
    emit(state.copyWith(use24HourFormat: v));
  }

  Future<void> setDefaultVolume(double v) async {
    await SharedPreferencesWithCache.instance.setDouble(_K.defaultVolume, v);
    emit(state.copyWith(defaultVolume: v));
  }

  Future<void> setDefaultAudioPath(String v) async {
    await SharedPreferencesWithCache.instance.setString(_K.defaultAudioPath, v);
    emit(state.copyWith(defaultAudioPath: v));
  }

  Future<void> setDefaultFadeIn(bool v) async {
    await SharedPreferencesWithCache.instance.setInt(
      _K.defaultFadeIn,
      v ? 1 : 0,
    );
    emit(state.copyWith(defaultFadeIn: v));
  }

  Future<void> setDefaultVibration(bool v) async {
    await SharedPreferencesWithCache.instance.setInt(
      _K.defaultVibration,
      v ? 1 : 0,
    );
    emit(state.copyWith(defaultVibration: v));
  }

  Future<void> setDefaultFlashlight(bool v) async {
    await SharedPreferencesWithCache.instance.setInt(
      _K.defaultFlashlight,
      v ? 1 : 0,
    );
    emit(state.copyWith(defaultFlashlight: v));
  }

  Future<void> setDefaultAlarmDisarmMode(AlarmDisarmMode v) async {
    await SharedPreferencesWithCache.instance.setString(
      _K.defaultDisarmMode,
      v.name,
    );
    emit(state.copyWith(defaultAlarmDisarmMode: v));
  }

  Future<void> setDefaultSoundSettings(SoundSettings v) async {
    await SharedPreferencesWithCache.instance.setString(
      _K.defaultSoundSettings,
      jsonEncode(v.toJson()),
    );
    emit(state.copyWith(defaultSoundSettings: v));
  }

  Future<void> setDefaultDismissSettings(DismissSettings v) async {
    await SharedPreferencesWithCache.instance.setString(
      _K.defaultDismissSettings,
      jsonEncode(v.toJson()),
    );
    emit(state.copyWith(defaultDismissSettings: v));
  }

  Future<void> setDefaultSnoozeSettings(SnoozeSettings v) async {
    await SharedPreferencesWithCache.instance.setString(
      _K.defaultSnoozeSettings,
      jsonEncode(v.toJson()),
    );
    emit(state.copyWith(defaultSnoozeSettings: v));
  }


  Future<void> applyProfileCategoryDefaults(ProfileCategory category) async {
    final dismissSettings = ProfileCategoryPresets.dismissSettingsFor(category);
    final snoozeSettings = ProfileCategoryPresets.snoozeSettingsFor(category);

    await SharedPreferencesWithCache.instance.setString(
      _K.defaultDismissSettings,
      jsonEncode(dismissSettings.toJson()),
    );
    await SharedPreferencesWithCache.instance.setString(
      _K.defaultSnoozeSettings,
      jsonEncode(snoozeSettings.toJson()),
    );

    emit(
      state.copyWith(
        defaultDismissSettings: dismissSettings,
        defaultSnoozeSettings: snoozeSettings,
      ),
    );
  }


  Future<void> restoreFromBackupJson(Map<String, dynamic> json) async {
    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == json['themeMode'],
      orElse: () => ThemeMode.system,
    );
    final defaultAlarmDisarmMode = AlarmDisarmMode.values.firstWhere(
      (mode) => mode.name == json['defaultAlarmDisarmMode'],
      orElse: () => AlarmDisarmMode.shake,
    );

    final defaultSoundSettings = SoundSettings.fromJson(
      (json['defaultSoundSettings'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
    final defaultDismissSettings = DismissSettings.fromJson(
      (json['defaultDismissSettings'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
    final defaultSnoozeSettings = SnoozeSettings.fromJson(
      (json['defaultSnoozeSettings'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );

    final next = SettingsState(
      themeMode: themeMode,
      use24HourFormat: json['use24HourFormat'] as bool? ?? false,
      appLanguage: AppLanguage.fromName(json['appLanguage'] as String?),
      defaultVolume: (json['defaultVolume'] as num?)?.toDouble() ?? 0.8,
      defaultAudioPath:
          json['defaultAudioPath'] as String? ?? SoundSettings.defaultSoundPath,
      defaultFadeIn: json['defaultFadeIn'] as bool? ?? false,
      defaultVibration: json['defaultVibration'] as bool? ?? true,
      defaultFlashlight: json['defaultFlashlight'] as bool? ?? false,
      defaultAlarmDisarmMode: defaultAlarmDisarmMode,
      defaultSoundSettings: defaultSoundSettings,
      defaultDismissSettings: defaultDismissSettings,
      defaultSnoozeSettings: defaultSnoozeSettings,
      weatherAwareEnabled: json['weatherAwareEnabled'] as bool? ?? true,
      weatherLocationName: json['weatherLocationName'] as String?,
      weatherLatitude: (json['weatherLatitude'] as num?)?.toDouble(),
      weatherLongitude: (json['weatherLongitude'] as num?)?.toDouble(),
      adaptiveDifficultyEnabled:
          json['adaptiveDifficultyEnabled'] as bool? ?? true,
      bedtimeAlertEnabled: json['bedtimeAlertEnabled'] as bool? ?? false,
      bedtimeAlertTime: _settingsTimeFromJson(
        json['bedtimeAlertTime'],
        const TimeOfDay(hour: 22, minute: 0),
      ),
      weekendReminderEnabled: json['weekendReminderEnabled'] as bool? ?? false,
      vacationModeEnabled: json['vacationModeEnabled'] as bool? ?? false,
      stickyAlarmTimeEnabled: json['stickyAlarmTimeEnabled'] as bool? ?? false,
      lastStickyAlarmTime: _settingsOptionalTimeFromJson(json['lastStickyAlarmTime']),
    );

    await SharedPreferencesWithCache.instance.setInt(
      _K.themeMode,
      next.themeMode.index,
    );
    await SharedPreferencesWithCache.instance.setInt(
      _K.use24HourFormat,
      next.use24HourFormat ? 1 : 0,
    );
    await SharedPreferencesWithCache.instance.setString(
      _K.appLanguage,
      next.appLanguage.name,
    );
    await SharedPreferencesWithCache.instance.setDouble(
      _K.defaultVolume,
      next.defaultVolume,
    );
    await SharedPreferencesWithCache.instance.setString(
      _K.defaultAudioPath,
      next.defaultAudioPath,
    );
    await SharedPreferencesWithCache.instance.setInt(
      _K.defaultFadeIn,
      next.defaultFadeIn ? 1 : 0,
    );
    await SharedPreferencesWithCache.instance.setInt(
      _K.defaultVibration,
      next.defaultVibration ? 1 : 0,
    );
    await SharedPreferencesWithCache.instance.setInt(
      _K.defaultFlashlight,
      next.defaultFlashlight ? 1 : 0,
    );
    await SharedPreferencesWithCache.instance.setString(
      _K.defaultDisarmMode,
      next.defaultAlarmDisarmMode.name,
    );
    await SharedPreferencesWithCache.instance.setString(
      _K.defaultSoundSettings,
      jsonEncode(next.defaultSoundSettings.toJson()),
    );
    await SharedPreferencesWithCache.instance.setString(
      _K.defaultDismissSettings,
      jsonEncode(next.defaultDismissSettings.toJson()),
    );
    await SharedPreferencesWithCache.instance.setString(
      _K.defaultSnoozeSettings,
      jsonEncode(next.defaultSnoozeSettings.toJson()),
    );
    await SharedPreferencesWithCache.instance.setInt(
      _K.weatherAwareEnabled,
      next.weatherAwareEnabled ? 1 : 0,
    );
    if (next.weatherLocationName == null ||
        next.weatherLatitude == null ||
        next.weatherLongitude == null) {
      await SharedPreferencesWithCache.instance.remove(_K.weatherLocationName);
      await SharedPreferencesWithCache.instance.remove(_K.weatherLatitude);
      await SharedPreferencesWithCache.instance.remove(_K.weatherLongitude);
    } else {
      await SharedPreferencesWithCache.instance.setString(
        _K.weatherLocationName,
        next.weatherLocationName!,
      );
      await SharedPreferencesWithCache.instance.setDouble(
        _K.weatherLatitude,
        next.weatherLatitude!,
      );
      await SharedPreferencesWithCache.instance.setDouble(
        _K.weatherLongitude,
        next.weatherLongitude!,
      );
    }
    await SharedPreferencesWithCache.instance.setInt(
      _K.adaptiveDifficultyEnabled,
      next.adaptiveDifficultyEnabled ? 1 : 0,
    );
    await SharedPreferencesWithCache.instance.setInt(
      _K.bedtimeAlertEnabled,
      next.bedtimeAlertEnabled ? 1 : 0,
    );
    await SharedPreferencesWithCache.instance.setInt(
      _K.bedtimeAlertHour,
      next.bedtimeAlertTime.hour,
    );
    await SharedPreferencesWithCache.instance.setInt(
      _K.bedtimeAlertMinute,
      next.bedtimeAlertTime.minute,
    );
    await SharedPreferencesWithCache.instance.setInt(
      _K.weekendReminderEnabled,
      next.weekendReminderEnabled ? 1 : 0,
    );
    await SharedPreferencesWithCache.instance.setInt(
      _K.vacationModeEnabled,
      next.vacationModeEnabled ? 1 : 0,
    );
    await SharedPreferencesWithCache.instance.setInt(
      _K.stickyAlarmTimeEnabled,
      next.stickyAlarmTimeEnabled ? 1 : 0,
    );
    if (next.lastStickyAlarmTime == null) {
      await SharedPreferencesWithCache.instance.remove(_K.lastStickyAlarmHour);
      await SharedPreferencesWithCache.instance.remove(_K.lastStickyAlarmMinute);
    } else {
      await SharedPreferencesWithCache.instance.setInt(
        _K.lastStickyAlarmHour,
        next.lastStickyAlarmTime!.hour,
      );
      await SharedPreferencesWithCache.instance.setInt(
        _K.lastStickyAlarmMinute,
        next.lastStickyAlarmTime!.minute,
      );
    }

    emit(next);
  }

  Future<void> setAdaptiveDifficultyEnabled(bool v) async {
    await SharedPreferencesWithCache.instance.setInt(
      _K.adaptiveDifficultyEnabled,
      v ? 1 : 0,
    );
    emit(state.copyWith(adaptiveDifficultyEnabled: v));
  }

  Future<void> setWeatherAwareEnabled(bool v) async {
    await SharedPreferencesWithCache.instance.setInt(
      _K.weatherAwareEnabled,
      v ? 1 : 0,
    );
    emit(state.copyWith(weatherAwareEnabled: v));
  }

  Future<void> setWeatherLocation({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    await SharedPreferencesWithCache.instance.setString(
      _K.weatherLocationName,
      name,
    );
    await SharedPreferencesWithCache.instance.setDouble(
      _K.weatherLatitude,
      latitude,
    );
    await SharedPreferencesWithCache.instance.setDouble(
      _K.weatherLongitude,
      longitude,
    );
    emit(
      state.copyWith(
        weatherLocationName: name,
        weatherLatitude: latitude,
        weatherLongitude: longitude,
      ),
    );
  }

  Future<void> clearWeatherLocation() async {
    await SharedPreferencesWithCache.instance.remove(_K.weatherLocationName);
    await SharedPreferencesWithCache.instance.remove(_K.weatherLatitude);
    await SharedPreferencesWithCache.instance.remove(_K.weatherLongitude);
    emit(state.copyWith(clearWeatherLocation: true));
  }


  Future<void> setBedtimeAlertEnabled(bool v) async {
    await SharedPreferencesWithCache.instance.setInt(
      _K.bedtimeAlertEnabled,
      v ? 1 : 0,
    );
    emit(state.copyWith(bedtimeAlertEnabled: v));
  }

  Future<void> setBedtimeAlertTime(TimeOfDay v) async {
    await SharedPreferencesWithCache.instance.setInt(_K.bedtimeAlertHour, v.hour);
    await SharedPreferencesWithCache.instance.setInt(
      _K.bedtimeAlertMinute,
      v.minute,
    );
    emit(state.copyWith(bedtimeAlertTime: v));
  }

  Future<void> setWeekendReminderEnabled(bool v) async {
    await SharedPreferencesWithCache.instance.setInt(
      _K.weekendReminderEnabled,
      v ? 1 : 0,
    );
    emit(state.copyWith(weekendReminderEnabled: v));
  }

  Future<void> setVacationModeEnabled(bool v) async {
    await SharedPreferencesWithCache.instance.setInt(
      _K.vacationModeEnabled,
      v ? 1 : 0,
    );
    emit(state.copyWith(vacationModeEnabled: v));
  }

  Future<void> setStickyAlarmTimeEnabled(bool v) async {
    await SharedPreferencesWithCache.instance.setInt(
      _K.stickyAlarmTimeEnabled,
      v ? 1 : 0,
    );
    emit(state.copyWith(stickyAlarmTimeEnabled: v));
  }

  Future<void> setLastStickyAlarmTime(TimeOfDay? v) async {
    if (v == null) {
      await SharedPreferencesWithCache.instance.remove(_K.lastStickyAlarmHour);
      await SharedPreferencesWithCache.instance.remove(_K.lastStickyAlarmMinute);
      emit(state.copyWith(clearLastStickyAlarmTime: true));
      return;
    }

    await SharedPreferencesWithCache.instance.setInt(_K.lastStickyAlarmHour, v.hour);
    await SharedPreferencesWithCache.instance.setInt(
      _K.lastStickyAlarmMinute,
      v.minute,
    );
    emit(state.copyWith(lastStickyAlarmTime: v));
  }
}
