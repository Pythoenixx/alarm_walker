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
  late final bool _caseSensitive;
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _isCorrect = false;

  static const String _letters =
      'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  static const String _numbers = '23456789';
  static const String _symbols = '!@#?._-';

  // Empty Retype text now creates a fresh phrase per alarm session.
  // The generated length follows mathDifficulty so adaptive difficulty can
  // still make Retype lighter or firmer without adding another setting field.
  String _generateRandomPhrase() {
    final difficulty = widget.alarmModel.dismissSettings.mathDifficulty;
    final length = switch (difficulty) {
      <= 1 => 10,
      2 => 12,
      _ => 14,
    };
    final rnd = Random();
    final requiredChars = <String>[
      _pick(rnd, _letters.toUpperCase()),
      _pick(rnd, _letters.toLowerCase()),
      _pick(rnd, _numbers),
      _pick(rnd, _symbols),
    ];
    final allChars = _letters + _numbers + _symbols;
    while (requiredChars.length < length) {
      requiredChars.add(_pick(rnd, allChars));
    }
    requiredChars.shuffle(rnd);
    return requiredChars.join();
  }

  String _pick(Random rnd, String source) => source[rnd.nextInt(source.length)];

  @override
  void initState() {
    super.initState();
    final configuredText = widget.alarmModel.dismissSettings.reTypeText.trim();
    _targetSentence =
        configuredText.isNotEmpty ? configuredText : _generateRandomPhrase();
    _caseSensitive = widget.alarmModel.dismissSettings.reTypeCaseSensitive;
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
    final target = _targetSentence.trim();
    final isMatch =
        _caseSensitive
            ? input == target
            : input.toLowerCase() == target.toLowerCase();

    if (isMatch) {
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
      unawaited(
        recordFailedDisarmAttemptForActiveAlarm(
          context: context,
          alarmSettings: widget.alarmSettings,
          alarmModel: widget.alarmModel,
        ),
      );

      setState(() {
        _error = context.tr(
          _caseSensitive
              ? 'Incorrect! Please type the sentence exactly as shown.'
              : 'Incorrect! Please match the sentence. Capital letters are optional.',
        );
        _isCorrect = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compactLayout = screenHeight < 720 || textScale > 1.15;
    final pagePadding = compactLayout ? 16.0 : 24.0;
    final largeGap = compactLayout ? 20.0 : 36.0;
    final mediumGap = compactLayout ? 14.0 : 22.0;
    final inputMaxLines = compactLayout ? 2 : 3;

    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.all(pagePadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (pagePadding * 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                        SizedBox(height: largeGap),
                        Text(
                          context.tr('Type this sentence to dismiss:'),
                          style: AppTextStyles.large(context).copyWith(
                            fontSize: compactLayout ? 15 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: mediumGap),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(compactLayout ? 14 : 16),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? AppColors.darkScaffold1.withValues(
                                      alpha: 0.5,
                                    )
                                    : AppColors.lightContainer1,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBlueGrey,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _targetSentence,
                              style: AppTextStyles.large(context).copyWith(
                                fontSize: compactLayout ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(height: mediumGap),
                        TextField(
                          controller: _controller,
                          autofocus: true,
                          minLines: 1,
                          maxLines: inputMaxLines,
                          style: AppTextStyles.large(
                            context,
                          ).copyWith(fontSize: compactLayout ? 15 : 16),
                          decoration: InputDecoration(
                            hintText: context.tr('Type here...'),
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
                                color:
                                    _isCorrect
                                        ? Colors.green
                                        : AppColors.primary,
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
                          Text(
                            context.tr('✓ Correct!'),
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        SizedBox(height: mediumGap),
                        GestureDetector(
                          onTap: _tryStop,
                          child: const StopButton(),
                        ),
                        SizedBox(height: compactLayout ? 16 : 28),
                        Text(
                          context.tr(
                            _caseSensitive
                                ? 'Match capitalization and punctuation exactly'
                                : 'Match the words and punctuation shown',
                          ),
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
