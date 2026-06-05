import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/model/alarm_settings.dart';
import 'package:alarm_walker/app_router.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/services/alarm_cubit.dart';
import 'package:alarm_walker/services/alarm_dismiss_helper.dart';
import 'package:alarm_walker/services/alarm_gate_route_guard.dart';
import 'package:alarm_walker/services/alarm_ringtone_recovery_service.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:alarm_walker/services/shared_prefs_with_cache.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/weather_alarm_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AlarmGateScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;
  final AlarmModel alarmModel;

  const AlarmGateScreen({
    super.key,
    required this.alarmSettings,
    required this.alarmModel,
  });

  @override
  State<AlarmGateScreen> createState() => _AlarmGateScreenState();
}

class _AlarmGateScreenState extends State<AlarmGateScreen>
    with TickerProviderStateMixin {
  // ── snooze state ───────────────────────────────────────────────────────────
  bool _snoozed = false;
  int _snoozeCount = 0;
  late int _snoozeDuration; // minutes, adjusted by drag
  Timer? _countdownTimer;
  Timer? _alarmWatchdogTimer;
  Duration _remaining = Duration.zero;
  bool _isStartingBackupRingtone = false;
  bool _isFinishingSnooze = false;

  ActiveAlarmRef get _alarmRef => ActiveAlarmRef.from(
    alarmSettings: widget.alarmSettings,
    alarmModel: widget.alarmModel,
  );

  // ── animations ─────────────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final AnimationController _snoozeConfirmCtrl;
  late final Animation<double> _snoozeConfirmAnim;

  // ── drag state ─────────────────────────────────────────────────────────────
  // Accumulated vertical drag delta used to step duration up/down
  double _dragAccum = 0;
  static const double _dragPerStep = 8.0; // px per 1-minute step
  static const int _minSnooze = 1;
  static const int _maxSnooze = 60;

  bool _isProcessingDismiss = false;

  AlarmModel get _m => widget.alarmModel;
  bool get _canSnooze =>
      _m.snoozeSettings.enabled &&
      (_m.snoozeSettings.maxCount == 0 ||
          _snoozeCount < _m.snoozeSettings.maxCount);
  int get _maxCount => _m.snoozeSettings.maxCount;

  @override
  void initState() {
    super.initState();
    final dbAlarmId = _m.alarmId;
    if (dbAlarmId != null) {
      AlarmGateRouteGuard.markActive(
        dbAlarmId: dbAlarmId,
        runtimeAlarmId: widget.alarmSettings.id,
      );
    }
    _snoozeDuration = _m.snoozeSettings.durationMinutes;
    _snoozeCount =
        SharedPreferencesWithCache.instance.get<int>(
          'snooze_count_${_m.alarmId}',
        ) ??
        0;

    _startAlarmWatchdog();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _snoozeConfirmCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _snoozeConfirmAnim = CurvedAnimation(
      parent: _snoozeConfirmCtrl,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _alarmWatchdogTimer?.cancel();
    _pulseCtrl.dispose();
    _snoozeConfirmCtrl.dispose();
    super.dispose();
  }

  // ── active alarm sound protection ─────────────────────────────────────────

  void _startAlarmWatchdog() {
    _alarmWatchdogTimer?.cancel();
    _alarmWatchdogTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _restoreSoundIfNotificationWasDismissed(),
    );
  }

  Future<void> _restoreSoundIfNotificationWasDismissed() async {
    if (
      !mounted ||
      _snoozed ||
      _isProcessingDismiss ||
      _isStartingBackupRingtone
    ) {
      return;
    }

    final alarms = await Alarm.getAlarms();
    final stillScheduledOrRinging = alarms.any(
      (alarm) => alarm.id == widget.alarmSettings.id,
    );

    if (stillScheduledOrRinging || !mounted || _snoozed || _isProcessingDismiss) {
      return;
    }

    _isStartingBackupRingtone = true;
    debugPrint(
      '⚠️ Alarm notification/audio stopped while AlarmGate is open. Starting backup ringtone.',
    );

    try {
      await AlarmRingtoneRecoveryService.instance.startBackupRingtone(
        alarmModel: widget.alarmModel,
        reason: 'notification_dismissed',
      );
    } finally {
      _isStartingBackupRingtone = false;
    }
  }

  // ── snooze logic ───────────────────────────────────────────────────────────

  Future<void> _snooze() async {
    if (!_canSnooze) return;
    unawaited(HapticFeedback.mediumImpact());
    await AlarmRingtoneRecoveryService.instance.stopBackupRingtone();
    if (!mounted) return;

    await context.read<AlarmCubit>().snoozeAlarm(
      alarmSettings: widget.alarmSettings,
      alarmRef: _alarmRef,
      snoozeMinutes: _snoozeDuration,
    );
    _snoozeConfirmCtrl.forward(from: 0);
    setState(() {
      _snoozed = true;
      _snoozeCount++;
      _remaining = Duration(minutes: _snoozeDuration);
      _pulseCtrl.stop();
    });
    _startCountdown();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.localization.alarmSnoozed(_snoozeDuration)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (_remaining.inSeconds <= 1) {
        unawaited(_finishSnoozeCountdown());
        return;
      }

      setState(() {
        _remaining -= const Duration(seconds: 1);
      });
    });
  }

  Future<void> _finishSnoozeCountdown() async {
    if (_isFinishingSnooze) return;
    _isFinishingSnooze = true;
    _countdownTimer?.cancel();

    await context.read<AlarmCubit>().wakeSnoozedAlarmNow(
      alarmSettings: widget.alarmSettings,
      alarmRef: _alarmRef,
    );

    await AlarmRingtoneRecoveryService.instance.startBackupRingtone(
      alarmModel: widget.alarmModel,
      reason: 'snooze_finished',
    );

    if (!mounted) return;

    setState(() {
      _snoozed = false;
      _remaining = Duration.zero;
      _pulseCtrl.repeat(reverse: true);
    });

    _isFinishingSnooze = false;
  }

  Future<void> _cancelSnooze() async {
    unawaited(HapticFeedback.mediumImpact());
    _countdownTimer?.cancel();
    await context.read<AlarmCubit>().wakeSnoozedAlarmNow(
      alarmSettings: widget.alarmSettings,
      alarmRef: _alarmRef,
    );

    await AlarmRingtoneRecoveryService.instance.startBackupRingtone(
      alarmModel: widget.alarmModel,
      reason: 'wake_now',
    );

    if (!mounted) return;

    setState(() {
      _snoozed = false;
      _remaining = Duration.zero;
      _pulseCtrl.repeat(reverse: true);
    });
  }

  // ── dismiss logic ──────────────────────────────────────────────────────────

  Future<void> _dismiss() async {
    if (_isProcessingDismiss) return;

    _isProcessingDismiss = true;

    unawaited(HapticFeedback.heavyImpact());
    _countdownTimer?.cancel();

    final mode = _m.dismissSettings.mode;

    if (mode == AlarmDisarmMode.normal) {
      await dismissActiveAlarmAndClose(
        context: context,
        alarmSettings: widget.alarmSettings,
        alarmModel: widget.alarmModel,
      );

      return;
    }

    final routeName = switch (mode) {
      AlarmDisarmMode.math => AppRoute.mathAlarm.name,
      AlarmDisarmMode.shake => AppRoute.shakeAlarm.name,
      AlarmDisarmMode.retype => AppRoute.retypeAlarm.name,
      AlarmDisarmMode.walk => AppRoute.walkAlarm.name,
      AlarmDisarmMode.normal => null,
    };

    if (!mounted || routeName == null) return;

    context.pushReplacementNamed(
      routeName,
      extra: (widget.alarmSettings, widget.alarmModel),
    );
  }

  // ── drag handlers ──────────────────────────────────────────────────────────

  void _onDragUpdate(DragUpdateDetails d) {
    // Drag up = negative dy = increase duration
    _dragAccum -= d.delta.dy;
    final steps = (_dragAccum / _dragPerStep).truncate();
    if (steps == 0) return;
    _dragAccum -= steps * _dragPerStep;
    final newDuration = (_snoozeDuration + steps).clamp(_minSnooze, _maxSnooze);
    if (newDuration != _snoozeDuration) {
      unawaited(HapticFeedback.selectionClick());
      setState(() => _snoozeDuration = newDuration);
    }
  }

  void _onDragEnd(DragEndDetails _) {
    _dragAccum = 0;
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors:
                  isDark
                      ? [AppColors.darkScaffold1, AppColors.darkScaffold2]
                      : [AppColors.lightScaffold1, AppColors.lightScaffold2],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Top info ───────────────────────────────────────────────
                Expanded(
                  flex: 2,
                  child: _TopInfo(
                    alarmSettings: widget.alarmSettings,
                    snoozed: _snoozed,
                    remaining: _remaining,
                    snoozeCount: _snoozeCount,
                    maxCount: _maxCount,
                    nextRingTime:
                        _snoozed ? DateTime.now().add(_remaining) : null,
                    pulseAnim: _pulseAnim,
                    snoozeConfirmAnim: _snoozeConfirmAnim,
                    isDark: isDark,
                  ),
                ),

                BlocSelector<SettingsCubit, SettingsState, bool>(
                  selector: (state) => state.weatherAwareEnabled,
                  builder:
                      (_, enabled) =>
                          enabled
                              ? const WeatherAlarmCard()
                              : const SizedBox.shrink(),
                ),

                // ── Snooze button (80%) ────────────────────────────────────
                Expanded(
                  flex: 4,
                  child:
                      _canSnooze || _snoozed
                          ? _SnoozePanel(
                            snoozed: _snoozed,
                            duration: _snoozeDuration,
                            remaining: _remaining,
                            canSnooze: _canSnooze,
                            onTap: _snoozed ? null : _snooze,
                            onCancelSnooze: _snoozed ? _cancelSnooze : null,
                            onDragUpdate: _snoozed ? null : _onDragUpdate,
                            onDragEnd: _snoozed ? null : _onDragEnd,
                            isDark: isDark,
                            minSnooze: _minSnooze,
                            maxSnooze: _maxSnooze,
                          )
                          : const SizedBox.shrink(),
                ),

                // ── Dismiss button (20%) ───────────────────────────────────
                Expanded(
                  flex: 1,
                  child: _DismissPanel(
                    mode: _m.dismissSettings.mode,
                    snoozed: _snoozed,
                    onDismiss: _dismiss,
                    isDark: isDark,
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top info
// ─────────────────────────────────────────────────────────────────────────────

class _TopInfo extends StatelessWidget {
  final AlarmSettings alarmSettings;
  final bool snoozed;
  final Duration remaining;
  final int snoozeCount;
  final int maxCount;
  final DateTime? nextRingTime;
  final Animation<double> pulseAnim;
  final Animation<double> snoozeConfirmAnim;
  final bool isDark;

  const _TopInfo({
    required this.alarmSettings,
    required this.snoozed,
    required this.remaining,
    required this.snoozeCount,
    required this.maxCount,
    required this.nextRingTime,
    required this.pulseAnim,
    required this.snoozeConfirmAnim,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat.jm().format(DateTime.now());
    final muted =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 180;
        final horizontalPadding = isCompactHeight ? 16.0 : 24.0;
        final topPadding = isCompactHeight ? 8.0 : 24.0;
        final iconSize = isCompactHeight ? 40.0 : 52.0;
        final titleStyle = AppTextStyles.large(context).copyWith(
          fontSize: isCompactHeight ? 18 : null,
        );
        final timeStyle = AppTextStyles.heading(context).copyWith(
          color: muted,
          fontSize: isCompactHeight ? 24 : null,
        );
        final contentWidth =
            constraints.maxWidth > horizontalPadding * 2
                ? constraints.maxWidth - (horizontalPadding * 2)
                : constraints.maxWidth;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            0,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Clock icon with pulse when not snoozed
                    ScaleTransition(
                      scale:
                          snoozed
                              ? const AlwaysStoppedAnimation(1.0)
                              : pulseAnim,
                      child: ScaleTransition(
                        scale:
                            snoozeConfirmAnim.status == AnimationStatus.dismissed
                                ? const AlwaysStoppedAnimation(1.0)
                                : Tween<double>(
                                  begin: 1.0,
                                  end: 1.3,
                                ).animate(snoozeConfirmAnim),
                        child: Icon(
                          snoozed ? Icons.snooze : Icons.alarm,
                          size: iconSize,
                          color: snoozed ? Colors.orange : AppColors.primary,
                        ),
                      ),
                    ),

                    SizedBox(height: isCompactHeight ? 8 : 12),

                    // Alarm title
                    Text(
                      alarmSettings.notificationSettings.body,
                      style: titleStyle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Current time
                    Text(timeStr, style: timeStyle),

                    // Snooze badge
                    if (snoozeCount > 0) ...[
                      SizedBox(height: isCompactHeight ? 6 : 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          maxCount == 0
                              ? context.tr(
                                'Snoozed {count}×',
                                {'count': snoozeCount},
                              )
                              : context.tr(
                                'Snoozed {count} / {max}×',
                                {'count': snoozeCount, 'max': maxCount},
                              ),
                          style: AppTextStyles.caption(context).copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    // Next ring time when snoozed
                    if (nextRingTime != null) ...[
                      SizedBox(height: isCompactHeight ? 6 : 8),
                      Text(
                        context.tr(
                          'Ringing again at {time}',
                          {'time': DateFormat.jm().format(nextRingTime!)},
                        ),
                        style: AppTextStyles.caption(context).copyWith(
                          color: muted,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Snooze panel
// ─────────────────────────────────────────────────────────────────────────────

class _SnoozePanel extends StatelessWidget {
  final int minSnooze;
  final int maxSnooze;

  final bool snoozed;
  final int duration;
  final Duration remaining;
  final bool canSnooze;
  final VoidCallback? onTap;
  final VoidCallback? onCancelSnooze;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;
  final bool isDark;

  const _SnoozePanel({
    required this.snoozed,
    required this.duration,
    required this.remaining,
    required this.canSnooze,
    required this.onTap,
    required this.onCancelSnooze,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.isDark,
    required this.minSnooze,
    required this.maxSnooze,
  });

  String _formatRemaining(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GestureDetector(
        onTap: onTap,
        onVerticalDragUpdate: onDragUpdate,
        onVerticalDragEnd: onDragEnd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color:
                snoozed
                    ? Colors.orange.withOpacity(isDark ? 0.18 : 0.12)
                    : AppColors.primary.withOpacity(isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color:
                  snoozed
                      ? Colors.orange.withOpacity(0.35)
                      : AppColors.primary.withOpacity(0.35),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            // ← clip the fill to rounded corners
            borderRadius: BorderRadius.circular(26.5),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Fill layer ──────────────────────────────────────────
                if (!snoozed)
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment:
                          Alignment.bottomCenter, // fill rises from bottom
                      heightFactor:
                          (duration - minSnooze) / (maxSnooze - minSnooze),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        color: AppColors.primary.withOpacity(
                          isDark ? 0.22 : 0.14,
                        ),
                      ),
                    ),
                  ),

                // ── Countdown arc when snoozed ──────────────────────────
                if (snoozed)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        value:
                            remaining.inSeconds /
                            Duration(minutes: duration).inSeconds,
                        strokeWidth: 3,
                        color: Colors.orange.withOpacity(0.5),
                        backgroundColor: Colors.orange.withOpacity(0.1),
                      ),
                    ),
                  ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.snooze,
                      size: 36,
                      color: snoozed ? Colors.orange : AppColors.primary,
                    ),
                    const SizedBox(height: 10),

                    if (!snoozed) ...[
                      // Duration display with drag hint
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$duration',
                              style: AppTextStyles.large(context).copyWith(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                context.tr('min'),
                                style: AppTextStyles.body(
                                  context,
                                ).copyWith(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          context.tr('Tap to snooze · drag to adjust'),
                          style: AppTextStyles.caption(
                            context,
                          ).copyWith(color: AppColors.primary.withOpacity(0.6)),
                        ),
                      ),
                    ] else ...[
                      // Countdown
                      Center(
                        child: Text(
                          _formatRemaining(remaining),
                          style: AppTextStyles.large(context).copyWith(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            height: 1,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: onCancelSnooze,
                          icon: const Icon(Icons.alarm_rounded, size: 16),
                          label: Text(context.tr('Wake now')),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dismiss panel
// ─────────────────────────────────────────────────────────────────────────────

class _DismissPanel extends StatelessWidget {
  final AlarmDisarmMode mode;
  final bool snoozed;
  final VoidCallback onDismiss;
  final bool isDark;

  const _DismissPanel({
    required this.mode,
    required this.snoozed,
    required this.onDismiss,
    required this.isDark,
  });

  String _dismissLabel(BuildContext context, AlarmDisarmMode mode) =>
      switch (mode) {
        AlarmDisarmMode.normal => context.tr('Dismiss'),
        AlarmDisarmMode.walk => context.tr('Dismiss — Walk'),
        AlarmDisarmMode.math => context.tr('Dismiss — Math'),
        AlarmDisarmMode.shake => context.tr('Dismiss — Shake'),
        AlarmDisarmMode.retype => context.tr('Dismiss — Retype'),
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: snoozed ? null : onDismiss,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color:
                snoozed
                    ? (isDark
                        ? AppColors.darkScaffold1.withOpacity(0.4)
                        : Colors.white.withOpacity(0.4))
                    : Colors.red.withOpacity(isDark ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  snoozed
                      ? (isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBlueGrey)
                      : Colors.red.withOpacity(0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                snoozed ? Icons.lock_clock_rounded : Icons.alarm_off_outlined,
                size: 18,
                color:
                    snoozed
                        ? (isDark
                            ? AppColors.darkBackgroundText.withValues(alpha: 0.55)
                            : AppColors.lightBackgroundText.withValues(alpha: 0.55))
                        : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                snoozed
                    ? context.tr('Wake now to dismiss')
                    : _dismissLabel(context, mode),
                style: AppTextStyles.body(context).copyWith(
                  color:
                      snoozed
                          ? (isDark
                              ? AppColors.darkBackgroundText.withValues(alpha: 0.55)
                              : AppColors.lightBackgroundText.withValues(alpha: 0.55))
                          : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
