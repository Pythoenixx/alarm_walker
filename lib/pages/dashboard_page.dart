import 'package:alarm_walker/models/profile_category.dart';
import 'package:alarm_walker/services/admin_report_service.dart';
import 'package:alarm_walker/theme/app_colors.dart';
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
                    'System overview for users, profile categories, and issue readiness.',
                action: IconButton.filledTonal(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh dashboard',
                ),
              ),
              const SizedBox(height: 20),
              _OverviewGrid(metrics: metrics),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _CategoryDistributionCard(metrics: metrics)),
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
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetricCard(
          icon: Icons.people_alt_outlined,
          title: 'Total Users',
          value: metrics.totalUsers.toString(),
          note: 'Registered user records',
          color: AppColors.primary,
        ),
        _MetricCard(
          icon: Icons.person_outline,
          title: 'Adult Users',
          value: metrics.adultUsers.toString(),
          note: 'Default fallback category',
          color: Colors.blue,
        ),
        _MetricCard(
          icon: Icons.report_gmailerrorred_outlined,
          title: 'Issue Logs',
          value: metrics.issueLogsAvailable ? metrics.issueLogs.toString() : 'N/A',
          note: metrics.issueLogsAvailable ? 'Prepared for Patch A2' : 'Collection unavailable',
          color: Colors.orange,
        ),
        _MetricCard(
          icon: Icons.auto_graph_outlined,
          title: 'Top Category',
          value: metrics.topCategoryLabel,
          note: 'Most common profile type',
          color: Colors.green,
        ),
      ],
    );
  }
}

class _CategoryDistributionCard extends StatelessWidget {
  final AdminReportMetrics metrics;

  const _CategoryDistributionCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Profile Category Distribution',
      subtitle: 'Shows how users are grouped for difficulty presets.',
      child: Column(
        children:
            ProfileCategory.values.map((category) {
              final count = metrics.countFor(category);
              final percent = metrics.percentFor(category);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _CategoryProgressRow(
                  label: category.label,
                  count: count,
                  percent: percent,
                  color: _categoryColor(category),
                ),
              );
            }).toList(),
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
            ? '${metrics.issueLogs} issue log record(s) found.'
            : 'Issue log collection is not available yet.';

    return _PanelCard(
      title: 'System Health Overview',
      subtitle: 'Basic report readiness for admin monitoring.',
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
            title: 'Issue reporting',
            message: issueText,
            color: Colors.orange,
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

class _RecentUsersCard extends StatelessWidget {
  final List<AdminUserSummary> users;

  const _RecentUsersCard({required this.users});

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Recent User Records',
      subtitle: 'Quick view of the first available user records.',
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
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          child: const Icon(Icons.person_outline, color: AppColors.primary),
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.userId),
                        trailing: Chip(label: Text(user.profileCategory.label)),
                      );
                    }).toList(),
              ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String note;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.note,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(note, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
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

class _CategoryProgressRow extends StatelessWidget {
  final String label;
  final int count;
  final double percent;
  final Color color;

  const _CategoryProgressRow({
    required this.label,
    required this.count,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('$count (${percent.toStringAsFixed(0)}%)'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: percent / 100,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
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

Color _categoryColor(ProfileCategory category) {
  return switch (category) {
    ProfileCategory.child => Colors.purple,
    ProfileCategory.adult => Colors.blue,
    ProfileCategory.senior => Colors.teal,
  };
}

String _formatDateTime(DateTime value) {
  final date = '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  final time = '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
