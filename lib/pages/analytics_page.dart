import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/services/admin_report_service.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/widgets/admin_category_donut_chart.dart';
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
                        'Admin summaries for users, profile categories, and system issue readiness.',
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
    return _ReportPanel(
      title: 'Registered User Summary',
      subtitle: 'Basic user report generated from Firestore user records.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _ReportChip(label: 'Total Users', value: metrics.totalUsers.toString()),
          _ReportChip(label: 'Child', value: metrics.childUsers.toString()),
          _ReportChip(label: 'Adult', value: metrics.adultUsers.toString()),
          _ReportChip(label: 'Senior', value: metrics.seniorUsers.toString()),
          _ReportChip(label: 'Top Category', value: metrics.topCategoryLabel),
          _ReportChip(
            label: 'Email Coverage',
            value: '${metrics.emailCoveragePercent.toStringAsFixed(0)}%',
          ),
        ],
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
  final String title;
  final String subtitle;
  final Widget child;

  const _ReportPanel({
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
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
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

class _ReportChip extends StatelessWidget {
  final String label;
  final String value;

  const _ReportChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
