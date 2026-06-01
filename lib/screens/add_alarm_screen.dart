import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/dismiss_settings.dart';
import 'package:alarm_walker/models/snooze_settings.dart';
import 'package:alarm_walker/models/sound_settings.dart';
import 'package:alarm_walker/screens/dismiss_settings_screen.dart';
import 'package:alarm_walker/screens/snooze_settings_screen.dart';
import 'package:alarm_walker/screens/sound_settings_screen.dart';
import 'package:alarm_walker/services/alarm_cubit.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/add_button.dart';
import 'package:alarm_walker/widgets/gradient_switch.dart';
import 'package:alarm_walker/widgets/time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AddAlarmScreen extends StatefulWidget {
  final AlarmModel? alarmModel;

  const AddAlarmScreen({super.key, this.alarmModel});

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  late TimeOfDay _selectedTime;
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late Set<int> _selectedDays;
  late SnoozeSettings _snoozeSettings;
  late SoundSettings _soundSettings;
  late DismissSettings _dismissSettings;
  late bool _wakeupCheck;
  late bool _isOneTime;
  late String _initialSignature;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    if (widget.alarmModel != null) {
      final m = widget.alarmModel!;
      _selectedTime = m.time;
      _selectedDays = m.days.toSet();
      _titleController.text = m.title;
      _snoozeSettings = m.snoozeSettings;
      _soundSettings = m.soundSettings;
      _dismissSettings = m.dismissSettings;
      // Wakeup check is currently hidden from the UI because it is not part of
      // the focused SRS/demo flow. Keep saved alarms on the stable default.
      _wakeupCheck = false;
      _isOneTime = m.isOnce;
    } else {
      _selectedTime = TimeOfDay.now();
      _selectedDays = <int>{
        DateTime.sunday,
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
      };
      final appDefaults = context.read<SettingsCubit>().state;

      _snoozeSettings = appDefaults.defaultSnoozeSettings;
      _soundSettings = appDefaults.defaultSoundSettings;
      _dismissSettings = appDefaults.defaultDismissSettings;
      _wakeupCheck = false;
      _isOneTime = false;
    }

    _initialSignature = _currentSignature();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _currentSignature() {
    final sortedDays = _selectedDays.toList()..sort();
    return [
      _selectedTime.hour,
      _selectedTime.minute,
      _titleController.text,
      _isOneTime,
      sortedDays.join(','),
      _snoozeSettings.toJson(),
      _soundSettings.toJson(),
      _dismissSettings.toJson(),
      _wakeupCheck,
    ].join('|');
  }

  bool get _hasUnsavedChanges => _currentSignature() != _initialSignature;

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges) return true;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
              'You have unsaved alarm changes. Save the alarm to keep them, or discard to leave this page.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _leaveIfSafe() async {
    final canLeave = await _confirmDiscardChanges();
    if (!mounted || !canLeave) return;

    setState(() => _allowPop = true);
    context.pop();
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _addAlarm() async {
    final title = _titleController.text.trim();
    final cubit = context.read<AlarmCubit>();
    final days = _isOneTime ? <int>[] : _selectedDays.toList();

    if (!_isOneTime && days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one repeat day.'),
        ),
      );
      return;
    }

    await cubit.setPeriodicAlarms(
      alarmId: widget.alarmModel?.alarmId,
      timeOfDay: _selectedTime,
      days: days,
      title: title,
      snoozeSettings: _snoozeSettings,
      soundSettings: _soundSettings,
      dismissSettings: _dismissSettings,
      wakeupCheck: _wakeupCheck,
      isOnce: _isOneTime,
    );

    if (mounted) {
      _initialSignature = _currentSignature();
      setState(() => _allowPop = true);
      context.pop();
    }
  }

  Future<void> _deleteAlarm() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(context.localization.deleteAlarm),
                content: Text(context.localization.deleteAlarmPrompt),
                actions: [
                  TextButton(
                    onPressed: () => context.pop(false),
                    child: Text(context.localization.cancel),
                  ),
                  TextButton(
                    onPressed: () => context.pop(true),
                    child: Text(context.localization.delete),
                  ),
                ],
              ),
        ) ??
        false;

    if (!mounted || !confirmed) return;

    await context.read<AlarmCubit>().deleteAlarmModel(widget.alarmModel!);
    if (mounted) {
      setState(() => _allowPop = true);
      context.pop();
    }
  }

  Future<void> _openSoundSettings() async {
    final result = await Navigator.of(context).push<SoundSettings>(
      MaterialPageRoute(
        builder: (_) => SoundSettingsScreen(initial: _soundSettings),
      ),
    );
    if (result != null) setState(() => _soundSettings = result);
  }

  Future<void> _openDismissSettings() async {
    final result = await Navigator.of(context).push<DismissSettings>(
      MaterialPageRoute(
        builder: (_) => DismissSettingsScreen(initial: _dismissSettings),
      ),
    );
    if (result != null) setState(() => _dismissSettings = result);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.caption(context).copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: isDark ? AppColors.darkBorder : AppColors.lightBlueGrey,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _iconBox(icon),
      title: Text(title, style: AppTextStyles.body(context)),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption(context).copyWith(
          color:
              isDark
                  ? AppColors.darkBackgroundText
                  : AppColors.lightBackgroundText,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color:
            isDark
                ? AppColors.darkBackgroundText
                : AppColors.lightBackgroundText,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _iconBox(icon),
      title: Text(title, style: AppTextStyles.body(context)),
      subtitle:
          subtitle != null
              ? Text(subtitle, style: AppTextStyles.caption(context))
              : null,
      trailing: GradientSwitch(value: value, onChanged: onChanged),
    );
  }


  Widget _alarmTypeSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color:
              isDark
                  ? AppColors.darkScaffold2.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBlueGrey,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _alarmTypeButton(
                icon: Icons.repeat_rounded,
                label: 'Repeat',
                selected: !_isOneTime,
                onTap: () {
                  setState(() {
                    _isOneTime = false;
                    if (_selectedDays.isEmpty) {
                      _selectedDays = <int>{
                        DateTime.monday,
                        DateTime.tuesday,
                        DateTime.wednesday,
                        DateTime.thursday,
                        DateTime.friday,
                      };
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _alarmTypeButton(
                icon: Icons.looks_one_outlined,
                label: 'One-time',
                selected: _isOneTime,
                onTap: () {
                  setState(() {
                    _isOneTime = true;
                    _selectedDays = <int>{};
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alarmTypeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient:
              selected
                  ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryAlt],
                  )
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.caption(context).copyWith(
                color: selected ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _oneTimeInfoCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This alarm will ring once at the next matching time and then disable itself after successful dismiss.',
                style: AppTextStyles.caption(context).copyWith(
                  color:
                      isDark
                          ? AppColors.darkBackgroundText
                          : AppColors.lightBackgroundText,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }

  // replace _buildSnoozeSection() and _chipRow() with:
  Future<void> _openSnoozeSettings() async {
    final result = await Navigator.of(context).push<SnoozeSettings>(
      MaterialPageRoute(
        builder: (_) => SnoozeSettingsScreen(initial: _snoozeSettings),
      ),
    );
    if (result != null) setState(() => _snoozeSettings = result);
  }

  // ── day selector ───────────────────────────────────────────────────────────

  Widget _daySelector(bool isDark) {
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    // This map aligns your UI order (Sunday first) with Dart's DateTime constants
    const daysOrder = [
      DateTime.sunday, // 7
      DateTime.monday, // 1
      DateTime.tuesday, // 2
      DateTime.wednesday, // 3
      DateTime.thursday, // 4
      DateTime.friday, // 5
      DateTime.saturday, // 6
    ];

    final localizations = context.localization;
    final dayNames = [
      localizations.sunday,
      localizations.monday,
      localizations.tuesday,
      localizations.wednesday,
      localizations.thursday,
      localizations.friday,
      localizations.saturday,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // To use logic/variables inside a collection for,
        // we map the index to the widget.
        ...List.generate(dayLabels.length, (i) {
          final dayValue = daysOrder[i]; // Sunday is now 7, Saturday is 6

          return IconButton(
            tooltip: dayNames[i],
            onPressed: () => _toggleDay(dayValue), // Send the correct ID
            style: IconButton.styleFrom(
              backgroundColor:
                  _selectedDays.contains(dayValue) ? AppColors.primary : null,
              side:
                  _selectedDays.contains(dayValue)
                      ? BorderSide.none
                      : BorderSide(
                        color:
                            isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBlueGrey,
                      ),
            ),
            icon: Text(
              dayLabels[i],
              style: AppTextStyles.caption(context).copyWith(
                color:
                    _selectedDays.contains(dayValue)
                        ? Colors.white
                        : isDark
                        ? AppColors.darkBackgroundText
                        : AppColors.lightBackgroundText,
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final dismissMode = _dismissSettings.mode;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _leaveIfSafe();
      },
      child: GestureDetector(
        onTap: _focusNode.unfocus,
        child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBorder : Colors.white,
        appBar: AppBar(
          surfaceTintColor: Colors.transparent, // Prevents automatic tint
          scrolledUnderElevation: 0, // Prevents color shift on scroll
          backgroundColor:
              isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
          leading: IconButton(
            tooltip: context.localization.back,
            onPressed: _leaveIfSafe,
            style: IconButton.styleFrom(
              foregroundColor:
                  isDark
                      ? AppColors.darkBackgroundText
                      : AppColors.lightBackgroundText,
            ),
            icon: const Icon(Icons.arrow_back),
          ),
          actions:
              widget.alarmModel == null
                  ? null
                  : [
                    IconButton(
                      tooltip: context.localization.delete,
                      onPressed: _deleteAlarm,
                      style: IconButton.styleFrom(
                        foregroundColor:
                            isDark
                                ? AppColors.darkBackgroundText
                                : AppColors.lightBackgroundText,
                      ),
                      icon: const Icon(Icons.delete),
                    ),
                  ],
          centerTitle: true,
          title: Text(
            widget.alarmModel == null
                ? context.localization.addAlarm
                : context.localization.editAlarm,
          ),
          titleTextStyle: AppTextStyles.heading(context),
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
          child: Form(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      alwaysUse24HourFormat:
                          context.read<SettingsCubit>().state.use24HourFormat,
                    ),
                    child: TimePickerWidget(
                      initialTime: _selectedTime,
                      onTimeChanged: (time) {
                        setState(() => _selectedTime = time);
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _alarmTypeSelector(isDark),

                        if (_isOneTime)
                          _oneTimeInfoCard(isDark)
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _daySelector(isDark),
                          ),

                        // Title field
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: TextField(
                            controller: _titleController,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              labelText: context.localization.titleLabel,
                            ),
                            onSubmitted: (_) => _addAlarm(),
                          ),
                        ),

                        // ── Settings ──────────────────────────────────────
                        _buildSectionHeader(
                          'Settings',
                          isDark,
                        ), // TODO: localize

                        _buildNavRow(
                          icon: Icons.snooze,
                          title: 'Snooze', // TODO: localize
                          subtitle:
                              _snoozeSettings.enabled
                                  ? '${_snoozeSettings.durationMinutes} min · max ${_snoozeSettings.maxCount == 0 ? '∞' : '${_snoozeSettings.maxCount}×'}'
                                  : 'Off',
                          onTap: _openSnoozeSettings,
                          isDark: isDark,
                        ),

                        _buildNavRow(
                          icon: Icons.music_note_outlined,
                          title: 'Sound', // TODO: localize
                          subtitle: _soundSettings.soundName ?? 'Default',
                          onTap: _openSoundSettings,
                          isDark: isDark,
                        ),

                        _buildNavRow(
                          icon: _dismissModeIcon(dismissMode),
                          title: 'Dismiss', // TODO: localize
                          subtitle: _dismissModeLabel(dismissMode),
                          onTap: _openDismissSettings,
                          isDark: isDark,
                        ),


                        // Save button
                        IconButton(
                          tooltip:
                              widget.alarmModel == null
                                  ? context.localization.addAlarm
                                  : context.localization.editAlarm,
                          onPressed: _addAlarm,
                          icon: const AddButton(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.paddingOf(context).bottom),
              ],
            ),
          ),
        ),
      ),
      ),
    );
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
      AlarmDisarmMode.normal => 'Normal', // TODO: localize all
      AlarmDisarmMode.walk => 'Walk ${_dismissSettings.walkSteps} steps',
      AlarmDisarmMode.math =>
        'Math · ${['Easy', 'Medium', 'Hard'][_dismissSettings.mathDifficulty - 1]}',
      AlarmDisarmMode.shake => 'Shake ${_dismissSettings.shakeCount}×',
      AlarmDisarmMode.retype => 'Retype phrase',
    };
  }
}
