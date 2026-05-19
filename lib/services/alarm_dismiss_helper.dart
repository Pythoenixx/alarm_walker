import 'package:alarm/alarm.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/services/alarm_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

Future<void> dismissActiveAlarmAndClose({
  required BuildContext context,
  required AlarmSettings alarmSettings,
  required AlarmModel alarmModel,
  AlarmResult result = AlarmResult.success,
}) async {
  final cubit = context.read<AlarmCubit>();

  final alarmRef = ActiveAlarmRef.from(
    alarmSettings: alarmSettings,
    alarmModel: alarmModel,
  );

  await cubit.finishRingingAlarm(alarmRef: alarmRef, result: result);

  if (context.mounted) {
    context.pop();
  }
}
