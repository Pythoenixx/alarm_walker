import 'dart:async';
import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/services/alarm_dismiss_helper.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/stop_alarm.dart';
import 'package:flutter/material.dart';

class RetypeAlarmScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;
  final AlarmModel alarmModel;

  const RetypeAlarmScreen({
    super.key,
    required this.alarmSettings,
    required this.alarmModel,
  });

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
    'k9!2z.Q7@4m',
    'v8?P1@x5.R3',
    '2!mZ.9q@7B',
    'x6.1V@p9?3k',
    '7L@4n.8j!1w',
    'b3?9m.V1@6z',
    '4k.7Q!2w@8p',
    '9!5z.R2@1x',
    'm7@3k.V9?4j',
    '1q.8Z!5p@2n',
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

      if (!mounted) return;

      await dismissActiveAlarmAndClose(
        context: context,
        alarmSettings: widget.alarmSettings,
        alarmModel: widget.alarmModel,
      );
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
                              ? AppColors.darkScaffold1.withValues(alpha: 0.5)
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
                              ? AppColors.darkBackgroundText.withValues(
                                alpha: 0.6,
                              )
                              : AppColors.lightBackgroundText.withValues(
                                alpha: 0.6,
                              ),
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
