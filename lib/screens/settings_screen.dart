// import 'dart:async';

import 'package:alarm_walker/app_router.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/services/alarm_cubit.dart';
// import 'package:alarm_walker/services/alarm_permissions.dart';
import 'package:alarm_walker/services/custom_sounds_cubit.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/gradient_slider.dart';
import 'package:alarm_walker/widgets/gradient_switch.dart';
import 'package:alarm_walker/widgets/settings_tile.dart';
import 'package:alarm_walker/widgets/theme_list_tile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// import 'package:path/path.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBorder : Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor:
            isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
        leading: IconButton(
          tooltip: context.localization.back,
          onPressed: () => context.pop(),
          style: IconButton.styleFrom(
            foregroundColor:
                isDark
                    ? AppColors.darkBackgroundText
                    : AppColors.lightBackgroundText,
          ),
          icon: const Icon(Icons.arrow_back),
        ),
        centerTitle: true,
        title: Text(context.localization.settings),
        titleTextStyle: AppTextStyles.heading(context),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );

              if (confirmed == true && context.mounted) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  context.goNamed(AppRoute.login.name);
                }
              }
            },
            style: IconButton.styleFrom(
              foregroundColor:
                  isDark
                      ? AppColors.darkBackgroundText
                      : AppColors.lightBackgroundText,
            ),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? [AppColors.darkScaffold1, AppColors.darkScaffold2]
                    : [AppColors.lightContainer1, AppColors.lightContainer2],
          ),
        ),
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            final color =
                isDark
                    ? AppColors.darkBackgroundText
                    : AppColors.lightBackgroundText;
            return ListView(
              padding: const EdgeInsets.all(10),
              children: [
                ThemeListTile(
                  mode: state.mode,
                  onChanged: (m) => context.read<SettingsCubit>().setTheme(m),
                ),
                const SizedBox(height: 23),
                SettingsTile(
                  onTap:
                      () => context.read<SettingsCubit>().setUse24HourFormat(
                        !state.use24HourFormat,
                      ),
                  child: Row(
                    children: [
                      Text(
                        context.localization.format24h,
                        style: AppTextStyles.body(
                          context,
                        ).copyWith(color: color),
                      ),
                      const Spacer(),
                      GradientSwitch(
                        value: state.use24HourFormat,
                        onChanged:
                            (v) => context
                                .read<SettingsCubit>()
                                .setUse24HourFormat(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 23),
                SettingsTile(
                  onTap: () async {
                    final settingsCubit = context.read<SettingsCubit>();
                    final alarmCubit = context.read<AlarmCubit>();
                    final newValue = !state.vibrationEnabled;
                    await settingsCubit.setVibrationEnabled(newValue);
                    await alarmCubit.updateVibrationForAll(newValue);
                  },
                  child: Row(
                    children: [
                      Text(
                        context.localization.vibration,
                        style: AppTextStyles.body(
                          context,
                        ).copyWith(color: color),
                      ),
                      const Spacer(),
                      GradientSwitch(
                        value: state.vibrationEnabled,
                        onChanged: (v) async {
                          final settingsCubit = context.read<SettingsCubit>();
                          final alarmCubit = context.read<AlarmCubit>();
                          await settingsCubit.setVibrationEnabled(v);
                          await alarmCubit.updateVibrationForAll(v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 23),
                SettingsTile(
                  onTap: () async {
                    final settingsCubit = context.read<SettingsCubit>();
                    final alarmCubit = context.read<AlarmCubit>();
                    final newValue = !state.fadeInAlarm;
                    await settingsCubit.setFadeInAlarm(newValue);
                    await alarmCubit.updateVolumeSettingsForAll(
                      fadeIn: newValue,
                      volume: state.alarmVolume,
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        context.localization.fadeIn,
                        style: AppTextStyles.body(
                          context,
                        ).copyWith(color: color),
                      ),
                      const Spacer(),
                      GradientSwitch(
                        value: state.fadeInAlarm,
                        onChanged: (v) async {
                          final settingsCubit = context.read<SettingsCubit>();
                          final alarmCubit = context.read<AlarmCubit>();
                          await settingsCubit.setFadeInAlarm(v);
                          await alarmCubit.updateVolumeSettingsForAll(
                            fadeIn: v,
                            volume: state.alarmVolume,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 23),
                SettingsTile(
                  child: Row(
                    children: [
                      Text(
                        context.localization.alarmScreen,
                        style: AppTextStyles.body(
                          context,
                        ).copyWith(color: color),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: DropdownButton<AlarmDisarmMode>(
                          value: state.alarmDisarmMode,
                          underline: const SizedBox(),
                          isExpanded: true,
                          dropdownColor:
                              isDark
                                  ? AppColors.darkScaffold1
                                  : AppColors.lightScaffold1,
                          items: [
                            DropdownMenuItem(
                              value: AlarmDisarmMode.normal,
                              child: Text(context.localization.defaultOption),
                            ),
                            DropdownMenuItem(
                              value: AlarmDisarmMode.math,
                              child: Text(context.localization.mathChallenge),
                            ),
                            DropdownMenuItem(
                              value: AlarmDisarmMode.shake,
                              child: Text(context.localization.shakeToStop),
                            ),
                            DropdownMenuItem(
                              value: AlarmDisarmMode.retype,
                              child: Text(context.localization.retypeToStop),
                            ),
                            DropdownMenuItem(
                              value: AlarmDisarmMode.walk,
                              child: Text(context.localization.walkToStop),
                            ),
                          ],
                          onChanged: (v) async {
                            if (v == null) return;
                            if (!context.mounted) return;
                            await context
                                .read<SettingsCubit>()
                                .setAlarmDisarmMode(v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 23),
                SettingsTile(
                  onTap: () => context.pushNamed(AppRoute.database.name),
                  child: Row(
                    children: [
                      Text(
                        context.localization.database,
                        style: AppTextStyles.body(
                          context,
                        ).copyWith(color: color),
                      ),
                      // const Spacer(),
                      // GradientSwitch(
                      //   value: state.vibrationEnabled,
                      //   onChanged: (v) async {
                      //     final settingsCubit = context.read<SettingsCubit>();
                      //     final alarmCubit = context.read<AlarmCubit>();
                      //     await settingsCubit.setVibrationEnabled(v);
                      //     await alarmCubit.updateVibrationForAll(v);
                      //   },
                      // ),
                    ],
                  ),
                ),
                const SizedBox(height: 23),
                SettingsTile(
                  child: Row(
                    children: [
                      Icon(
                        state.alarmVolume > 0.7
                            ? Icons.volume_up_rounded
                            : state.alarmVolume > 0.1
                            ? Icons.volume_down_rounded
                            : Icons.volume_mute_rounded,
                        color: color,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GradientSlider(
                          value: state.alarmVolume,
                          onChanged: (v) async {
                            final settingsCubit = context.read<SettingsCubit>();
                            final alarmCubit = context.read<AlarmCubit>();
                            await settingsCubit.setAlarmVolume(v);
                            await alarmCubit.updateVolumeSettingsForAll(
                              fadeIn: state.fadeInAlarm,
                              volume: v,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 23 + MediaQuery.viewPaddingOf(context).bottom),
              ],
            );
          },
        ),
      ),
    );
  }
}
