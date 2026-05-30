import 'package:alarm_walker/app_router.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/gradient_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AlarmTile extends StatefulWidget {
  final AlarmModel alarmModel;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<List<int>> onDaysChanged;
  final VoidCallback onDelete;

  const AlarmTile({
    super.key,
    required this.alarmModel,
    required this.onEnabledChanged,
    required this.onDaysChanged,
    required this.onDelete,
  });

  @override
  State<AlarmTile> createState() => _AlarmTileState();
}

class _AlarmTileState extends State<AlarmTile> {
  late bool _enabled;
  late Set<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    _enabled = widget.alarmModel.enabled;
    _selectedDays = widget.alarmModel.days.toSet();
  }

  @override
  void didUpdateWidget(covariant AlarmTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _enabled = widget.alarmModel.enabled;
    _selectedDays = widget.alarmModel.days.toSet();
  }

  String _repeatLabel() {
    if (widget.alarmModel.isOnce) return 'One-time';
    if (_selectedDays.isEmpty) return 'No repeat days';

    const dayLabels = {
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };

    final ordered = [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    ];

    if (_selectedDays.length == 7) return 'Every day';
    if (_selectedDays.length == 5 &&
        _selectedDays.containsAll([
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
        ])) {
      return 'Weekdays';
    }

    return ordered
        .where(_selectedDays.contains)
        .map((day) => dayLabels[day]!)
        .join(' · ');
  }

  IconData _dismissModeIcon(AlarmDisarmMode mode) {
    return switch (mode) {
      AlarmDisarmMode.normal => Icons.alarm_off_outlined,
      AlarmDisarmMode.walk => Icons.directions_walk_outlined,
      AlarmDisarmMode.math => Icons.calculate_outlined,
      AlarmDisarmMode.shake => Icons.vibration,
      AlarmDisarmMode.retype => Icons.keyboard_outlined,
    };
  }

  String _dismissModeLabel(AlarmDisarmMode mode) {
    return switch (mode) {
      AlarmDisarmMode.normal => 'Normal',
      AlarmDisarmMode.walk => 'Walk',
      AlarmDisarmMode.math => 'Math',
      AlarmDisarmMode.shake => 'Shake',
      AlarmDisarmMode.retype => 'Retype',
    };
  }

  String _snoozeLabel() {
    final snooze = widget.alarmModel.snoozeSettings;
    if (!snooze.enabled) return 'Snooze off';
    final max = snooze.maxCount == 0 ? '∞' : '${snooze.maxCount}×';
    return '${snooze.durationMinutes} min · max $max';
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required bool isDark,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: chipColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color:
                    isDark
                        ? AppColors.darkBackgroundText
                        : AppColors.lightBackgroundText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final settings = context.watch<SettingsCubit>().state;
    final bool use24h = settings.use24HourFormat;
    final vacationMode = settings.vacationModeEnabled;
    final alarm = widget.alarmModel;
    final isPausedByVacation = vacationMode && _enabled;

    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      alarm.time,
      alwaysUse24HourFormat: use24h,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [AppColors.darkBorder, AppColors.darkScaffold2]
                    : [Colors.white, AppColors.lightScaffold2],
          ),
          boxShadow:
              isDark
                  ? [
                    BoxShadow(
                      offset: const Offset(-5, -5),
                      blurRadius: 20,
                      color: AppColors.darkGrey.withValues(alpha: 0.35),
                    ),
                    BoxShadow(
                      offset: const Offset(13, 14),
                      blurRadius: 12,
                      spreadRadius: -6,
                      color: AppColors.shadowDark.withValues(alpha: 0.70),
                    ),
                  ]
                  : [
                    BoxShadow(
                      offset: const Offset(-5, -5),
                      blurRadius: 20,
                      color: Colors.white.withValues(alpha: 0.53),
                    ),
                    BoxShadow(
                      offset: const Offset(13, 14),
                      blurRadius: 12,
                      spreadRadius: -6,
                      color: AppColors.shadowLight.withValues(alpha: 0.57),
                    ),
                  ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    isDark
                        ? [AppColors.darkClock1, AppColors.darkScaffold1]
                        : [AppColors.lightScaffold1, AppColors.lightGradient2],
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap:
                    () => context.pushNamed(
                      AppRoute.addAlarm.name,
                      extra: alarm,
                    ),
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(time, style: AppTextStyles.bigTime(context)),
                                if (alarm.title.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    alarm.title.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption(context).copyWith(
                                      color:
                                          isDark
                                              ? AppColors.darkBackgroundText
                                              : AppColors.lightBackgroundText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GradientSwitch(
                            value: _enabled,
                            onChanged: (v) {
                              setState(() => _enabled = v);
                              widget.onEnabledChanged(v);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _infoChip(
                            icon: _dismissModeIcon(alarm.dismissSettings.mode),
                            label: _dismissModeLabel(alarm.dismissSettings.mode),
                            isDark: isDark,
                          ),
                          _infoChip(
                            icon:
                                alarm.isOnce
                                    ? Icons.looks_one_outlined
                                    : Icons.repeat_rounded,
                            label: _repeatLabel(),
                            isDark: isDark,
                            color: alarm.isOnce ? Colors.deepPurple : null,
                          ),
                          _infoChip(
                            icon: Icons.music_note_outlined,
                            label: alarm.soundSettings.soundName ?? 'Default',
                            isDark: isDark,
                            color: Colors.indigo,
                          ),
                          _infoChip(
                            icon: Icons.snooze_outlined,
                            label: _snoozeLabel(),
                            isDark: isDark,
                            color: Colors.orange,
                          ),
                          if (!_enabled)
                            _infoChip(
                              icon: Icons.pause_circle_outline,
                              label: 'Disabled',
                              isDark: isDark,
                              color: Colors.grey,
                            ),
                          if (isPausedByVacation)
                            _infoChip(
                              icon: Icons.beach_access_outlined,
                              label: 'Paused by vacation mode',
                              isDark: isDark,
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
