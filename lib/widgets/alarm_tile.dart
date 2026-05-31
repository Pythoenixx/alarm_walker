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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: active ? 0.10 : 0.06),
          border: Border.all(
            color: accent.withValues(alpha: active ? 0.18 : 0.10),
          ),
        ),
        child: Icon(icon, size: 14, color: accent),
      ),
    );
  }

  Widget _repeatBadge({
    required bool isDark,
    required bool active,
  }) {
    final accent = active ? AppColors.primary : _mutedColor(isDark);
    return Tooltip(
      message: 'Repeat: ${_repeatLabel()}',
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: accent.withValues(alpha: active ? 0.10 : 0.06),
          border: Border.all(
            color: accent.withValues(alpha: active ? 0.18 : 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.alarmModel.isOnce
                  ? Icons.looks_one_outlined
                  : Icons.repeat_rounded,
              size: 14,
              color: accent,
            ),
            const SizedBox(width: 5),
            Text(
              _repeatLabel(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
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
        width: 72,
        height: 56,
        child: Center(
          child: Transform.scale(
            scale: 1.18,
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

    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(alarm.time, alwaysUse24HourFormat: use24h);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
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
                    () =>
                        context.pushNamed(AppRoute.addAlarm.name, extra: alarm),
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 78),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alarm.title.trim().isEmpty
                                  ? 'Alarm'
                                  : alarm.title.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption(context).copyWith(
                                color:
                                    _enabled
                                        ? isDark
                                            ? AppColors.darkBackgroundText
                                            : AppColors.lightBackgroundText
                                        : _mutedColor(isDark),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              time,
                              style: AppTextStyles.bigTime(context).copyWith(
                                height: 0.98,
                                color: _enabled ? null : _mutedColor(isDark),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 7,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _repeatBadge(
                                    isDark: isDark,
                                    active: _enabled && !isPausedByVacation,
                                  ),
                                  _iconBadge(
                                    icon: _dismissModeIcon(
                                      alarm.dismissSettings.mode,
                                    ),
                                    tooltip:
                                        'Dismiss mode: ${_dismissModeLabel(alarm.dismissSettings.mode)}',
                                    isDark: isDark,
                                    active: _enabled && !isPausedByVacation,
                                  ),
                                  _iconBadge(
                                    icon: Icons.music_note_outlined,
                                    tooltip:
                                        'Sound: ${alarm.soundSettings.soundName ?? 'Default'}',
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
                                    active:
                                        _enabled &&
                                        !isPausedByVacation &&
                                        alarm.snoozeSettings.enabled,
                                  ),
                                  if (isPausedByVacation)
                                    _iconBadge(
                                      icon: Icons.beach_access_outlined,
                                      tooltip: 'Vacation paused',
                                      isDark: isDark,
                                      active: true,
                                      color: Colors.orange,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _largeSwitchHitBox(),
                        ),
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
