import 'package:alarm_walker/services/alarm_database.dart';
import 'package:alarm_walker/extensions/context_extensions.dart';
import 'package:alarm_walker/models/alarm_db_entry.dart';
import 'package:alarm_walker/theme/app_colors.dart';
import 'package:alarm_walker/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({super.key});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  List<AlarmDbEntry>? _alarms;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final alarms = await AlarmDatabase.allAlarms();
      // Sort alarms by time
      alarms.sort((a, b) {
        final aMinutes = a.time.hour * 60 + a.time.minute;
        final bMinutes = b.time.hour * 60 + b.time.minute;
        return aMinutes - bMinutes;
      });

      if (mounted) {
        setState(() {
          _alarms = alarms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load alarms: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDays(List<int> days) {
    if (days.isEmpty) return '';
    return days.join(',');
  }

  Future<void> _deleteAlarm(AlarmDbEntry alarm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Alarm'),
            content: Text('Delete alarm at ${_formatTime(alarm.time)}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await AlarmDatabase.delete(alarm.time);
        await _loadAlarms();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Alarm deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete alarm: $e')));
        }
      }
    }
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
                      'Database',
                      style: AppTextStyles.large(
                        context,
                      ).copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadAlarms,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
              if (_alarms != null && _alarms!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Total Records: ${_alarms!.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark
                              ? AppColors.darkBackgroundText.withOpacity(0.7)
                              : AppColors.lightBackgroundText.withOpacity(0.7),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(child: _buildContent(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadAlarms, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_alarms == null || _alarms!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: 64,
              color:
                  isDark
                      ? AppColors.darkBackgroundText.withOpacity(0.3)
                      : AppColors.lightBackgroundText.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No records in database',
              style: AppTextStyles.large(context).copyWith(
                color:
                    isDark
                        ? AppColors.darkBackgroundText.withOpacity(0.6)
                        : AppColors.lightBackgroundText.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _DatabaseTable(
          alarms: _alarms!,
          isDark: isDark,
          onDelete: _deleteAlarm,
          formatTime: _formatTime,
          formatDays: _formatDays,
        ),
      ),
    );
  }
}

class _DatabaseTable extends StatelessWidget {
  final List<AlarmDbEntry> alarms;
  final bool isDark;
  final Function(AlarmDbEntry) onDelete;
  final String Function(TimeOfDay) formatTime;
  final String Function(List<int>) formatDays;

  const _DatabaseTable({
    required this.alarms,
    required this.isDark,
    required this.onDelete,
    required this.formatTime,
    required this.formatDays,
  });

  @override
  Widget build(BuildContext context) {
    final headerColor =
        isDark
            ? AppColors.darkScaffold1.withOpacity(0.8)
            : AppColors.lightContainer1;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBlueGrey;
    final textColor =
        isDark ? AppColors.darkBackgroundText : AppColors.lightBackgroundText;
    final rowColor =
        isDark
            ? AppColors.darkScaffold1.withOpacity(0.3)
            : Colors.white.withOpacity(0.5);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DataTable(
          headingRowHeight: 56,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 80,
          headingRowColor: WidgetStateProperty.all(headerColor),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.1);
            }
            return rowColor;
          }),
          border: TableBorder.symmetric(
            inside: BorderSide(color: borderColor, width: 0.5),
          ),
          columns: [
            DataColumn(
              label: Expanded(
                child: Text(
                  'TIME',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  'DAYS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  'ENABLED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  'BODY',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text(
                  'ACTIONS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
          rows:
              alarms.asMap().entries.map((entry) {
                final index = entry.key;
                final alarm = entry.value;

                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          formatTime(alarm.time),
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'monospace',
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          formatDays(alarm.days),
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'monospace',
                            color: textColor.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                alarm.enabled
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color:
                                  alarm.enabled
                                      ? Colors.green.withOpacity(0.5)
                                      : Colors.red.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            alarm.enabled ? '1' : '0',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: alarm.enabled ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          alarm.body.isEmpty ? '(empty)' : alarm.body,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                alarm.body.isEmpty
                                    ? textColor.withOpacity(0.4)
                                    : textColor.withOpacity(0.8),
                            fontStyle:
                                alarm.body.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red.withOpacity(0.7),
                          iconSize: 20,
                          onPressed: () => onDelete(alarm),
                          tooltip: 'Delete',
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}
