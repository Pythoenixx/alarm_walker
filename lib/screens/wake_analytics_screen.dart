import 'package:alarm/alarm.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/wake_log_model.dart';
import 'package:alarm_walker/models/wake_log_repository.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
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
    final logs = await widget.wakeRepo.getAllLogs();
    final summary = await widget.wakeRepo.getSummary();
    await Alarm.getAlarms(); // debug

    return _AnalyticsData(logs, summary);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Scaffold(
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
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Wake Analytics',
                      style: AppTextStyles.large(
                        context,
                      ).copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refresh,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<_AnalyticsData>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load analytics',
                              style: TextStyle(
                                color:
                                    isDark
                                        ? AppColors.darkBackgroundText
                                        : AppColors.lightBackgroundText,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = snapshot.data!;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SummaryCards(summary: data.summary, isDark: isDark),
                          const SizedBox(height: 24),
                          Text(
                            'Wake History',
                            style: AppTextStyles.large(context).copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _WakeLogTable(logs: data.logs, isDark: isDark),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final Map<String, Object?> summary;
  final bool isDark;

  const _SummaryCards({required this.summary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = summary['total'] as int? ?? 0;
    final success = summary['successes'] as int? ?? 0;
    final avg = (summary['avg_duration'] as num?)?.toInt() ?? 0;
    final successRate =
        total > 0 ? (success / total * 100).toStringAsFixed(0) : '0';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.alarm,
                label: 'Total Alarms',
                value: total.toString(),
                isDark: isDark,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                label: 'Success Rate',
                value: '$successRate%',
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
                icon: Icons.timer,
                label: 'Avg Disarm Time',
                value: '${avg}s',
                isDark: isDark,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.done_all,
                label: 'Successful',
                value: '$success / $total',
                isDark: isDark,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkScaffold1.withValues(alpha: 0.5)
                : AppColors.lightContainer1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBlueGrey,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color:
                  isDark
                      ? AppColors.darkBackgroundText
                      : AppColors.lightBackgroundText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color:
                  isDark
                      ? AppColors.darkBackgroundText.withValues(alpha: 0.7)
                      : AppColors.lightBackgroundText.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WakeLogTable extends StatelessWidget {
  final List<WakeLog> logs;
  final bool isDark;

  const _WakeLogTable({required this.logs, required this.isDark});

  String _formatDateTime(DateTime dt) {
    return DateFormat('MMM dd, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color:
              isDark
                  ? AppColors.darkScaffold1.withValues(alpha: 0.5)
                  : AppColors.lightContainer1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBlueGrey,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color:
                  isDark
                      ? AppColors.darkBackgroundText.withValues(alpha: 0.3)
                      : AppColors.lightBackgroundText.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No wake logs yet',
              style: TextStyle(
                fontSize: 16,
                color:
                    isDark
                        ? AppColors.darkBackgroundText.withValues(alpha: 0.6)
                        : AppColors.lightBackgroundText.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBlueGrey,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 56,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 60,
            headingRowColor: WidgetStateProperty.all(
              isDark
                  ? AppColors.darkScaffold1.withValues(alpha: 0.8)
                  : AppColors.lightContainer1,
            ),
            dataRowColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return isDark
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Colors.blue.withValues(alpha: 0.1);
              }
              return isDark
                  ? AppColors.darkScaffold1.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.5);
            }),
            border: TableBorder.symmetric(
              inside: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBlueGrey,
                width: 0.5,
              ),
            ),
            columns: [
              DataColumn(
                label: Text(
                  'DATE & TIME',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color:
                        isDark
                            ? AppColors.darkBackgroundText
                            : AppColors.lightBackgroundText,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'STATUS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color:
                        isDark
                            ? AppColors.darkBackgroundText
                            : AppColors.lightBackgroundText,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'SNOOZES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color:
                        isDark
                            ? AppColors.darkBackgroundText
                            : AppColors.lightBackgroundText,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'DISARM TIME',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color:
                        isDark
                            ? AppColors.darkBackgroundText
                            : AppColors.lightBackgroundText,
                  ),
                ),
              ),
            ],
            rows:
                logs.map((log) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          _formatDateTime(log.wakeTime),
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'monospace',
                            color:
                                isDark
                                    ? AppColors.darkBackgroundText
                                    : AppColors.lightBackgroundText,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                log.success
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color:
                                  log.success
                                      ? Colors.green.withValues(alpha: 0.5)
                                      : Colors.red.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                log.success ? Icons.check_circle : Icons.cancel,
                                size: 16,
                                color: log.success ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                log.success ? 'Success' : 'Failed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      log.success ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? AppColors.darkScaffold2.withValues(
                                      alpha: 0.5,
                                    )
                                    : AppColors.lightScaffold2.withValues(
                                      alpha: 0.3,
                                    ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.snoozeCount.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark
                                      ? AppColors.darkBackgroundText
                                      : AppColors.lightBackgroundText,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${log.disarmDurationMs ~/ 1000}s',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'monospace',
                            color:
                                isDark
                                    ? AppColors.darkBackgroundText.withValues(
                                      alpha: 0.8,
                                    )
                                    : AppColors.lightBackgroundText.withValues(
                                      alpha: 0.8,
                                    ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsData {
  final List<WakeLog> logs;
  final Map<String, Object?> summary;

  _AnalyticsData(this.logs, this.summary);
}
