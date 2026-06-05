import 'dart:async';

import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/sound_settings.dart';
import 'package:alarm_walker/services/app_issue_log_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Keeps alarm audio alive when Android/plugin notification controls are
/// dismissed while the in-app AlarmGate is still active.
///
/// This is intentionally audio-only. The OS notification can be swiped away on
/// some devices, but the gate should continue making sound until the user
/// snoozes or completes the configured disarm flow.
class AlarmRingtoneRecoveryService {
  AlarmRingtoneRecoveryService._();

  static final AlarmRingtoneRecoveryService instance =
      AlarmRingtoneRecoveryService._();

  final AudioPlayer _player = AudioPlayer();
  int? _activeDbAlarmId;
  bool _isPlaying = false;
  Future<void>? _pendingStart;

  bool get isPlaying => _isPlaying;

  Future<void> startBackupRingtone({
    required AlarmModel alarmModel,
    required String reason,
  }) {
    final dbAlarmId = alarmModel.alarmId;

    if (_isPlaying && _activeDbAlarmId == dbAlarmId) {
      return Future<void>.value();
    }

    final pending = _pendingStart;
    if (pending != null) return pending;

    final future = _startBackupRingtone(alarmModel: alarmModel, reason: reason);
    _pendingStart = future;
    future.whenComplete(() => _pendingStart = null);
    return future;
  }

  Future<void> _startBackupRingtone({
    required AlarmModel alarmModel,
    required String reason,
  }) async {
    final soundSettings = alarmModel.soundSettings;
    final soundPath =
        soundSettings.soundPath ?? SoundSettings.defaultSoundPath;

    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);

      final volume = (soundSettings.overrideVolume
              ? soundSettings.volume.clamp(0.0, 1.0)
              : 1.0)
          .toDouble();
      await _player.setVolume(volume);

      if (soundPath.startsWith('assets/')) {
        await _player.play(AssetSource(soundPath.replaceFirst('assets/', '')));
      } else {
        await _player.play(DeviceFileSource(soundPath));
      }

      _activeDbAlarmId = alarmModel.alarmId;
      _isPlaying = true;
      debugPrint('🔊 Backup alarm ringtone started ($reason).');
    } catch (error, stackTrace) {
      _isPlaying = false;
      debugPrint('Error starting backup alarm ringtone: $error');
      unawaited(
        AppIssueLogService.recordError(
          error,
          stackTrace,
          source: 'alarm_ringtone_recovery',
          screen: 'AlarmRingtoneRecoveryService.startBackupRingtone',
          fatal: false,
        ),
      );
    }
  }

  Future<void> stopBackupRingtone() async {
    _activeDbAlarmId = null;
    _isPlaying = false;
    _pendingStart = null;

    try {
      await _player.stop();
    } catch (error, stackTrace) {
      debugPrint('Error stopping backup alarm ringtone: $error');
      unawaited(
        AppIssueLogService.recordError(
          error,
          stackTrace,
          source: 'alarm_ringtone_recovery',
          screen: 'AlarmRingtoneRecoveryService.stopBackupRingtone',
          fatal: false,
        ),
      );
    }
  }
}
