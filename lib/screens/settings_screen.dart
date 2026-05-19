import 'package:alarm_walker/app_router.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/dismiss_settings.dart';
import 'package:alarm_walker/models/snooze_settings.dart';
import 'package:alarm_walker/models/sound_settings.dart';
import 'package:alarm_walker/screens/dismiss_settings_screen.dart';
import 'package:alarm_walker/screens/snooze_settings_screen.dart';
import 'package:alarm_walker/screens/sound_settings_screen.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
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
            title: const Text('Replay onboarding'), // TODO: localize
            content: const Text(
              'This will show the introduction screens again. Your alarms, settings, and wake-up logs will not be deleted.',
            ), // TODO: localize
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'), // TODO: localize
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Replay'), // TODO: localize
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
                  label: 'Appearance',
                  isDark: isDark,
                ), // TODO: localize
                ThemeListTile(
                  mode: state.themeMode,
                  onChanged: (m) => cubit.setTheme(m),
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
                  label: 'Weather-aware wake-up',
                  isDark: isDark,
                ), // TODO: localize
                SettingsTile(
                  onTap:
                      () => cubit.setWeatherAwareEnabled(
                        !state.weatherAwareEnabled,
                      ),
                  child: _SwitchRow(
                    label: 'Show weather messages', // TODO: localize
                    value: state.weatherAwareEnabled,
                    onChanged: cubit.setWeatherAwareEnabled,
                    isDark: isDark,
                  ),
                ),

                // ── Adaptive difficulty ──────────────────────────────
                _SectionHeader(
                  label: 'Adaptive difficulty',
                  isDark: isDark,
                ), // TODO: localize
                SettingsTile(
                  onTap:
                      () => cubit.setAdaptiveDifficultyEnabled(
                        !state.adaptiveDifficultyEnabled,
                      ),
                  child: _SwitchRow(
                    label: 'Adjust future alarm defaults', // TODO: localize
                    value: state.adaptiveDifficultyEnabled,
                    onChanged: cubit.setAdaptiveDifficultyEnabled,
                    isDark: isDark,
                  ),
                ),

                // ── Alarm defaults ───────────────────────────────────────
                _SectionHeader(
                  label: 'New alarm defaults',
                  isDark: isDark,
                ), // TODO: localize
                SettingsTile(
                  onTap: () => _openSoundDefaults(cubit, state),
                  child: _NavRow(
                    icon: Icons.music_note_outlined,
                    label: 'Sound', // TODO: localize
                    subtitle: state.defaultSoundSettings.soundName ?? 'Default',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 8),
                SettingsTile(
                  onTap: () => _openDismissDefaults(cubit, state),
                  child: _NavRow(
                    icon: _dismissIcon(state.defaultDismissSettings.mode),
                    label: 'Dismiss', // TODO: localize
                    subtitle: _dismissSubtitle(state.defaultDismissSettings),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 8),
                SettingsTile(
                  onTap: () => _openSnoozeDefaults(cubit, state),
                  child: _NavRow(
                    icon: Icons.snooze,
                    label: 'Snooze', // TODO: localize
                    subtitle:
                        state.defaultSnoozeSettings.enabled
                            ? '${state.defaultSnoozeSettings.durationMinutes} min · '
                                'max ${state.defaultSnoozeSettings.maxCount == 0 ? '∞' : '${state.defaultSnoozeSettings.maxCount}×'}'
                            : 'Off',
                    isDark: isDark,
                  ),
                ),

                // ── System ───────────────────────────────────────────────
                _SectionHeader(
                  label: 'System',
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
                    label: 'Permissions', // TODO: localize
                    isDark: isDark,
                  ),
                ),

                // ── About ────────────────────────────────────────────────
                _SectionHeader(
                  label: 'About',
                  isDark: isDark,
                ), // TODO: localize
                SettingsTile(
                  onTap: _showAboutDialog,
                  child: _NavRow(
                    icon: Icons.info_outline,
                    label: 'About Alarm Walker', // TODO: localize
                    subtitle: _version,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 8),
                SettingsTile(
                  onTap: _replayOnboarding,
                  child: _NavRow(
                    icon: Icons.play_circle_outline,
                    label: 'Replay onboarding', // TODO: localize
                    subtitle: 'View the introduction and category guide again',
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

  // ── label helpers ──────────────────────────────────────────────────────────

  IconData _dismissIcon(AlarmDisarmMode mode) => switch (mode) {
    AlarmDisarmMode.normal => Icons.alarm_off_outlined,
    AlarmDisarmMode.walk => Icons.directions_walk_outlined,
    AlarmDisarmMode.math => Icons.calculate_outlined,
    AlarmDisarmMode.shake => Icons.vibration,
    AlarmDisarmMode.retype => Icons.keyboard_outlined,
  };

  String _dismissSubtitle(DismissSettings s) => switch (s.mode) {
    AlarmDisarmMode.normal => 'Normal', // TODO: localize
    AlarmDisarmMode.walk => 'Walk ${s.walkSteps} steps',
    AlarmDisarmMode.math =>
      'Math · ${['Easy', 'Medium', 'Hard'][s.mathDifficulty - 1]}',
    AlarmDisarmMode.shake => 'Shake ${s.shakeCount}×',
    AlarmDisarmMode.retype => 'Retype phrase',
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
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.body(context).copyWith(
            color:
                isDark
                    ? AppColors.darkBackgroundText
                    : AppColors.lightBackgroundText,
          ),
        ),
        const Spacer(),
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
