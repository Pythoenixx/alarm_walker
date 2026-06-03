import 'dart:async';
import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/services/alarm_dismiss_helper.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/gradient_linear_progress_indicator.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeAlarmScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;
  final AlarmModel alarmModel;

  const ShakeAlarmScreen({
    super.key,
    required this.alarmSettings,
    required this.alarmModel,
  });

  @override
  State<ShakeAlarmScreen> createState() => _ShakeAlarmScreenState();
}

class _ShakeAlarmScreenState extends State<ShakeAlarmScreen> {
  late final StreamSubscription<AccelerometerEvent> _subscription;
  Timer? _debounce;
  int _shakeCount = 0;

  bool _isDismissing = false;

  int get _requiredShakes {
    final value = widget.alarmModel.dismissSettings.shakeCount;
    if (value < 1) return 1;
    if (value > 999) return 999;
    return value;
  }

  int get _shakeIntensity {
    final value = widget.alarmModel.dismissSettings.shakeIntensity;
    if (value < 1) return 1;
    if (value > 3) return 3;
    return value;
  }

  double get _threshold {
    return switch (_shakeIntensity) {
      1 => 1.8,
      2 => 2.2,
      _ => 2.6,
    };
  }

  String get _intensityLabel {
    return switch (_shakeIntensity) {
      1 => 'Gentle sensitivity',
      2 => 'Balanced sensitivity',
      _ => 'Strong shake needed',
    };
  }

  @override
  void initState() {
    super.initState();
    _subscription = accelerometerEventStream().listen(_onData);
  }

  Future<void> _onData(AccelerometerEvent event) async {
    if (_isDismissing) return;

    final double gX = event.x / 9.81;
    final double gY = event.y / 9.81;
    final double gZ = event.z / 9.81;

    final double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

    if (gForce <= _threshold) return;

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 100), () async {
      if (!mounted || _isDismissing) return;

      setState(() {
        _shakeCount++;
      });

      if (_shakeCount < _requiredShakes) return;

      _isDismissing = true;

      await _subscription.cancel();

      if (!mounted) return;

      await dismissActiveAlarmAndClose(
        context: context,
        alarmSettings: widget.alarmSettings,
        alarmModel: widget.alarmModel,
      );
    });
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compactLayout = screenHeight < 720 || textScale > 1.15;
    final pagePadding = compactLayout ? 16.0 : 24.0;
    final animationSize = compactLayout ? 190.0 : 250.0;
    final gap = compactLayout ? 14.0 : 20.0;

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
                        SizedBox(
                          height: animationSize,
                          child: Lottie.asset(
                            'assets/lottie/phone_vibrate.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: gap),
                        Text(
                          widget.alarmSettings.notificationSettings.body,
                          style: AppTextStyles.large(context).copyWith(
                            fontSize: compactLayout ? 18 : null,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: gap),
                        Text(
                          context.localization.shakePhone,
                          style: AppTextStyles.large(context).copyWith(
                            fontSize: compactLayout ? 18 : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: gap),
                        Text(
                          context.localization.shakesCount(
                            _shakeCount,
                            _requiredShakes,
                          ),
                          style: AppTextStyles.large(context).copyWith(
                            fontSize: compactLayout ? 18 : null,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _intensityLabel,
                          style: AppTextStyles.caption(context).copyWith(
                            color:
                                isDark
                                    ? AppColors.darkBackgroundText.withValues(
                                      alpha: 0.7,
                                    )
                                    : AppColors.lightBackgroundText.withValues(
                                      alpha: 0.7,
                                    ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: gap),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: compactLayout ? 12 : 40,
                          ),
                          child: GradientLinearProgressIndicator(
                            value: (_shakeCount / _requiredShakes).clamp(
                              0.0,
                              1.0,
                            ),
                          ),
                        ),
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
