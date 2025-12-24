import 'dart:async';
import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/services/alarm_cubit.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/stop_alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RetypeAlarmScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;
  const RetypeAlarmScreen({super.key, required this.alarmSettings});

  @override
  State<RetypeAlarmScreen> createState() => _RetypeAlarmScreenState();
}

class _RetypeAlarmScreenState extends State<RetypeAlarmScreen> {
  late final String _targetSentence;
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _isCorrect = false;

  // List of sentences to choose from
  static const List<String> _sentences = [
    'I am awake and ready to start my day',
    'Today is going to be a productive day',
    'I choose to be energized and focused',
    'Getting up early helps me achieve my goals',
    'I am grateful for this new morning',
    'Every morning is a fresh start',
    'I have the power to create a great day',
    'My morning routine sets the tone for success',
    'I am capable of accomplishing amazing things',
    'This is my time to shine and grow',
  ];

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    _targetSentence = _sentences[rnd.nextInt(_sentences.length)];
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _error = null;
      _isCorrect = false;
    });
  }

  Future<void> _tryStop() async {
    final input = _controller.text.trim();

    if (input == _targetSentence) {
      setState(() {
        _isCorrect = true;
        _error = null;
      });

      // Small delay to show success state
      await Future.delayed(const Duration(milliseconds: 300));

      await context.read<AlarmCubit>().stopAlarm(widget.alarmSettings.id);
      if (mounted) {
        context.pop();
      }
    } else {
      setState(() {
        _error = 'Incorrect! Please type the sentence exactly as shown.';
        _isCorrect = false;
      });
    }
  }

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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    widget.alarmSettings.notificationSettings.body,
                    style: AppTextStyles.large(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Type this sentence to dismiss:',
                    style: AppTextStyles.large(
                      context,
                    ).copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppColors.darkScaffold1.withOpacity(0.5)
                              : AppColors.lightContainer1,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBlueGrey,
                      ),
                    ),
                    child: Text(
                      _targetSentence,
                      style: AppTextStyles.large(context).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLines: 3,
                    style: AppTextStyles.large(context).copyWith(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Type here...',
                      filled: true,
                      fillColor:
                          isDark ? AppColors.darkScaffold1 : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBlueGrey,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBlueGrey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _isCorrect ? Colors.green : Colors.blue,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_isCorrect) ...[
                    const SizedBox(height: 12),
                    const Text(
                      '✓ Correct!',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  GestureDetector(onTap: _tryStop, child: const StopButton()),
                  const Spacer(),
                  Text(
                    'Match capitalization and punctuation exactly',
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.darkBackgroundText.withOpacity(0.6)
                              : AppColors.lightBackgroundText.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
