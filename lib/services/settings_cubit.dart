// lib/services/settings_cubit.dart

import 'dart:convert';

import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/dismiss_settings.dart';
import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/models/profile_category_presets.dart';
import 'package:alarm_walker/models/snooze_settings.dart';
import 'package:alarm_walker/models/sound_settings.dart';
import 'package:alarm_walker/services/shared_prefs_with_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Keys ──────────────────────────────────────────────────────────────────────

abstract final class _K {
  static const themeMode = 'themeMode';
  static const use24HourFormat = 'use24HourFormat';
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
}

// ── State ─────────────────────────────────────────────────────────────────────

class SettingsState {
  // UI / system
  final ThemeMode themeMode;
  final bool use24HourFormat;

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

  const SettingsState({
    required this.themeMode,
    required this.use24HourFormat,
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
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? use24HourFormat,
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
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    use24HourFormat: use24HourFormat ?? this.use24HourFormat,
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
  );

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
      defaultVolume: p.get<double>(_K.defaultVolume) ?? 0.8,
      defaultAudioPath:
          p.get<String>(_K.defaultAudioPath) ?? SoundSettings.defaultSoundPath,
      defaultFadeIn: (p.get<int>(_K.defaultFadeIn) ?? 0) == 1,
      defaultVibration: (p.get<int>(_K.defaultVibration) ?? 1) == 1,
      defaultFlashlight: (p.get<int>(_K.defaultFlashlight) ?? 0) == 1,
      defaultAlarmDisarmMode: AlarmDisarmMode.values.firstWhere(
        (e) => e.name == p.get<String>(_K.defaultDisarmMode),
        orElse: () => AlarmDisarmMode.normal,
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
    );
  }

  // ── setters ────────────────────────────────────────────────────────────────

  Future<void> setTheme(ThemeMode v) async {
    await SharedPreferencesWithCache.instance.setInt(_K.themeMode, v.index);
    emit(state.copyWith(themeMode: v));
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

  Future<void> setWeatherAwareEnabled(bool v) async {
    await SharedPreferencesWithCache.instance.setInt(
      _K.weatherAwareEnabled,
      v ? 1 : 0,
    );
    emit(state.copyWith(weatherAwareEnabled: v));
  }
}
