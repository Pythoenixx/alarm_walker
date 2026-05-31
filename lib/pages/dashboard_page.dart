import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/services/admin_report_service.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/widgets/admin_category_donut_chart.dart';
import 'package:alarm_walker/widgets/admin_disarm_mode_donut_chart.dart';
import 'package:alarm_walker/widgets/admin_metric_card.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<AdminReportMetrics> _metricsFuture;
  final _reportService = AdminReportService();

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
          return _AdminErrorState(
            title: 'Unable to load dashboard',
            message: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }

        final metrics = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _AdminHeader(
                title: 'Admin Dashboard',
                subtitle:
                    'Quick snapshot of users, alarm activity, wake performance, open issues, and support tickets.',
                action: IconButton.filledTonal(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh dashboard',
                ),
              ),
              const SizedBox(height: 20),
              _OverviewGrid(metrics: metrics),
              const SizedBox(height: 20),
              _DashboardChartPreviewRow(metrics: metrics),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _UsageHighlightsCard(metrics: metrics)),
                  const SizedBox(width: 16),
                  Expanded(child: _SystemHealthCard(metrics: metrics)),
                ],
              ),
              const SizedBox(height: 20),
              _RecentUsersCard(users: metrics.recentUsers),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  final AdminReportMetrics metrics;

  const _OverviewGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final cards = [
      AdminMetricCard(
        icon: Icons.people_alt_outlined,
        title: 'Total Users',
        value: metrics.totalUsers.toString(),
        note: 'Registered user records',
        color: AppColors.primary,
      ),
      AdminMetricCard(
        icon: Icons.alarm_on_outlined,
        title: 'Total Alarms',
        value: metrics.totalAlarms.toString(),
        note:
            '${metrics.enabledAlarms} enabled · ${metrics.disabledAlarms} disabled',
        color: Colors.indigo,
      ),
      AdminMetricCard(
        icon: Icons.nightlight_round_outlined,
        title: 'Wake Logs',
        value: metrics.totalWakeLogs.toString(),
        note: '${metrics.wakeSuccessRate.toStringAsFixed(0)}% success rate',
        color: Colors.deepPurple,
      ),
      AdminMetricCard(
        icon: Icons.verified_outlined,
        title: 'Success Rate',
        value: '${metrics.wakeSuccessRate.toStringAsFixed(0)}%',
        note:
            '${metrics.successfulWakeLogs}/${metrics.totalWakeLogs} successful wake logs',
        color: Colors.green,
      ),
      AdminMetricCard(
        icon: Icons.snooze_outlined,
        title: 'Avg Snooze',
        value: metrics.averageSnoozeCount.toStringAsFixed(1),
        note: 'Average snoozes per wake log',
        color: Colors.orange,
      ),
      AdminMetricCard(
        icon: Icons.touch_app_outlined,
        title: 'Failed Attempts',
        value: metrics.totalFailedDisarmAttempts.toString(),
        note: '${metrics.averageFailedAttemptsPerWakeLog.toStringAsFixed(1)} average per wake log',
        color: Colors.redAccent,
      ),
      AdminMetricCard(
        icon: Icons.report_gmailerrorred_outlined,
        title: 'Open Issues',
        value:
            metrics.issueLogsAvailable ? metrics.issueLogs.toString() : 'N/A',
        note:
            metrics.issueLogsAvailable
                ? 'Unresolved issue records'
                : 'Collection unavailable',
        color: Colors.orange,
      ),
      AdminMetricCard(
        icon: Icons.support_agent_outlined,
        title: 'Open Support',
        value:
            metrics.supportTicketsAvailable ? metrics.supportTickets.toString() : 'N/A',
        note:
            metrics.supportTicketsAvailable
                ? 'User-submitted tickets'
                : 'Collection unavailable',
        color: AppColors.primary,
      ),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (var index = 0; index < cards.length; index++)
          AdminAnimatedCard(index: index, child: cards[index]),
      ],
    );
  }
}

class _DashboardChartPreviewRow extends StatelessWidget {
  final AdminReportMetrics metrics;

  const _DashboardChartPreviewRow({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        final children = [
          Expanded(child: _CategoryDistributionCard(metrics: metrics)),
          const SizedBox(width: 16),
          Expanded(child: _DisarmDistributionCard(metrics: metrics)),
        ];

        if (isCompact) {
          return Column(
            children: [
              _CategoryDistributionCard(metrics: metrics),
              const SizedBox(height: 16),
              _DisarmDistributionCard(metrics: metrics),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }
}

class _CategoryDistributionCard extends StatelessWidget {
  final AdminReportMetrics metrics;

  const _CategoryDistributionCard({required this.metrics});

  IconData _categoryIcon(String label) {
    final normalized = label.toLowerCase();

    if (normalized.contains('child')) {
      return Icons.child_care_rounded;
    }

    if (normalized.contains('senior')) {
      return Icons.elderly_rounded;
    }

    if (normalized.contains('adult')) {
      return Icons.person_rounded;
    }

    return Icons.person_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Profile Categories',
      subtitle:
          'Quick user grouping preview. Open Reports for full percentages.',
      child: _ChartPreview(
        chart: AdminCategoryDonutChart(
          counts: metrics.categoryCounts,
          total: metrics.totalUsers,
          size: 150,
          strokeWidth: 18,
        ),
        legend:
            ProfileCategory.values.map((category) {
              return _LegendPill(
                icon: _categoryIcon(category.label),
                label: category.label,
                value: metrics.countFor(category).toString(),
                color: _categoryColor(category),
              );
            }).toList(),
        footer: '',
      ),
    );
  }
}

class _DisarmDistributionCard extends StatelessWidget {
  final AdminReportMetrics metrics;

  const _DisarmDistributionCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    // final topMode =
    //     metrics.totalDisarmModeSelections == 0
    //         ? 'No data yet'
    //         : metrics.topDisarmModeLabel;

    return _PanelCard(
      title: 'Disarm Choices',
      subtitle:
          'Compact mode preference preview. Open Reports for detailed counts.',
      child: _ChartPreview(
        chart: AdminDisarmModeDonutChart(
          counts: metrics.disarmModeCounts,
          total: metrics.totalDisarmModeSelections,
          size: 150,
          strokeWidth: 18,
        ),
        legend:
            AlarmDisarmMode.values.map((mode) {
              return _LegendPill(
                icon: adminDisarmModeIcon(mode),
                label: AdminReportMetrics.modeLabel(mode),
                value: metrics.disarmModeCountFor(mode).toString(),
                color: adminDisarmModeColor(mode),
              );
            }).toList(),
        footer: '',
      ),
    );
  }
}

class _ChartPreview extends StatelessWidget {
  final Widget chart;
  final List<Widget> legend;
  final String footer;

  const _ChartPreview({
    required this.chart,
    required this.legend,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(child: chart),
        const SizedBox(height: 18),
        Wrap(spacing: 8, runSpacing: 8, children: legend),
        const SizedBox(height: 14),
        Text(
          footer,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _LegendPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _LegendPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(value),
        ],
      ),
    );
  }
}

class _SystemHealthCard extends StatelessWidget {
  final AdminReportMetrics metrics;

  const _SystemHealthCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final issueText =
        metrics.issueLogsAvailable
            ? '${metrics.issueLogs} open issue(s) need review.'
            : 'Issue log collection is not available yet.';
    final supportText =
        metrics.supportTicketsAvailable
            ? '${metrics.supportTickets} support ticket(s) need admin follow-up.'
            : 'Support ticket collection is not available yet.';

    return _PanelCard(
      title: 'System Health Overview',
      subtitle: 'Basic app monitoring status for admin review.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HealthItem(
            icon: Icons.check_circle_outline,
            title: 'User reporting',
            message: '${metrics.totalUsers} user record(s) can be summarized.',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _HealthItem(
            icon: Icons.info_outline,
            title: 'Open issue tracking',
            message: issueText,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _HealthItem(
            icon: Icons.support_agent_outlined,
            title: 'Support tickets',
            message: supportText,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _HealthItem(
            icon: Icons.insights_outlined,
            title: 'Usage statistics',
            message:
                '${metrics.usersWithUsageStats} of ${metrics.totalUsers} user record(s) have synced alarm usage summaries.',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _HealthItem(
            icon: Icons.schedule_outlined,
            title: 'Generated at',
            message: _formatDateTime(metrics.generatedAt),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _UsageHighlightsCard extends StatelessWidget {
  final AdminReportMetrics metrics;

  const _UsageHighlightsCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final statusMessage =
        metrics.usageStatsAvailable
            ? '${metrics.usersWithUsageStats}/${metrics.totalUsers} user(s) have synced usage summaries.'
            : 'Usage summary collection is unavailable yet.';

    return _PanelCard(
      title: 'Usage Highlights',
      subtitle:
          'Short dashboard preview. Open Reports for detailed breakdowns.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HealthItem(
            icon: Icons.cloud_sync_outlined,
            title: 'Usage summary coverage',
            message: statusMessage,
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MiniStat(
                label: 'Enabled alarms',
                value: metrics.enabledAlarms.toString(),
                helper:
                    '${metrics.alarmEnabledPercent.toStringAsFixed(0)}% of saved alarms',
              ),
              _MiniStat(
                label: 'No-repeat alarms',
                value: metrics.oneTimeAlarms.toString(),
                helper: 'Saved with no repeat day selected',
              ),
              _MiniStat(
                label: 'Avg disarm time',
                value: _formatDurationSeconds(
                  metrics.averageDisarmDurationSeconds,
                ),
                helper: 'Across completed wake logs',
              ),
              _MiniStat(
                label: 'Total snoozes',
                value: metrics.totalSnoozeCount.toString(),
                helper: 'From synced wake logs',
              ),
              _MiniStat(
                label: 'Failed attempts',
                value: metrics.totalFailedDisarmAttempts.toString(),
                helper: 'Wrong challenge inputs recorded',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentUsersCard extends StatelessWidget {
  final List<AdminUserSummary> users;

  const _RecentUsersCard({required this.users});

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Recent User Records',
      subtitle:
          'Compact account preview. Open Users for full management details.',
      child:
          users.isEmpty
              ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No users found yet.')),
              )
              : Column(
                children:
                    users.map((user) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Text(
                          user.hasEmail ? user.displayEmail : user.userId,
                        ),
                        trailing: Chip(label: Text(user.profileCategory.label)),
                      );
                    }).toList(),
              ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String helper;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(helper, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _PanelCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _HealthItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _HealthItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(message, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const _AdminHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _AdminErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _AdminErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42, color: Colors.red),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
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
        ),
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

String _formatDateTime(DateTime value) {
  final date =
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
