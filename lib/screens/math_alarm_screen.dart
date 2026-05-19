import 'dart:async';
import 'dart:math';

import 'package:alarm/model/alarm_settings.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/dismiss_settings.dart';
import 'package:alarm_walker/services/alarm_dismiss_helper.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/stop_alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

enum _Operation { add, subtract, multiply, divide }

class _Problem {
  final int a;
  final int b;
  final _Operation op;

  const _Problem({required this.a, required this.b, required this.op});

  int get answer => switch (op) {
    _Operation.add => a + b,
    _Operation.subtract => a - b,
    _Operation.multiply => a * b,
    _Operation.divide => a ~/ b,
  };

  String get symbol => switch (op) {
    _Operation.add => '+',
    _Operation.subtract => '−',
    _Operation.multiply => '×',
    _Operation.divide => '÷',
  };

  static _Problem generate({required int difficulty}) {
    final rnd = Random();

    final ops = switch (difficulty) {
      1 => [_Operation.add, _Operation.subtract],
      2 => [_Operation.add, _Operation.subtract, _Operation.multiply],
      _ => _Operation.values,
    };

    final op = ops[rnd.nextInt(ops.length)];

    return switch (op) {
      _Operation.add => () {
        final max =
            difficulty == 1
                ? 20
                : difficulty == 2
                ? 50
                : 100;

        return _Problem(
          a: rnd.nextInt(max) + 1,
          b: rnd.nextInt(max) + 1,
          op: op,
        );
      }(),
      _Operation.subtract => () {
        final max =
            difficulty == 1
                ? 20
                : difficulty == 2
                ? 50
                : 100;

        final a = rnd.nextInt(max) + 5;
        final b = difficulty == 3 ? rnd.nextInt(max) + 1 : rnd.nextInt(a) + 1;

        return _Problem(a: a, b: b, op: op);
      }(),
      _Operation.multiply => () {
        final max = difficulty == 2 ? 12 : 20;

        return _Problem(
          a: rnd.nextInt(max) + 1,
          b: rnd.nextInt(max) + 1,
          op: op,
        );
      }(),
      _Operation.divide => () {
        final maxQuotient = difficulty == 3 ? 20 : 12;
        final b = rnd.nextInt(9) + 2;
        final res = rnd.nextInt(maxQuotient) + 1;

        return _Problem(a: res * b, b: b, op: op);
      }(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class MathAlarmScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;
  final AlarmModel alarmModel;

  const MathAlarmScreen({
    super.key,
    required this.alarmSettings,
    required this.alarmModel,
  });

  @override
  State<MathAlarmScreen> createState() => _MathAlarmScreenState();
}

class _MathAlarmScreenState extends State<MathAlarmScreen>
    with TickerProviderStateMixin {
  // ── problem state ──────────────────────────────────────────────────────────
  late _Problem _current;
  int _solved = 0;
  String _input = '';
  bool _negative = false;
  String? _error;

  // ── task timer ─────────────────────────────────────────────────────────────
  Timer? _taskTimer;
  int _taskSecondsLeft = 0;

  // ── animations ─────────────────────────────────────────────────────────────
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  late final AnimationController _successCtrl;
  late final Animation<double> _successAnim;

  late final AnimationController _problemCtrl;
  late final Animation<Offset> _problemSlide;
  late final Animation<double> _problemFade;

  DismissSettings get _ds => widget.alarmModel.dismissSettings;

  int get _total => _ds.mathProblemCount;

  bool get _timerEnabled => _ds.taskTimerSeconds != null;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _successAnim = CurvedAnimation(parent: _successCtrl, curve: Curves.easeOut);

    _problemCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0,
    );

    _problemSlide = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _problemCtrl, curve: Curves.easeOutCubic),
    );

    _problemFade = CurvedAnimation(parent: _problemCtrl, curve: Curves.easeOut);

    _nextProblem(animate: false);
  }

  @override
  void dispose() {
    _taskTimer?.cancel();
    _shakeCtrl.dispose();
    _successCtrl.dispose();
    _problemCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Logic
  // ───────────────────────────────────────────────────────────────────────────

  void _nextProblem({bool animate = true}) {
    _taskTimer?.cancel();

    _current = _Problem.generate(difficulty: _ds.mathDifficulty);
    _input = '';
    _negative = false;
    _error = null;

    if (_timerEnabled) {
      _taskSecondsLeft = _ds.taskTimerSeconds!;

      _taskTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;

        setState(() {
          _taskSecondsLeft--;

          if (_taskSecondsLeft <= 0) {
            _taskTimer?.cancel();
            _onTimerExpired();
          }
        });
      });
    }

    if (animate) {
      _problemCtrl.forward(from: 0);
    }
  }

  void _onTimerExpired() {
    unawaited(HapticFeedback.heavyImpact());

    setState(() {
      _error = 'Time\'s up!'; // TODO: localize
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(_nextProblem);
    });
  }

  Future<void> _trySubmit() async {
    final raw = _input.isEmpty ? null : int.tryParse(_input);
    if (raw == null) return;

    final answer = _negative ? -raw : raw;

    if (answer == _current.answer) {
      unawaited(HapticFeedback.mediumImpact());

      _taskTimer?.cancel();

      await _successCtrl.forward(from: 0);
      await _successCtrl.reverse();

      if (!mounted) return;

      setState(() {
        _solved++;
      });

      if (_solved >= _total) {
        await _dismiss();
        return;
      }

      if (!mounted) return;

      setState(() {
        _nextProblem();
      });
    } else {
      unawaited(HapticFeedback.vibrate());

      await _shakeCtrl.forward(from: 0);

      if (!mounted) return;

      setState(() {
        _error = context.localization.wrongAnswer;
      });
    }
  }

  Future<void> _skipProblem() async {
    if (!_ds.mathAllowSkip) return;

    unawaited(HapticFeedback.selectionClick());

    _taskTimer?.cancel();

    setState(() {
      _nextProblem();
    });
  }

  Future<void> _dismiss() async {
    _taskTimer?.cancel();

    await dismissActiveAlarmAndClose(
      context: context,
      alarmSettings: widget.alarmSettings,
      alarmModel: widget.alarmModel,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Input
  // ───────────────────────────────────────────────────────────────────────────

  void _onKey(String value) {
    setState(() {
      _error = null;

      if (value == 'DEL') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        } else {
          _negative = false;
        }
      } else if (value == '±') {
        _negative = !_negative;
      } else if (_input.length < 4) {
        _input += value;
      }
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final progressFraction = _total > 0 ? _solved / _total : 0.0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  isDark
                      ? [AppColors.darkScaffold1, AppColors.darkScaffold2]
                      : [AppColors.lightScaffold1, AppColors.lightScaffold2],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _Header(
                  title: widget.alarmSettings.notificationSettings.body,
                  solved: _solved,
                  total: _total,
                  progressFraction: progressFraction,
                  isDark: isDark,
                ),

                const Spacer(),

                SlideTransition(
                  position: _problemSlide,
                  child: FadeTransition(
                    opacity: _problemFade,
                    child: AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (_, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnim.value, 0),
                          child: child,
                        );
                      },
                      child: AnimatedBuilder(
                        animation: _successAnim,
                        builder: (_, child) {
                          return Transform.scale(
                            scale: 1.0 + _successAnim.value * 0.04,
                            child: child,
                          );
                        },
                        child: _ProblemCard(
                          problem: _current,
                          input: _input,
                          negative: _negative,
                          error: _error,
                          timerEnabled: _timerEnabled,
                          timerSeconds: _taskSecondsLeft,
                          totalTimer: _ds.taskTimerSeconds ?? 1,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                _NumberPad(
                  onKeyTap: _onKey,
                  onSubmit: _trySubmit,
                  isDark: isDark,
                ),

                const SizedBox(height: 12),

                _BottomActions(
                  canSkip: _ds.mathAllowSkip,
                  onSkip: _skipProblem,
                  onStop: _trySubmit,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final int solved;
  final int total;
  final double progressFraction;
  final bool isDark;

  const _Header({
    required this.title,
    required this.solved,
    required this.total,
    required this.progressFraction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.large(context)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progressFraction),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor:
                            isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBlueGrey,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$solved / $total',
                style: AppTextStyles.caption(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Problem card
// ─────────────────────────────────────────────────────────────────────────────

class _ProblemCard extends StatelessWidget {
  final _Problem problem;
  final String input;
  final bool negative;
  final String? error;
  final bool timerEnabled;
  final int timerSeconds;
  final int totalTimer;
  final bool isDark;

  const _ProblemCard({
    required this.problem,
    required this.input,
    required this.negative,
    required this.error,
    required this.timerEnabled,
    required this.timerSeconds,
    required this.totalTimer,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final displayInput = input.isEmpty ? '?' : '${negative ? '−' : ''}$input';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkScaffold1.withOpacity(0.7)
                : Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              error != null
                  ? Colors.red.withOpacity(0.5)
                  : isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBlueGrey,
          width: error != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (timerEnabled) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: timerSeconds / totalTimer,
                minHeight: 4,
                backgroundColor:
                    isDark ? AppColors.darkBorder : AppColors.lightBlueGrey,
                valueColor: AlwaysStoppedAnimation<Color>(
                  timerSeconds <= 5 ? Colors.red : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.caption(context).copyWith(
                color: timerSeconds <= 5 ? Colors.red : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              child: Text('${timerSeconds}s'),
            ),
            const SizedBox(height: 20),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${problem.a} ${problem.symbol} ${problem.b} =',
                style: AppTextStyles.large(context).copyWith(fontSize: 32),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      error != null
                          ? Colors.red.withOpacity(0.08)
                          : AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        error != null
                            ? Colors.red.withOpacity(0.6)
                            : AppColors.primary.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  displayInput,
                  style: AppTextStyles.large(context).copyWith(
                    fontSize: 32,
                    color: error != null ? Colors.red : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child:
                error != null
                    ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error!,
                        style: AppTextStyles.caption(
                          context,
                        ).copyWith(color: Colors.red),
                      ),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Number pad
// ─────────────────────────────────────────────────────────────────────────────

class _NumberPad extends StatelessWidget {
  final void Function(String) onKeyTap;
  final VoidCallback onSubmit;
  final bool isDark;

  const _NumberPad({
    required this.onKeyTap,
    required this.onSubmit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Widget key(String label, {Color? bg, Color? fg}) {
      final isAction = bg != null;

      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Material(
            color:
                bg ??
                (isDark
                    ? AppColors.darkScaffold1.withOpacity(0.8)
                    : Colors.white.withOpacity(0.85)),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                onKeyTap(label);
              },
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border:
                      isAction
                          ? null
                          : Border.all(
                            color:
                                isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBlueGrey,
                          ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label == 'DEL' ? '⌫' : label,
                  style: AppTextStyles.large(context).copyWith(
                    fontSize: 22,
                    color:
                        fg ??
                        (isDark
                            ? AppColors.darkBackgroundText
                            : AppColors.lightBackgroundText),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(children: [key('1'), key('2'), key('3')]),
          Row(children: [key('4'), key('5'), key('6')]),
          Row(children: [key('7'), key('8'), key('9')]),
          Row(
            children: [
              key(
                '±',
                bg: AppColors.primary.withOpacity(0.15),
                fg: AppColors.primary,
              ),
              key('0'),
              key('DEL', bg: Colors.red.withOpacity(0.12), fg: Colors.red),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom actions
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final bool canSkip;
  final VoidCallback onSkip;
  final VoidCallback onStop;

  const _BottomActions({
    required this.canSkip,
    required this.onSkip,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    if (!canSkip) {
      return Center(
        child: GestureDetector(onTap: onStop, child: const StopButton()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: onSkip,
            icon: const Icon(Icons.skip_next_outlined, size: 18),
            label: const Text('Skip'), // TODO: localize
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
          ),

          GestureDetector(onTap: onStop, child: const StopButton()),

          // Keeps the Stop button visually centered when skip exists on the left.
          const SizedBox(width: 80),
        ],
      ),
    );
  }
}
