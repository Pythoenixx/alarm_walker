import 'package:alarm/alarm.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/services/adaptive_difficulty_service.dart';
import 'package:alarm_walker/services/alarm_cubit.dart';
import 'package:alarm_walker/services/profile_cubit.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

Future<void> dismissActiveAlarmAndClose({
  required BuildContext context,
  required AlarmSettings alarmSettings,
  required AlarmModel alarmModel,
  AlarmResult result = AlarmResult.success,
}) async {
  final alarmCubit = context.read<AlarmCubit>();
  final settingsCubit = context.read<SettingsCubit>();
  final profileCubit = context.read<ProfileCubit>();

  final alarmRef = ActiveAlarmRef.from(
    alarmSettings: alarmSettings,
    alarmModel: alarmModel,
  );

  await alarmCubit.finishRingingAlarm(alarmRef: alarmRef, result: result);

  final shouldAdapt =
      result == AlarmResult.success &&
      settingsCubit.state.adaptiveDifficultyEnabled;

  if (shouldAdapt) {
    final category = profileCubit.state?.profileCategory ?? ProfileCategory.fallback;

    await AdaptiveDifficultyService.evaluateAndApply(
      wakeRepo: alarmCubit.wakeLogRepo,
      settingsCubit: settingsCubit,
      category: category,
    );
  }

  if (context.mounted) {
    context.pop();
  }
}
