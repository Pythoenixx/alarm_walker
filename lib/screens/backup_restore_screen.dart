import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/user_profile_repository.dart';
import 'package:alarm_walker/services/alarm_cubit.dart';
import 'package:alarm_walker/services/backup_restore_service.dart';
import 'package:alarm_walker/services/profile_cubit.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:alarm_walker/widgets/settings_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite/sqflite.dart';

class BackupRestoreScreen extends StatefulWidget {
  final Database db;
  final UserProfileRepository userRepo;

  const BackupRestoreScreen({
    super.key,
    required this.db,
    required this.userRepo,
  });

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _busy = false;

  String _ownerLabel(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return context.tr('Local device profile');
    return user.email ?? context.tr('Signed-in Firebase account');
  }

  BackupRestoreService _service() {
    return BackupRestoreService(
      db: widget.db,
      userRepo: widget.userRepo,
      settingsCubit: context.read<SettingsCubit>(),
    );
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportBackup() async {
    await _runBusy(() async {
      final result = await _service().exportCurrentUserBackup();
      if (!mounted) return;
      _showResult(result);
    });
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr('Restore backup')),
            content: Text(
              context.tr('This will replace alarms, settings, profile data, and wake-up logs for the current profile only. Other local/Firebase profiles are not changed.'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.tr('Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(context.tr('Choose backup')),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    await _runBusy(() async {
      final result = await _service().importBackupForCurrentUser();

      if (result.success) {
        await context.read<AlarmCubit>().reloadForCurrentOwner();
        final ownerId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
        await context.read<ProfileCubit>().loadProfile(ownerId);
      }

      if (!mounted) return;
      _showResult(result);
    });
  }

  void _showResult(BackupRestoreResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBorder : Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor:
            isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
        leading: IconButton(
          tooltip: context.localization.back,
          onPressed: _busy ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        centerTitle: true,
        title: Text(context.tr('Backup & Restore')),
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
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            12,
            12,
            12,
            12 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            _HeroCard(ownerLabel: _ownerLabel(context), isDark: isDark),
            const SizedBox(height: 16),
            SettingsTile(
              onTap: _busy ? null : _exportBackup,
              child: _ActionRow(
                icon: Icons.file_upload_outlined,
                label: context.tr('Back up data'),
                subtitle:
                    context.tr('Export current profile alarms, settings, and wake logs to JSON.'),
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 8),
            SettingsTile(
              onTap: _busy ? null : _restoreBackup,
              child: _ActionRow(
                icon: Icons.restore_outlined,
                label: context.tr('Restore data'),
                subtitle:
                    context.tr('Import a previous Alarm Walker JSON backup for this profile.'),
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),
            _NoteCard(isDark: isDark),
            if (_busy) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String ownerLabel;
  final bool isDark;

  const _HeroCard({required this.ownerLabel, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.9),
            AppColors.primary.withOpacity(0.65),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.cloud_sync_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Protect your alarm data'),
                  style: AppTextStyles.large(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ownerLabel,
                  style: AppTextStyles.caption(context).copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isDark;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTextStyles.body(context)),
              Text(
                subtitle,
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

class _NoteCard extends StatelessWidget {
  final bool isDark;

  const _NoteCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkScaffold1.withOpacity(0.7)
                : Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBlueGrey,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('Backups are local JSON files. Restore only backups that you trust. The restore action replaces data for the current profile only.'),
              style: AppTextStyles.caption(context).copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
