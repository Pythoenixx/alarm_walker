import 'package:alarm_walker/app_router.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/app_language.dart';
import 'package:alarm_walker/models/dismiss_settings.dart';
import 'package:alarm_walker/models/snooze_settings.dart';
import 'package:alarm_walker/models/sound_settings.dart';
import 'package:alarm_walker/screens/dismiss_settings_screen.dart';
import 'package:alarm_walker/screens/snooze_settings_screen.dart';
import 'package:alarm_walker/screens/sound_settings_screen.dart';
import 'package:alarm_walker/services/alarm_cubit.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:alarm_walker/services/reminder_notification_service.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/gradient_switch.dart';
import 'package:alarm_walker/widgets/settings_tile.dart';
import 'package:alarm_walker/widgets/theme_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted)
      setState(() => _version = 'v${info.version} (${info.buildNumber})');
  }

  // ── navigation helpers ─────────────────────────────────────────────────────

  Future<void> _openSoundDefaults(
    SettingsCubit cubit,
    SettingsState state,
  ) async {
    final result = await Navigator.of(context).push<SoundSettings>(
      MaterialPageRoute(
        builder:
            (_) => SoundSettingsScreen(initial: state.defaultSoundSettings),
      ),
    );
    if (result != null) await cubit.setDefaultSoundSettings(result);
  }

  Future<void> _openDismissDefaults(
    SettingsCubit cubit,
    SettingsState state,
  ) async {
    final result = await Navigator.of(context).push<DismissSettings>(
      MaterialPageRoute(
        builder:
            (_) => DismissSettingsScreen(initial: state.defaultDismissSettings),
      ),
    );
    if (result != null) await cubit.setDefaultDismissSettings(result);
  }

  Future<void> _openSnoozeDefaults(
    SettingsCubit cubit,
    SettingsState state,
  ) async {
    final result = await Navigator.of(context).push<SnoozeSettings>(
      MaterialPageRoute(
        builder:
            (_) => SnoozeSettingsScreen(initial: state.defaultSnoozeSettings),
      ),
    );
    if (result != null) await cubit.setDefaultSnoozeSettings(result);
  }


  Future<void> _openLanguagePicker(
    SettingsCubit cubit,
    SettingsState state,
  ) async {
    final result = await showDialog<AppLanguage>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr('Language')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  AppLanguage.values
                      .map(
                        (language) => RadioListTile<AppLanguage>(
                          value: language,
                          groupValue: state.appLanguage,
                          onChanged: (value) => Navigator.of(context).pop(value),
                          title: Text(context.tr(language.label)),
                          subtitle: Text(context.tr(language.description)),
                        ),
                      )
                      .toList(),
            ),
          ),
    );

    if (result != null) await cubit.setLanguage(result);
  }

  Future<void> _openBedtimePicker(
    SettingsCubit cubit,
    SettingsState state,
  ) async {
    final result = await showTimePicker(
      context: context,
      initialTime: state.bedtimeAlertTime,
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: state.use24HourFormat,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
    );

    if (result != null) {
      await cubit.setBedtimeAlertTime(result);
      await _syncReminderNotifications();
    }
  }

  Future<void> _syncReminderNotifications() async {
    final settings = context.read<SettingsCubit>().state;
    final alarms = context.read<AlarmCubit>().state;
    await ReminderNotificationService.sync(settings: settings, alarms: alarms);
  }

  Future<void> _setBedtimeAlertEnabled(SettingsCubit cubit, bool value) async {
    await cubit.setBedtimeAlertEnabled(value);
    await _syncReminderNotifications();
  }

  Future<void> _setWeekendReminderEnabled(SettingsCubit cubit, bool value) async {
    await cubit.setWeekendReminderEnabled(value);
    await _syncReminderNotifications();
  }

  Future<void> _setVacationModeEnabled(SettingsCubit cubit, bool value) async {
    await cubit.setVacationModeEnabled(value);
    await context.read<AlarmCubit>().reloadForCurrentOwner();
    await _syncReminderNotifications();
  }

  Future<void> _setStickyAlarmNotificationEnabled(
    SettingsCubit cubit,
    bool value,
  ) async {
    await cubit.setStickyAlarmTimeEnabled(value);
    await _syncReminderNotifications();
  }

  // ── permissions ────────────────────────────────────────────────────────────

  Future<void> _showPermissionsSheet() async {
    final notification = await Permission.notification.status;
    final exactAlarm = await Permission.scheduleExactAlarm.status;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _PermissionsSheet(
            notificationStatus: notification,
            exactAlarmStatus: exactAlarm,
          ),
    );
  }

  // ── about ──────────────────────────────────────────────────────────────────

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Alarm Walker',
      applicationVersion: _version,
      applicationLegalese: '© ${DateTime.now().year} Alarm Walker',
    );
  }

  Future<void> _replayOnboarding() async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr('Replay onboarding')),
            content: Text(
              context.tr('This will show the introduction screens again. Your alarms, settings, and wake-up logs will not be deleted.'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.tr('Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(context.tr('Replay')),
              ),
            ],
          ),
    );

    if (!mounted || shouldOpen != true) return;

    context.pushNamed(AppRoute.onboarding.name);
  }



  // ── build ──────────────────────────────────────────────────────────────────

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
            final cubit = context.read<SettingsCubit>();
            return ListView(
              padding: EdgeInsets.fromLTRB(
                12,
                12,
                12,
                12 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              children: [
                // ── Appearance ───────────────────────────────────────────
                _SectionHeader(
                  label: context.tr('Appearance'),
                  isDark: isDark,
                ), // TODO: localize
                ThemeListTile(
                  mode: state.themeMode,
                  onChanged: (m) => cubit.setTheme(m),
                ),
                const SizedBox(height: 8),
                SettingsTile(
                  onTap: () => _openLanguagePicker(cubit, state),
                  child: _NavRow(
                    icon: Icons.translate_outlined,
                    label: context.tr('Language'),
                    subtitle: context.tr(state.appLanguage.label),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 8),
                SettingsTile(
                  onTap: () => cubit.setUse24HourFormat(!state.use24HourFormat),
                  child: _SwitchRow(
                    label: context.localization.format24h,
                    value: state.use24HourFormat,
                    onChanged: cubit.setUse24HourFormat,
                    isDark: isDark,
                  ),
                ),

                // ── Weather-aware wake-up ────────────────────────────────
                _SectionHeader(
                  label: context.tr('Weather-aware wake-up'),
                  isDark: isDark,
                ), // TODO: localize
                SettingsTile(
                  onTap:
                      () => cubit.setWeatherAwareEnabled(
                        !state.weatherAwareEnabled,
                      ),
                  child: _SwitchRow(
                    label: context.tr('Show weather messages'),
                    value: state.weatherAwareEnabled,
                    onChanged: cubit.setWeatherAwareEnabled,
                    isDark: isDark,
                  ),
                ),
                // ── Adaptive difficulty ──────────────────────────────
                _SectionHeader(
                  label: context.tr('Adaptive difficulty'),
                  isDark: isDark,
                ), // TODO: localize
                SettingsTile(
                  onTap:
                      () => cubit.setAdaptiveDifficultyEnabled(
                        !state.adaptiveDifficultyEnabled,
                      ),
                  child: _SwitchRow(
                    label: context.tr('Adjust future alarm defaults'),
                    value: state.adaptiveDifficultyEnabled,
                    onChanged: cubit.setAdaptiveDifficultyEnabled,
                    isDark: isDark,
                  ),
                ),

                // ── Reminder options ─────────────────────────────────────
                _SectionHeader(
                  label: context.tr('Reminder options'),
                  isDark: isDark,
                ), // TODO: localize
                SettingsTile(
                  onTap:
                      () => _setBedtimeAlertEnabled(
                        cubit,
                        !state.bedtimeAlertEnabled,
                      ),
                  child: _SwitchRow(
                    label: context.tr('Bedtime alert'),
                    subtitle: context.tr('Remind me to prepare for sleep and check alarms.'),
                    value: state.bedtimeAlertEnabled,
                    onChanged: (value) => _setBedtimeAlertEnabled(cubit, value),
                    isDark: isDark,
                  ),
                ),
                if (state.bedtimeAlertEnabled) ...[
                  const SizedBox(height: 8),
                  SettingsTile(
                    onTap: () => _openBedtimePicker(cubit, state),
                    child: _NavRow(
                      icon: Icons.bedtime_outlined,
                      label: context.tr('Bedtime reminder time'),
                      subtitle: _formatTime(state.bedtimeAlertTime, state),
                      isDark: isDark,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SettingsTile(
                  onTap:
                      () => _setWeekendReminderEnabled(
                        cubit,
                        !state.weekendReminderEnabled,
                      ),
                  child: _SwitchRow(
                    label: context.tr('Weekend reminder'),
                    subtitle: context.tr('Warn me on weekends if no weekday alarm is set.'),
                    value: state.weekendReminderEnabled,
                    onChanged:
                        (value) => _setWeekendReminderEnabled(cubit, value),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 8),
                SettingsTile(
                  onTap:
                      () => _setVacationModeEnabled(
                        cubit,
                        !state.vacationModeEnabled,
                      ),
                  child: _SwitchRow(
                    label: context.tr('Vacation mode'),
                    subtitle:
                        state.vacationModeEnabled
                            ? context.tr('ON: scheduled alarms are paused until disabled.')
                            : context.tr('Pause scheduled alarms without deleting them.'),
                    value: state.vacationModeEnabled,
                    onChanged: (value) => _setVacationModeEnabled(cubit, value),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 8),
                SettingsTile(
                  onTap:
                      () => _setStickyAlarmNotificationEnabled(
                        cubit,
                        !state.stickyAlarmTimeEnabled,
                      ),
                  child: _SwitchRow(
                    label: context.tr('Sticky alarm notification'),
                    subtitle: context.tr('Show a persistent notification for the next alarm.'),
                    value: state.stickyAlarmTimeEnabled,
                    onChanged:
                        (value) =>
                            _setStickyAlarmNotificationEnabled(cubit, value),
                    isDark: isDark,
                  ),
                ),

                // ── Alarm defaults ───────────────────────────────────────
                _SectionHeader(
                  label: context.tr('New alarm defaults'),
                  isDark: isDark,
                ), // TODO: localize
                SettingsTile(
                  onTap: () => _openSoundDefaults(cubit, state),
                  child: _NavRow(
                    icon: Icons.music_note_outlined,
                    label: context.tr('Sound'),
                    subtitle: state.defaultSoundSettings.soundName ?? context.tr('Default'),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 8),
                SettingsTile(
                  onTap: () => _openDismissDefaults(cubit, state),
                  child: _NavRow(
                    icon: _dismissIcon(state.defaultDismissSettings.mode),
                    label: context.tr('Dismiss'),
                    subtitle: _dismissSubtitle(state.defaultDismissSettings),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 8),
                SettingsTile(
                  onTap: () => _openSnoozeDefaults(cubit, state),
                  child: _NavRow(
                    icon: Icons.snooze,
                    label: context.tr('Snooze'),
                    subtitle:
                        state.defaultSnoozeSettings.enabled
                            ? '${state.defaultSnoozeSettings.durationMinutes} min · '
                                'max ${state.defaultSnoozeSettings.maxCount == 0 ? '∞' : '${state.defaultSnoozeSettings.maxCount}×'}'
                            : context.tr('Off'),
                    isDark: isDark,
                  ),
                ),

                // ── Help & feedback ─────────────────────────────────────
                _SectionHeader(
                  label: context.tr('Help & Feedback'),
                  isDark: isDark,
                ), // TODO: localize
                SettingsTile(
                  onTap: () => context.pushNamed(AppRoute.helpFeedback.name),
                  child: _NavRow(
                    icon: Icons.support_agent_outlined,
                    label: context.tr('Report a problem'),
                    subtitle: context.tr('Send feedback or request help from admin'),
                    isDark: isDark,
                  ),
                ),

                // ── System ───────────────────────────────────────────────
                _SectionHeader(
                  label: context.tr('System'),
                  isDark: isDark,
                ), // TODO: localize
                SettingsTile(
                  onTap: () => context.pushNamed(AppRoute.database.name),
                  child: _NavRow(
                    icon: Icons.storage_outlined,
                    label: context.localization.database,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 8),
                SettingsTile(
                  onTap: _showPermissionsSheet,
                  child: _NavRow(
                    icon: Icons.security_outlined,
                    label: context.tr('Permissions'),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 8),
                SettingsTile(
                  onTap: () => context.pushNamed(AppRoute.backupRestore.name),
                  child: _NavRow(
                    icon: Icons.backup_outlined,
                    label: context.tr('Backup & Restore'),
                    subtitle: context.tr('Export or restore alarms, settings, and logs'),
                    isDark: isDark,
                  ),
                ),

                // ── About ────────────────────────────────────────────────
                _SectionHeader(
                  label: context.tr('About'),
                  isDark: isDark,
                ), // TODO: localize
                SettingsTile(
                  onTap: _showAboutDialog,
                  child: _NavRow(
                    icon: Icons.info_outline,
                    label: context.tr('About Alarm Walker'),
                    subtitle: _version,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 8),
                SettingsTile(
                  onTap: _replayOnboarding,
                  child: _NavRow(
                    icon: Icons.play_circle_outline,
                    label: context.tr('Replay onboarding'),
                    subtitle: context.tr('View the introduction and category guide again'),
                    isDark: isDark,
                  ),
                ),

                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time, SettingsState state) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      time,
      alwaysUse24HourFormat: state.use24HourFormat,
    );
  }

  // ── label helpers ──────────────────────────────────────────────────────────

  IconData _dismissIcon(AlarmDisarmMode mode) => switch (mode) {
    AlarmDisarmMode.normal => Icons.alarm_off_outlined,
    AlarmDisarmMode.walk => Icons.directions_walk_outlined,
    AlarmDisarmMode.math => Icons.calculate_outlined,
    AlarmDisarmMode.shake => Icons.vibration,
    AlarmDisarmMode.retype => Icons.keyboard_outlined,
  };

  String _dismissSubtitle(DismissSettings s) => switch (s.mode) {
    AlarmDisarmMode.normal => context.tr('Normal'),
    AlarmDisarmMode.walk => "${context.tr('Walk')} ${s.walkSteps} ${context.tr('steps')}",
    AlarmDisarmMode.math =>
      "${context.tr('Math')} · ${context.tr(['Easy', 'Medium', 'Hard'][s.mathDifficulty - 1])}",
    AlarmDisarmMode.shake => "${context.tr('Shake')} ${s.shakeCount}×",
    AlarmDisarmMode.retype => context.tr('Retype phrase'),
  };
}


// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets (private to this file)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
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
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isDark;

  const _NavRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTextStyles.body(context)),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTextStyles.caption(context).copyWith(color: muted),
                ),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: muted, size: 20),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _SwitchRow({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.body(context).copyWith(color: muted),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTextStyles.caption(context).copyWith(color: muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        GradientSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Permissions bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionsSheet extends StatefulWidget {
  final PermissionStatus notificationStatus;
  final PermissionStatus exactAlarmStatus;

  const _PermissionsSheet({
    required this.notificationStatus,
    required this.exactAlarmStatus,
  });

  @override
  State<_PermissionsSheet> createState() => _PermissionsSheetState();
}

class _PermissionsSheetState extends State<_PermissionsSheet> {
  late PermissionStatus _notification;
  late PermissionStatus _exactAlarm;

  @override
  void initState() {
    super.initState();
    _notification = widget.notificationStatus;
    _exactAlarm = widget.exactAlarmStatus;
  }

  Future<void> _request(Permission p) async {
    final result = await p.request();
    if (!mounted) return;
    setState(() {
      if (p == Permission.notification) _notification = result;
      if (p == Permission.scheduleExactAlarm) _exactAlarm = result;
    });
    // If permanently denied, bounce to app settings
    if (result.isPermanentlyDenied) await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkScaffold1 : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permissions', // TODO: localize
            style: AppTextStyles.heading(context),
          ),
          const SizedBox(height: 4),
          Text(
            'These permissions are required for alarms to work reliably.', // TODO: localize
            style: AppTextStyles.caption(context),
          ),
          const SizedBox(height: 20),
          _PermissionRow(
            icon: Icons.notifications_outlined,
            label: 'Notifications', // TODO: localize
            description: 'Show alarm notifications',
            status: _notification,
            onRequest: () => _request(Permission.notification),
          ),
          const SizedBox(height: 12),
          _PermissionRow(
            icon: Icons.alarm_outlined,
            label: 'Exact alarms', // TODO: localize
            description: 'Schedule alarms at precise times',
            status: _exactAlarm,
            onRequest: () => _request(Permission.scheduleExactAlarm),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final PermissionStatus status;
  final VoidCallback onRequest;

  const _PermissionRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.status,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final granted = status.isGranted;
    final statusColor = granted ? Colors.green : Colors.orange;
    final statusLabel = switch (status) {
      PermissionStatus.granted => 'Granted', // TODO: localize
      PermissionStatus.denied => 'Denied',
      PermissionStatus.permanentlyDenied => 'Blocked — tap to open settings',
      PermissionStatus.restricted => 'Restricted',
      _ => 'Unknown',
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.body(context)),
              Text(
                description,
                style: AppTextStyles.caption(context).copyWith(
                  color:
                      isDark
                          ? AppColors.darkBackgroundText
                          : AppColors.lightBackgroundText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        granted
            ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: statusColor, size: 18),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: AppTextStyles.caption(
                    context,
                  ).copyWith(color: statusColor),
                ),
              ],
            )
            : TextButton(
              onPressed: onRequest,
              style: TextButton.styleFrom(
                foregroundColor: statusColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                status.isPermanentlyDenied
                    ? 'Open settings'
                    : statusLabel, // TODO: localize
                style: AppTextStyles.caption(
                  context,
                ).copyWith(color: statusColor, fontWeight: FontWeight.bold),
              ),
            ),
      ],
    );
  }
}
