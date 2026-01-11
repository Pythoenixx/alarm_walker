import 'package:alarm_walker/models/wake_up_repository.dart';
import 'package:flutter/material.dart';

class WakeAnalyticsScreen extends StatefulWidget {
  final WakeLogRepository repo;
  final String userId;

  const WakeAnalyticsScreen({
    super.key,
    required this.repo,
    required this.userId,
  });

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
    final logs = await widget.repo.getAllLogs(userId: widget.userId);
    final summary = await widget.repo.getSummary(userId: widget.userId);
    return _AnalyticsData(logs, summary);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Wake Analytics')),
      body: FutureBuilder<_AnalyticsData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SummaryRow(summary: data.summary, theme: theme),
                const SizedBox(height: 16),
                Expanded(child: _WakeLogTable(logs: data.logs, theme: theme)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final Map<String, Object?> summary;
  final ThemeData theme;

  const _SummaryRow({required this.summary, required this.theme});

  @override
  Widget build(BuildContext context) {
    final total = summary['total'] as int? ?? 0;
    final success = summary['success_count'] as int? ?? 0;
    final avg = (summary['avg_disarm_duration'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        _StatCard(label: 'Total', value: total.toString(), theme: theme),
        const SizedBox(width: 12),
        _StatCard(label: 'Success', value: '$success / $total', theme: theme),
        const SizedBox(width: 12),
        _StatCard(label: 'Avg Disarm', value: '${avg}s', theme: theme),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(value, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _WakeLogTable extends StatelessWidget {
  final List<Map<String, Object?>> logs;
  final ThemeData theme;

  const _WakeLogTable({required this.logs, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Success')),
            DataColumn(label: Text('Snooze')),
            DataColumn(label: Text('Disarm')),
          ],
          rows:
              logs.map((row) {
                final success = row['success'] == 1;
                return DataRow(
                  cells: [
                    DataCell(Text(row['wake_time'].toString())),
                    DataCell(Icon(success ? Icons.check : Icons.close)),
                    DataCell(Text(row['snooze_count'].toString())),
                    DataCell(Text('${row['disarm_duration']}s')),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}

class _AnalyticsData {
  final List<Map<String, Object?>> logs;
  final Map<String, Object?> summary;

  _AnalyticsData(this.logs, this.summary);
}
