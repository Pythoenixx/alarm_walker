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
    return 'Snooze ${snooze.durationMinutes} min · max $max';
  }

  Color _mutedColor(bool isDark) {
    return isDark
        ? AppColors.darkBackgroundText.withValues(alpha: 0.52)
        : AppColors.lightBackgroundText.withValues(alpha: 0.52);
  }

  Widget _metaPill({
    required IconData icon,
    required String label,
    required bool isDark,
    required bool active,
    Color? color,
  }) {
    final accent = active ? (color ?? AppColors.primary) : _mutedColor(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: active ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: active ? 0.20 : 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption(context).copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconBadge({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required bool active,
    Color? color,
  }) {
    final accent = active ? (color ?? AppColors.primary) : _mutedColor(isDark);
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: active ? 0.10 : 0.06),
          border: Border.all(color: accent.withValues(alpha: active ? 0.18 : 0.10)),
        ),
        child: Icon(icon, size: 15, color: accent),
      ),
    );
  }

  Widget _largeSwitchHitBox() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final next = !_enabled;
        setState(() => _enabled = next);
        widget.onEnabledChanged(next);
      },
      child: SizedBox(
        width: 64,
        height: 48,
        child: Center(
          child: Transform.scale(
            scale: 1.12,
            child: AbsorbPointer(
              child: GradientSwitch(value: _enabled, onChanged: (_) {}),
            ),
          ),
        ),
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
                                Text(
                                  time,
                                  style: AppTextStyles.bigTime(context).copyWith(
                                    color:
                                        _enabled
                                            ? null
                                            : _mutedColor(isDark),
                                  ),
                                ),
                                if (alarm.title.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    alarm.title.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption(context).copyWith(
                                      color:
                                          _enabled
                                              ? isDark
                                                  ? AppColors.darkBackgroundText
                                                  : AppColors.lightBackgroundText
                                              : _mutedColor(isDark),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _largeSwitchHitBox(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _metaPill(
                            icon: _dismissModeIcon(alarm.dismissSettings.mode),
                            label: _dismissModeLabel(alarm.dismissSettings.mode),
                            isDark: isDark,
                            active: _enabled && !isPausedByVacation,
                          ),
                          _metaPill(
                            icon:
                                alarm.isOnce
                                    ? Icons.looks_one_outlined
                                    : Icons.repeat_rounded,
                            label: _repeatLabel(),
                            isDark: isDark,
                            active: _enabled && !isPausedByVacation,
                          ),
                          _iconBadge(
                            icon:
                                alarm.snoozeSettings.enabled
                                    ? Icons.snooze_outlined
                                    : Icons.snooze_rounded,
                            tooltip: _snoozeLabel(),
                            isDark: isDark,
                            active: _enabled && alarm.snoozeSettings.enabled,
                          ),
                          if (isPausedByVacation)
                            _metaPill(
                              icon: Icons.beach_access_outlined,
                              label: 'Vacation paused',
                              isDark: isDark,
                              active: true,
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
