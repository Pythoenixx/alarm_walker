import 'dart:async';

import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/dismiss_settings.dart';
import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/models/user_profile_model.dart';
import 'package:alarm_walker/models/wake_log_model.dart';
import 'package:alarm_walker/models/wake_log_repository.dart';
import 'package:alarm_walker/services/adaptive_difficulty_service.dart';
import 'package:alarm_walker/services/profile_cubit.dart';
import 'package:alarm_walker/services/settings_cubit.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class WakeAnalyticsScreen extends StatefulWidget {
  final WakeLogRepository wakeRepo;

  const WakeAnalyticsScreen({super.key, required this.wakeRepo});

  @override
  State<WakeAnalyticsScreen> createState() => _WakeAnalyticsScreenState();
}

class _WakeAnalyticsScreenState extends State<WakeAnalyticsScreen> {
  late Future<_AnalyticsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AnalyticsData> _load() async {
    final ownerId = FirebaseAuth.instance.currentUser?.uid ?? 'local';
    final logs = await widget.wakeRepo.getAllLogs(userId: ownerId);
    final summary = await widget.wakeRepo.getSummary(userId: ownerId);
    final settingsCubit = context.read<SettingsCubit>();
    final settings = settingsCubit.state;
    final category =
        context.read<ProfileCubit>().state?.profileCategory ??
        ProfileCategory.fallback;
    final adaptiveResult =
        settings.adaptiveDifficultyEnabled
            ? await AdaptiveDifficultyService.analyze(
              wakeRepo: widget.wakeRepo,
              settingsCubit: settingsCubit,
              category: category,
              ownerId: ownerId,
            )
            : null;

    return _AnalyticsData(
      logs: logs,
      summary: summary,
      adaptiveResult: adaptiveResult,
      profileCategory: category,
      adaptiveDifficultyEnabled: settings.adaptiveDifficultyEnabled,
      defaultDismissSettings: settings.defaultDismissSettings,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.darkScaffold1 : AppColors.lightScaffold1,
        leading:
            Navigator.of(context).canPop()
                ? IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                )
                : null,
        centerTitle: true,
        title: const Text('Wake Analytics'),
        titleTextStyle: AppTextStyles.heading(context),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => unawaited(_refresh()),
            icon: const Icon(Icons.refresh_rounded),
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
                    : [AppColors.lightScaffold1, AppColors.lightScaffold2],
          ),
        ),
        child: SafeArea(
          top: false,
          child: MultiBlocListener(
            listeners: [
              BlocListener<ProfileCubit, UserProfile?>(
                listenWhen:
                    (previous, current) =>
                        previous?.profileCategory != current?.profileCategory,
                listener: (_, __) => unawaited(_refresh()),
              ),
              BlocListener<SettingsCubit, SettingsState>(
                listenWhen:
                    (previous, current) =>
                        previous.adaptiveDifficultyEnabled !=
                            current.adaptiveDifficultyEnabled ||
                        previous.defaultDismissSettings !=
                            current.defaultDismissSettings,
                listener: (_, __) => unawaited(_refresh()),
              ),
            ],
            child: FutureBuilder<_AnalyticsData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _AnalyticsErrorState(
                    isDark: isDark,
                    onRetry: () => unawaited(_refresh()),
                  );
                }

                final data = snapshot.data;
                if (data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _OverviewHero(data: data, isDark: isDark),
                      const SizedBox(height: 16),
                      _SectionHeader(
                        icon: Icons.insights_outlined,
                        title: 'Performance Summary',
                        subtitle: 'Quick view of your latest wake-up behavior.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _SummaryCards(
                        summary: data.summary,
                        logs: data.logs,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        icon: Icons.auto_awesome_outlined,
                        title: 'Adaptive Difficulty',
                        subtitle: 'Recommendation for future alarm defaults.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _AdaptiveDifficultyCard(
                        result: data.adaptiveResult,
                        profileCategory: data.profileCategory,
                        enabled: data.adaptiveDifficultyEnabled,
                        defaultDismissSettings: data.defaultDismissSettings,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        icon: Icons.history_rounded,
                        title: 'Wake History',
                        subtitle: 'Recent alarm attempts and disarm results.',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _WakeHistoryList(logs: data.logs, isDark: isDark),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewHero extends StatelessWidget {
  final _AnalyticsData data;
  final bool isDark;

  const _OverviewHero({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = data.summary['total'] as int? ?? 0;
    final success = data.summary['successes'] as int? ?? 0;
    final successRate = total > 0 ? (success / total * 100).round() : 0;
    final latest = data.logs.isNotEmpty ? data.logs.first.wakeTime : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.bedtime_rounded,
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
                      total == 0
                          ? 'No wake records yet'
                          : '$successRate% successful wake-ups',
                      style: AppTextStyles.large(context).copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'Complete an alarm to start.'
                          : '$success / $total successful records',
                      style: AppTextStyles.body(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(
                icon: Icons.person_outline_rounded,
                label: data.profileCategory.label,
              ),
              _HeroChip(
                icon: Icons.auto_graph_rounded,
                label:
                    data.adaptiveDifficultyEnabled
                        ? 'Adaptive ON'
                        : 'Adaptive OFF',
              ),
              _HeroChip(
                icon: Icons.calendar_month_rounded,
                label:
                    latest == null
                        ? 'No latest wake'
                        : 'Latest ${DateFormat('MMM d, h:mm a').format(latest)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.large(context).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Summary',
                style: AppTextStyles.caption(context).copyWith(
                  color: textColor.withValues(alpha: 0.48),
                ),
              ),
            ],
          ),
        ),
        Tooltip(
          message: subtitle,
          child: Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: textColor.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}


String _formatDurationMs(int milliseconds) {
  if (milliseconds <= 0) return '0s';

  final seconds = milliseconds / 1000;

  if (seconds < 60) {
    final decimals = seconds < 10 && seconds != seconds.roundToDouble() ? 1 : 0;
    return '${seconds.toStringAsFixed(decimals)}s';
  }

  final minutes = seconds ~/ 60;
  final remainingSeconds = (seconds % 60).round();

  if (remainingSeconds == 0) return '${minutes}m';
  return '${minutes}m ${remainingSeconds}s';
}

class _SummaryCards extends StatelessWidget {
  final Map<String, Object?> summary;
  final List<WakeLog> logs;
  final bool isDark;

  const _SummaryCards({
    required this.summary,
    required this.logs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final total = summary['total'] as int? ?? 0;
    final success = summary['successes'] as int? ?? 0;
    final avgMs = (summary['avg_duration'] as num?)?.round() ?? 0;
    final successRate = total > 0 ? (success / total * 100).round() : 0;
    final totalSnoozes = logs.fold<int>(0, (sum, log) => sum + log.snoozeCount);
    final totalFailedAttempts = logs.fold<int>(
      0,
      (sum, log) => sum + log.failedAttemptCount,
    );
    final averageFailedAttempts =
        total > 0 ? totalFailedAttempts / total : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.alarm_rounded,
                label: 'Total Records',
                value: total.toString(),
                caption: 'Wake attempts',
                isDark: isDark,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.verified_rounded,
                label: 'Success Rate',
                value: '$successRate%',
                caption: '$success successful',
                isDark: isDark,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.timer_rounded,
                label: 'Avg Disarm',
                value: _formatDurationMs(avgMs),
                caption: 'Challenge time',
                isDark: isDark,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.snooze_rounded,
                label: 'Snoozes',
                value: totalSnoozes.toString(),
                caption: 'Total used',
                isDark: isDark,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.touch_app_rounded,
                label: 'Failed Attempts',
                value: totalFailedAttempts.toString(),
                caption: 'Wrong challenge inputs',
                isDark: isDark,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.insights_rounded,
                label: 'Avg Attempts',
                value: averageFailedAttempts.toStringAsFixed(1),
                caption: 'Per wake record',
                isDark: isDark,
                color: Colors.deepOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdaptiveDifficultyCard extends StatelessWidget {
  final AdaptiveDifficultyResult? result;
  final ProfileCategory profileCategory;
  final bool enabled;
  final DismissSettings defaultDismissSettings;
  final bool isDark;

  const _AdaptiveDifficultyCard({
    required this.result,
    required this.profileCategory,
    required this.enabled,
    required this.defaultDismissSettings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final decision = result?.decision;
    final color = _colorForDecision(decision, enabled);
    final icon = _iconForDecision(decision, enabled);
    final title = _titleForDecision(decision, enabled);
    final subtitle =
        enabled
            ? result?.message ?? 'Adaptive difficulty is ready to analyze wake-up records.'
            : 'Adaptive difficulty is turned off in Settings.';
    final metrics = result?.metrics;

    return _SurfaceCard(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      borderColor: enabled ? color.withValues(alpha: 0.45) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adaptive Difficulty',
                      style: AppTextStyles.large(context).copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: AppTextStyles.caption(context).copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Tooltip(
                message: subtitle,
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Default challenge summary',
                  style: AppTextStyles.caption(context).copyWith(
                    color:
                        isDark
                            ? AppColors.darkBackgroundText.withValues(alpha: 0.65)
                            : AppColors.lightBackgroundText.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.person_outline,
                label: profileCategory.label,
                isDark: isDark,
              ),
              _InfoChip(
                icon: Icons.analytics_outlined,
                label: '${result?.analyzedLogs ?? 0} logs analyzed',
                isDark: isDark,
              ),
              _InfoChip(
                icon: Icons.calculate_outlined,
                label:
                    'Math ${_mathDifficultyLabel(defaultDismissSettings.mathDifficulty)}',
                isDark: isDark,
              ),
              _InfoChip(
                icon: Icons.format_list_numbered,
                label: '${defaultDismissSettings.mathProblemCount} problems',
                isDark: isDark,
              ),
              _InfoChip(
                icon: Icons.directions_walk,
                label: '${defaultDismissSettings.walkSteps} steps',
                isDark: isDark,
              ),
            ],
          ),
          if (metrics != null) ...[
            const SizedBox(height: 14),
            Divider(
              color: isDark ? AppColors.darkBorder : AppColors.lightBlueGrey,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Success',
                    value: '${(metrics.successRate * 100).toStringAsFixed(0)}%',
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _MiniMetric(
                    label: 'Avg snooze',
                    value: metrics.averageSnoozeCount.toStringAsFixed(1),
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _MiniMetric(
                    label: 'Avg disarm',
                    value: '${metrics.averageDisarmSeconds.toStringAsFixed(0)}s',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Color _colorForDecision(
    AdaptiveDifficultyDecision? decision,
    bool enabled,
  ) {
    if (!enabled) return Colors.grey;
    return switch (decision) {
      AdaptiveDifficultyDecision.madeHarder => Colors.deepOrange,
      AdaptiveDifficultyDecision.madeEasier => Colors.green,
      AdaptiveDifficultyDecision.insufficientData => Colors.blueGrey,
      AdaptiveDifficultyDecision.noChange || null => Colors.indigo,
    };
  }

  static IconData _iconForDecision(
    AdaptiveDifficultyDecision? decision,
    bool enabled,
  ) {
    if (!enabled) return Icons.pause_circle_outline;
    return switch (decision) {
      AdaptiveDifficultyDecision.madeHarder => Icons.trending_up,
      AdaptiveDifficultyDecision.madeEasier => Icons.trending_down,
      AdaptiveDifficultyDecision.insufficientData => Icons.hourglass_empty,
      AdaptiveDifficultyDecision.noChange || null => Icons.tune,
    };
  }

  static String _titleForDecision(
    AdaptiveDifficultyDecision? decision,
    bool enabled,
  ) {
    if (!enabled) return 'Disabled';
    return switch (decision) {
      AdaptiveDifficultyDecision.madeHarder => 'Recommendation: firmer defaults',
      AdaptiveDifficultyDecision.madeEasier => 'Recommendation: lighter defaults',
      AdaptiveDifficultyDecision.insufficientData => 'Collecting wake-up records',
      AdaptiveDifficultyDecision.noChange || null => 'Current defaults are suitable',
    };
  }

  static String _mathDifficultyLabel(int value) {
    return switch (value) {
      1 => 'Easy',
      2 => 'Medium',
      _ => 'Hard',
    };
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const _SurfaceCard({
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkScaffold1.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              borderColor ??
              (isDark ? AppColors.darkBorder : AppColors.lightBlueGrey),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkScaffold2.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBlueGrey,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.large(context).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption(context).copyWith(
            color:
                isDark
                    ? AppColors.darkBackgroundText.withValues(alpha: 0.65)
                    : AppColors.lightBackgroundText.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final bool isDark;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;

    return _SurfaceCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 21, color: color),
              ),
              const Spacer(),
              Text(
                value,
                style: AppTextStyles.large(context).copyWith(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: AppTextStyles.caption(context).copyWith(
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _WakeHistoryList extends StatelessWidget {
  final List<WakeLog> logs;
  final bool isDark;

  const _WakeHistoryList({required this.logs, required this.isDark});

  String _formatDate(DateTime dt) => DateFormat('EEE, MMM d').format(dt);

  String _formatTime(DateTime dt) => DateFormat('h:mm a').format(dt);

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return _SurfaceCard(
        isDark: isDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No wake logs yet',
              style: AppTextStyles.large(context).copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Dismiss an alarm to start recording wake-up performance.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(context).copyWith(
                color:
                    isDark
                        ? AppColors.darkBackgroundText.withValues(alpha: 0.65)
                        : AppColors.lightBackgroundText.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children:
          logs.take(30).map((log) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _WakeLogCard(
                log: log,
                date: _formatDate(log.wakeTime),
                time: _formatTime(log.wakeTime),
                isDark: isDark,
              ),
            );
          }).toList(),
    );
  }
}

class _WakeLogCard extends StatelessWidget {
  final WakeLog log;
  final String date;
  final String time;
  final bool isDark;

  const _WakeLogCard({
    required this.log,
    required this.date,
    required this.time,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final successColor = log.success ? Colors.green : Colors.red;
    final successLabel = log.success ? 'Success' : 'Failed';
    final textColor =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;

    return _SurfaceCard(
      isDark: isDark,
      padding: const EdgeInsets.all(14),
      borderColor: successColor.withValues(alpha: 0.28),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: successColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              log.success ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$date • $time',
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                    _StatusPill(label: successLabel, color: successColor),
                  ],
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CompactMetric(
                      icon: _modeIcon(log.disarmMode),
                      label: _modeLabel(log.disarmMode),
                      isDark: isDark,
                    ),
                    _CompactMetric(
                      icon: Icons.snooze_rounded,
                      label: '${log.snoozeCount} snooze${log.snoozeCount == 1 ? '' : 's'}',
                      isDark: isDark,
                    ),
                    _CompactMetric(
                      icon: Icons.timer_rounded,
                      label: '${_formatDurationMs(log.disarmDurationMs)} disarm',
                      isDark: isDark,
                    ),
                    if (log.failedAttemptCount > 0)
                      _CompactMetric(
                        icon: Icons.touch_app_rounded,
                        label:
                            '${log.failedAttemptCount} failed attempt${log.failedAttemptCount == 1 ? '' : 's'}',
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _modeIcon(AlarmDisarmMode mode) {
    return switch (mode) {
      AlarmDisarmMode.math => Icons.calculate_rounded,
      AlarmDisarmMode.retype => Icons.keyboard_rounded,
      AlarmDisarmMode.shake => Icons.vibration_rounded,
      AlarmDisarmMode.walk => Icons.directions_walk_rounded,
      AlarmDisarmMode.normal => Icons.touch_app_rounded,
    };
  }

  static String _modeLabel(AlarmDisarmMode mode) {
    return switch (mode) {
      AlarmDisarmMode.math => 'Math',
      AlarmDisarmMode.retype => 'Typing',
      AlarmDisarmMode.shake => 'Shake',
      AlarmDisarmMode.walk => 'Walk',
      AlarmDisarmMode.normal => 'Normal',
    };
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(context).copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _CompactMetric({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkScaffold2.withValues(alpha: 0.42)
                : AppColors.lightScaffold2.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption(context).copyWith(
              color: textColor.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsErrorState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRetry;

  const _AnalyticsErrorState({required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _SurfaceCard(
          isDark: isDark,
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load analytics',
                style: AppTextStyles.large(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please try refreshing the page.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(
                  color: textColor.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsData {
  final List<WakeLog> logs;
  final Map<String, Object?> summary;
  final AdaptiveDifficultyResult? adaptiveResult;
  final ProfileCategory profileCategory;
  final bool adaptiveDifficultyEnabled;
  final DismissSettings defaultDismissSettings;

  _AnalyticsData({
    required this.logs,
    required this.summary,
    required this.adaptiveResult,
    required this.profileCategory,
    required this.adaptiveDifficultyEnabled,
    required this.defaultDismissSettings,
  });
}
