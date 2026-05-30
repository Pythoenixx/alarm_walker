import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/services/admin_report_service.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/widgets/admin_category_donut_chart.dart';
import 'package:alarm_walker/widgets/admin_disarm_mode_donut_chart.dart';
import 'package:alarm_walker/widgets/admin_metric_card.dart';
import 'package:flutter/material.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _reportService = AdminReportService();
  late Future<AdminReportMetrics> _metricsFuture;

  @override
  void initState() {
    super.initState();
    _metricsFuture = _reportService.loadMetrics();
  }

  void _refresh() {
    setState(() {
      _metricsFuture = _reportService.loadMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminReportMetrics>(
      future: _metricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ReportErrorState(message: snapshot.error.toString(), onRetry: _refresh);
        }

        final metrics = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Reports',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Detailed reports for user distribution, alarm usage, disarm choices, and system readiness.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh reports',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ReportSummary(metrics: metrics),
            const SizedBox(height: 20),
            _UsageStatisticsReport(metrics: metrics),
            const SizedBox(height: 20),
            _CategoryReport(metrics: metrics),
            const SizedBox(height: 20),
            _IssueReadinessReport(metrics: metrics),
          ],
        );
      },
    );
  }
}

class _ReportSummary extends StatelessWidget {
  final AdminReportMetrics metrics;

  const _ReportSummary({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final chips = [
      _ReportChip(
        icon: Icons.people_alt_outlined,
        color: AppColors.primary,
        label: 'Total Users',
        value: metrics.totalUsers.toString(),
      ),
      _ReportChip(
        icon: Icons.child_care,
        color: _categoryColor(ProfileCategory.child),
        label: 'Child',
        value: metrics.childUsers.toString(),
      ),
      _ReportChip(
        icon: Icons.person,
        color: _categoryColor(ProfileCategory.adult),
        label: 'Adult',
        value: metrics.adultUsers.toString(),
      ),
      _ReportChip(
        icon: Icons.elderly,
        color: _categoryColor(ProfileCategory.senior),
        label: 'Senior',
        value: metrics.seniorUsers.toString(),
      ),
      _ReportChip(
        icon: Icons.auto_graph_outlined,
        color: Colors.green,
        label: 'Top Category',
        value: metrics.topCategoryLabel,
      ),
    ];

    return _ReportPanel(
      icon: Icons.people_alt_outlined,
      color: AppColors.primary,
      title: 'Registered User Summary',
      subtitle: 'Basic user report generated from Firestore user records.',
      child: _AnimatedReportGrid(children: chips),
    );
  }
}


class _UsageStatisticsReport extends StatelessWidget {
  final AdminReportMetrics metrics;

  const _UsageStatisticsReport({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final coverageText =
        metrics.usageStatsAvailable
            ? '${metrics.usersWithUsageStats}/${metrics.totalUsers} synced users'
            : 'Usage summaries unavailable';

    return _ReportPanel(
      icon: Icons.analytics_outlined,
      color: Colors.indigo,
      title: 'Alarm Usage Statistics',
      subtitle: 'Aggregated alarm, snooze, and wake-up behavior from synced user summaries.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AnimatedReportGrid(
            children: [
              _ReportChip(
                icon: Icons.cloud_sync_outlined,
                color: AppColors.primary,
                label: 'Usage Coverage',
                value: coverageText,
              ),
              _ReportChip(
                icon: Icons.alarm_on_outlined,
                color: Colors.indigo,
                label: 'Total Alarms',
                value: metrics.totalAlarms.toString(),
              ),
              _ReportChip(
                icon: Icons.toggle_on_outlined,
                color: Colors.green,
                label: 'Enabled Alarms',
                value: metrics.enabledAlarms.toString(),
              ),
              _ReportChip(
                icon: Icons.repeat_outlined,
                color: Colors.blue,
                label: 'Repeat Alarms',
                value: metrics.repeatAlarms.toString(),
              ),
              _ReportChip(
                icon: Icons.event_available_outlined,
                color: Colors.teal,
                label: 'No-repeat Alarms',
                value: metrics.oneTimeAlarms.toString(),
              ),
              _ReportChip(
                icon: Icons.nightlight_round_outlined,
                color: Colors.deepPurple,
                label: 'Wake Logs',
                value: metrics.totalWakeLogs.toString(),
              ),
              _ReportChip(
                icon: Icons.verified_outlined,
                color: Colors.green,
                label: 'Success Rate',
                value: '${metrics.wakeSuccessRate.toStringAsFixed(0)}%',
              ),
              _ReportChip(
                icon: Icons.report_gmailerrorred_outlined,
                color: Colors.orange,
                label: 'Incomplete / Failed',
                value: metrics.failedWakeLogs.toString(),
              ),
              _ReportChip(
                icon: Icons.snooze_outlined,
                color: Colors.orange,
                label: 'Avg Snooze',
                value: metrics.averageSnoozeCount.toStringAsFixed(1),
              ),
              _ReportChip(
                icon: Icons.touch_app_outlined,
                color: Colors.redAccent,
                label: 'Failed Attempts',
                value: metrics.totalFailedDisarmAttempts.toString(),
              ),
              _ReportChip(
                icon: Icons.insights_outlined,
                color: Colors.redAccent,
                label: 'Avg Failed Attempts',
                value: metrics.averageFailedAttemptsPerWakeLog.toStringAsFixed(1),
              ),
              _ReportChip(
                icon: Icons.timer_outlined,
                color: Colors.pink,
                label: 'Avg Disarm Time',
                value: _formatDurationSeconds(metrics.averageDisarmDurationSeconds),
              ),
            
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Failed attempts count incorrect challenge inputs while the alarm remains active. No-repeat alarms are saved without repeat days selected; full one-time auto-disable behavior can be implemented separately.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 22),
          _DisarmModeDistributionReport(metrics: metrics),
          const SizedBox(height: 22),
          _FailedAttemptDistributionReport(metrics: metrics),
          if (!metrics.usageStatsAvailable && metrics.usageStatsError != null) ...[
            const SizedBox(height: 8),
            Text(
              metrics.usageStatsError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}


class _DisarmModeDistributionReport extends StatelessWidget {
  final AdminReportMetrics metrics;

  const _DisarmModeDistributionReport({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final legend = Column(
      children:
          AlarmDisarmMode.values.map((mode) {
            final count = metrics.disarmModeCountFor(mode);
            final percent = metrics.disarmModePercentFor(mode);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: adminDisarmModeColor(mode).withValues(alpha: 0.12),
                    child: Icon(
                      adminDisarmModeIcon(mode),
                      size: 16,
                      color: adminDisarmModeColor(mode),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(width: 78, child: Text(AdminReportMetrics.modeLabel(mode))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: percent / 100,
                        backgroundColor: adminDisarmModeColor(mode).withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          adminDisarmModeColor(mode),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('$count (${percent.toStringAsFixed(0)}%)'),
                ],
              ),
            );
          }).toList(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;
        final chart = AdminDisarmModeDonutChart(
          counts: metrics.disarmModeCounts,
          total: metrics.totalDisarmModeSelections,
          size: isCompact ? 160 : 190,
          strokeWidth: 20,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disarm mode distribution',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            if (isCompact) ...[
              Center(child: chart),
              const SizedBox(height: 20),
              legend,
            ] else
              Row(
                children: [
                  chart,
                  const SizedBox(width: 28),
                  Expanded(child: legend),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _FailedAttemptDistributionReport extends StatelessWidget {
  final AdminReportMetrics metrics;

  const _FailedAttemptDistributionReport({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final total = metrics.totalFailedDisarmAttempts;

    return _ReportPanel(
      icon: Icons.touch_app_outlined,
      color: Colors.redAccent,
      title: 'Failed Attempt Distribution',
      subtitle: 'Tracks incorrect challenge attempts before the alarm is successfully dismissed.',
      child: total == 0
          ? Text(
              'No failed disarm attempts have been recorded yet. Wrong Math or Typing attempts will appear here after users retry and complete the alarm.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          : Column(
              children: AlarmDisarmMode.values.map((mode) {
                final count = metrics.failedAttemptCountFor(mode);
                final percent = metrics.failedAttemptModePercentFor(mode);
                final color = adminDisarmModeColor(mode);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: color.withValues(alpha: 0.12),
                        child: Icon(
                          adminDisarmModeIcon(mode),
                          size: 16,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 78,
                        child: Text(AdminReportMetrics.modeLabel(mode)),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: percent / 100,
                            backgroundColor: color.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('$count (${percent.toStringAsFixed(0)}%)'),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}


class _CategoryReport extends StatelessWidget {
  final AdminReportMetrics metrics;

  const _CategoryReport({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      icon: Icons.groups_2_outlined,
      color: Colors.teal,
      title: 'Profile Category Report',
      subtitle: 'Used to verify profile-category support and default difficulty grouping.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 620;
          final chart = AdminCategoryDonutChart(
            counts: metrics.categoryCounts,
            total: metrics.totalUsers,
            size: isCompact ? 160 : 190,
            strokeWidth: 20,
          );
          final legend = Column(
            children:
                ProfileCategory.values.map((category) {
                  final count = metrics.countFor(category);
                  final percent = metrics.percentFor(category);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: _categoryColor(category).withValues(alpha: 0.12),
                          child: Icon(_categoryIcon(category), size: 16, color: _categoryColor(category)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  minHeight: 7,
                                  value: percent / 100,
                                  backgroundColor: _categoryColor(category).withValues(alpha: 0.12),
                                  valueColor: AlwaysStoppedAnimation<Color>(_categoryColor(category)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('$count (${percent.toStringAsFixed(0)}%)'),
                      ],
                    ),
                  );
                }).toList(),
          );

          if (isCompact) {
            return Column(
              children: [
                chart,
                const SizedBox(height: 20),
                legend,
              ],
            );
          }

          return Row(
            children: [
              chart,
              const SizedBox(width: 28),
              Expanded(child: legend),
            ],
          );
        },
      ),
    );
  }
}

class _IssueReadinessReport extends StatelessWidget {
  final AdminReportMetrics metrics;

  const _IssueReadinessReport({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final title = metrics.issueLogsAvailable ? 'Issue Logs Available' : 'Issue Logs Not Available Yet';
    final message =
        metrics.issueLogsAvailable
            ? 'The app_issue_logs collection is reachable. ${metrics.issueLogs} issue record(s) are currently available.'
            : 'The issue log collection may not exist yet or may require Firestore permission updates. Patch A2 can add app-side issue logging.';

    return _ReportPanel(
      icon: Icons.report_gmailerrorred_outlined,
      color: Colors.orange,
      title: 'Issue Report Readiness',
      subtitle: 'Prepared for future app issue and system health reporting.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: const Icon(Icons.report_gmailerrorred_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportPanel extends StatelessWidget {
  final IconData? icon;
  final Color? color;
  final String title;
  final String subtitle;
  final Widget child;

  const _ReportPanel({
    this.icon,
    this.color,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: (color ?? AppColors.primary).withValues(alpha: 0.12),
                    child: Icon(icon, size: 18, color: color ?? AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}


class _AnimatedReportGrid extends StatelessWidget {
  final List<Widget> children;

  const _AnimatedReportGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var index = 0; index < children.length; index++)
          AdminAnimatedCard(index: index, delayMs: 55, child: children[index]),
      ],
    );
  }
}

class _ReportChip extends StatelessWidget {
  final IconData? icon;
  final Color? color;
  final String label;
  final String value;

  const _ReportChip({
    this.icon,
    this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AdminMetricCard(
      icon: icon ?? Icons.insights_outlined,
      title: label,
      value: value,
      note: '',
      color: color ?? AppColors.primary,
      width: 180,
      embedded: true,
    );
  }
}

class _ReportErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ReportErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 44, color: Colors.red),
          const SizedBox(height: 12),
          Text('Unable to load reports', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}


String _formatDurationSeconds(double seconds) {
  if (seconds <= 0) return '0s';
  if (seconds < 60) return '${seconds.toStringAsFixed(seconds < 10 ? 1 : 0)}s';
  final minutes = seconds ~/ 60;
  final remaining = (seconds % 60).round();
  return '${minutes}m ${remaining}s';
}

Color _categoryColor(ProfileCategory category) {
  return switch (category) {
    ProfileCategory.child => Colors.purple,
    ProfileCategory.adult => Colors.blue,
    ProfileCategory.senior => Colors.teal,
  };
}

IconData _categoryIcon(ProfileCategory category) {
  return switch (category) {
    ProfileCategory.child => Icons.child_care,
    ProfileCategory.adult => Icons.person,
    ProfileCategory.senior => Icons.elderly,
  };
}
