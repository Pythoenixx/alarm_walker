import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/services/alarm_cubit.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/stop_alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class WalkAlarmScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;
  const WalkAlarmScreen({super.key, required this.alarmSettings});

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

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  String _status = 'stopped';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _requiredSteps = 50; // Require 50 steps to dismiss

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initPedometer();
  }

  Future<void> _initPedometer() async {
    // Request activity recognition permission
    final status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      _startListening();
    } else {
      setState(() {
        _error = 'Permission denied. Please enable activity recognition.';
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

  void _onStepCount(StepCount event) {
    if (!_isInitialized) {
      _initialSteps = event.steps;
      _isInitialized = true;
    }

    final stepsTaken = event.steps - _initialSteps;

    setState(() {
      _currentSteps = stepsTaken;
    });

    // Animate when steps increase
    if (stepsTaken > 0 && stepsTaken <= _requiredSteps) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }

    // Check if goal reached
    if (stepsTaken >= _requiredSteps) {
      _dismissAlarm();
    }
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    setState(() {
      _status = event.status;
    });
  }

  void _onStepCountError(error) {
    setState(() {
      _error = 'Step counter error: $error';
    });
  }

  void _onPedestrianStatusError(error) {
    // Pedestrian status errors are less critical
    debugPrint('Pedestrian status error: $error');
  }

  Future<void> _dismissAlarm() async {
    await context.read<AlarmCubit>().stopAlarm(widget.alarmSettings.id);
    if (mounted) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final progress = (_currentSteps / _requiredSteps).clamp(0.0, 1.0);

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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Spacer(),
                  // Alarm title
                  Text(
                    widget.alarmSettings.notificationSettings.body,
                    style: AppTextStyles.large(
                      context,
                    ).copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Walking icon with animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isDark
                                ? AppColors.darkScaffold1.withOpacity(0.5)
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
                        size: 80,
                        color: progress >= 1.0 ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Steps counter
                  Text(
                    '$_currentSteps',
                    style: AppTextStyles.large(context).copyWith(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: progress >= 1.0 ? Colors.green : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'of $_requiredSteps steps',
                    style: TextStyle(
                      fontSize: 18,
                      color:
                          isDark
                              ? AppColors.darkBackgroundText.withOpacity(0.7)
                              : AppColors.lightBackgroundText.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Progress bar
                  Container(
                    height: 24,
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
                                : Colors.white.withOpacity(0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1.0 ? Colors.green : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Status text
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _status == 'walking'
                              ? Colors.green.withOpacity(0.2)
                              : (_status == 'stopped'
                                  ? Colors.orange.withOpacity(0.2)
                                  : Colors.blue.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            _status == 'walking'
                                ? Colors.green.withOpacity(0.5)
                                : (_status == 'stopped'
                                    ? Colors.orange.withOpacity(0.5)
                                    : Colors.blue.withOpacity(0.5)),
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
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
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
                  const SizedBox(height: 32),
                  // Instruction text
                  Text(
                    progress >= 1.0
                        ? '✓ Goal reached! Tap below to dismiss'
                        : 'Walk around to dismiss the alarm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          isDark
                              ? AppColors.darkBackgroundText.withOpacity(0.8)
                              : AppColors.lightBackgroundText.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Dismiss button (only enabled when goal reached)
                  GestureDetector(
                    onTap: progress >= 1.0 ? _dismissAlarm : null,
                    child: Opacity(
                      opacity: progress >= 1.0 ? 1.0 : 0.5,
                      child: const StopButton(),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
