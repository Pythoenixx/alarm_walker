import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/services/alarm_dismiss_helper.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/stop_alarm.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

class WalkAlarmScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;
  final AlarmModel alarmModel;
  const WalkAlarmScreen({
    super.key,
    required this.alarmSettings,
    required this.alarmModel,
  });

  @override
  State<WalkAlarmScreen> createState() => _WalkAlarmScreenState();
}

class _WalkAlarmScreenState extends State<WalkAlarmScreen>
    with SingleTickerProviderStateMixin {
  late final int _requiredSteps;
  int _currentSteps = 0;
  int _initialSteps = 0;
  bool _isInitialized = false;
  String? _error;
  bool _permissionDenied = false;

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  String _status = 'stopped';
  bool _isShaking = false;
  DateTime? _lastShakeTime;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _isDismissing = false;

  int get _configuredWalkSteps {
    final steps = widget.alarmModel.dismissSettings.walkSteps;
    if (steps < 1) return 1;
    if (steps > 9999) return 9999;
    return steps;
  }

  @override
  void initState() {
    super.initState();
    _requiredSteps = _configuredWalkSteps;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    unawaited(_initPedometer());
    _startShakeDetection();
  }

  Future<void> _initPedometer() async {
    // Check current permission status
    final status = await Permission.activityRecognition.status;

    if (status.isGranted) {
      _startListening();
    } else if (status.isDenied) {
      // Request permission
      final result = await Permission.activityRecognition.request();
      if (result.isGranted) {
        _startListening();
      } else {
        setState(() {
          _permissionDenied = true;
          _error =
              'Activity recognition permission is required to use this feature.';
        });
      }
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _permissionDenied = true;
        _error = 'Permission permanently denied. Please enable it in settings.';
      });
    }
  }

  void _startListening() {
    _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
      _onPedestrianStatusChanged,
      onError: _onPedestrianStatusError,
    );

    _stepCountSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
    );
  }

  // Shake detection to prevent cheating
  void _startShakeDetection() {
    // Configuration Variables
    const double shakeForceThreshold = 120.0; // Square of magnitude
    const int requiredShakeSamples = 5; // Number of consecutive events
    const int shakeCooldownSeconds = 10; // Time between warning triggers
    const int warningDisplayDuration = 3; // How long the UI stays active

    int shakeCount = 0;

    _accelerometerSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      // Calculate total acceleration magnitude (using square of magnitude for performance)
      final totalAcceleration =
          event.x * event.x + event.y * event.y + event.z * event.z;

      // Detect intense shaking
      if (totalAcceleration > shakeForceThreshold) {
        shakeCount++;

        // Only show warning if sustained shaking is detected
        if (shakeCount >= requiredShakeSamples) {
          final now = DateTime.now();

          final bool isCooldownOver =
              _lastShakeTime == null ||
              now.difference(_lastShakeTime!).inSeconds > shakeCooldownSeconds;

          if (isCooldownOver) {
            _lastShakeTime = now;
            setState(() {
              _isShaking = true;
            });

            // Reset shake warning after the specified duration
            Future.delayed(const Duration(seconds: warningDisplayDuration), () {
              if (mounted) {
                setState(() {
                  _isShaking = false;
                });
              }
            });
          }
          shakeCount = 0; // Reset after triggering or checking cooldown
        }
      } else {
        // Reset counter if motion falls below the threshold
        shakeCount = 0;
      }
    });
  }

  void _onStepCount(StepCount event) {
    if (!_isInitialized) {
      _initialSteps = event.steps;
      _isInitialized = true;
    }

    // Reduce steps if shaking is detected (penalty instead of blocking)
    int stepsTaken = event.steps - _initialSteps;
    if (_isShaking && stepsTaken > 0) {
      stepsTaken = (stepsTaken * 0.5).round(); // 50% penalty during shake
    }

    setState(() {
      _currentSteps = stepsTaken;
    });

    // Animate when steps increase
    if (stepsTaken > 0 && stepsTaken <= _requiredSteps && !_isShaking) {
      unawaited(
        _animationController.forward().then((_) {
          unawaited(_animationController.reverse());
        }),
      );
    }

    // Check if goal reached
    if (stepsTaken >= _requiredSteps) {
      unawaited(_dismissAlarm());
    }
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    setState(() {
      _status = event.status;
    });
  }

  void _onStepCountError(Object error) {
    setState(() {
      _error = 'Step counter error: $error';
    });
  }

  void _onPedestrianStatusError(Object error) {
    // Pedestrian status errors are less critical
    debugPrint('Pedestrian status error: $error');
  }

  Future<void> _dismissAlarm() async {
    if (_isDismissing) return;
    _isDismissing = true;

    await dismissActiveAlarmAndClose(
      context: context,
      alarmSettings: widget.alarmSettings,
      alarmModel: widget.alarmModel,
    );
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  Future<void> _fallbackDismiss() async {
    // Show confirmation dialog before allowing fallback dismiss
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = context.isDarkMode;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkScaffold1 : AppColors.lightContainer1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Dismiss Alarm?'),
          content: const Text(
            "You haven't completed the walking goal. "
            'Are you sure you want to dismiss the alarm?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Dismiss Anyway'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _dismissAlarm();
    }
  }

  @override
  void dispose() {
    unawaited(_stepCountSubscription?.cancel());
    unawaited(_pedestrianStatusSubscription?.cancel());
    unawaited(_accelerometerSubscription?.cancel());
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final progress = (_currentSteps / _requiredSteps).clamp(0.0, 1.0);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compactLayout = screenHeight < 720 || textScale > 1.15;
    final pagePadding = compactLayout ? 16.0 : 24.0;
    final largeGap = compactLayout ? 24.0 : 40.0;
    final mediumGap = compactLayout ? 16.0 : 24.0;
    final circlePadding = compactLayout ? 24.0 : 32.0;
    final walkIconSize = compactLayout ? 64.0 : 80.0;
    final stepFontSize = compactLayout ? 56.0 : 72.0;

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(pagePadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (pagePadding * 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Alarm title
                        Text(
                          widget.alarmSettings.notificationSettings.body,
                          style: AppTextStyles.large(context).copyWith(
                            fontSize: compactLayout ? 18 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: largeGap),

                        // Show permission denied state
                        if (_permissionDenied)
                          _PermissionDeniedWidget(
                            isDark: isDark,
                            error: _error,
                            onOpenSettings: _openSettings,
                            onDismiss: _fallbackDismiss,
                          )
                        else ...[
                          // Walking icon with animation
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              padding: EdgeInsets.all(circlePadding),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isDark
                                        ? AppColors.darkScaffold1.withValues(
                                          alpha: 0.5,
                                        )
                                        : AppColors.lightContainer1,
                                border: Border.all(
                                  color:
                                      isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBlueGrey,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _status == 'walking'
                                    ? Icons.directions_walk
                                    : Icons.directions_run,
                                size: walkIconSize,
                                color:
                                    progress >= 1.0 ? Colors.green : Colors.blue,
                              ),
                            ),
                          ),
                          SizedBox(height: largeGap),
                          // Steps counter
                          Text(
                            '$_currentSteps',
                            style: AppTextStyles.large(context).copyWith(
                              fontSize: stepFontSize,
                              fontWeight: FontWeight.bold,
                              color: progress >= 1.0 ? Colors.green : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'of $_requiredSteps steps',
                            style: TextStyle(
                              fontSize: compactLayout ? 16 : 18,
                              color:
                                  isDark
                                      ? AppColors.darkBackgroundText.withValues(
                                        alpha: 0.7,
                                      )
                                      : AppColors.lightBackgroundText.withValues(
                                        alpha: 0.7,
                                      ),
                            ),
                          ),
                          SizedBox(height: largeGap),
                          // Progress bar
                          Container(
                            height: compactLayout ? 20 : 24,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBlueGrey,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor:
                                    isDark
                                        ? AppColors.darkScaffold1
                                        : Colors.white.withValues(alpha: 0.5),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress >= 1.0 ? Colors.green : Colors.blue,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: mediumGap),
                          // Shake warning - gentler message
                          if (_isShaking)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Walk naturally for best results',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.orange,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Status text
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _status == 'walking'
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : (_status == 'stopped'
                                          ? Colors.orange.withValues(alpha: 0.2)
                                          : Colors.blue.withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    _status == 'walking'
                                        ? Colors.green.withValues(alpha: 0.5)
                                        : (_status == 'stopped'
                                            ? Colors.orange.withValues(alpha: 0.5)
                                            : Colors.blue.withValues(alpha: 0.5)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _status == 'walking'
                                      ? Icons.directions_walk
                                      : _status == 'stopped'
                                      ? Icons.pause_circle_outline
                                      : Icons.help_outline,
                                  size: 16,
                                  color:
                                      _status == 'walking'
                                          ? Colors.green
                                          : (_status == 'stopped'
                                              ? Colors.orange
                                              : Colors.blue),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _status == 'walking'
                                      ? 'Walking detected'
                                      : _status == 'stopped'
                                      ? 'Start walking!'
                                      : 'Unknown status',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        _status == 'walking'
                                            ? Colors.green
                                            : (_status == 'stopped'
                                                ? Colors.orange
                                                : Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_error != null && !_permissionDenied) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: mediumGap),
                          // Instruction text
                          Text(
                            progress >= 1.0
                                ? '✓ Goal reached! Tap below to dismiss'
                                : 'Walk naturally until you reach $_requiredSteps steps',
                            style: TextStyle(
                              fontSize: compactLayout ? 15 : 16,
                              fontWeight: FontWeight.w500,
                              color:
                                  isDark
                                      ? AppColors.darkBackgroundText.withValues(
                                        alpha: 0.8,
                                      )
                                      : AppColors.lightBackgroundText.withValues(
                                        alpha: 0.8,
                                      ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: mediumGap),
                          // Dismiss button (only enabled when goal reached)
                          GestureDetector(
                            onTap: progress >= 1.0 ? _dismissAlarm : null,
                            child: Opacity(
                              opacity: progress >= 1.0 ? 1.0 : 0.5,
                              child: const StopButton(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionDeniedWidget extends StatelessWidget {
  final bool isDark;
  final String? error;
  final VoidCallback onOpenSettings;
  final VoidCallback onDismiss;

  const _PermissionDeniedWidget({
    required this.isDark,
    required this.error,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.lock_outline,
          size: 80,
          color:
              isDark
                  ? AppColors.darkBackgroundText.withValues(alpha: 0.5)
                  : AppColors.lightBackgroundText.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 24),
        Text(
          'Permission Required',
          style: AppTextStyles.large(
            context,
          ).copyWith(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 32),
              const SizedBox(height: 12),
              Text(
                error ?? 'Activity recognition permission is needed',
                style: const TextStyle(color: Colors.orange, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: onDismiss,
          child: Text(
            'Dismiss Anyway',
            style: TextStyle(
              color:
                  isDark
                      ? AppColors.darkBackgroundText
                      : AppColors.lightBackgroundText,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
