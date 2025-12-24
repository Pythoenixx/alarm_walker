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
    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    return DateFormat.jm().format(dateTime);
  }

  String _formatDays(List<int> days) {
    if (days.isEmpty) return 'One time';

    if (days.length == 7) return 'Every day';

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => dayNames[d]).join(', ');
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

  Future<void> _toggleAlarm(AlarmDbEntry alarm) async {
    try {
      final updated = AlarmDbEntry(
        time: alarm.time,
        days: alarm.days,
        enabled: !alarm.enabled,
        body: alarm.body,
      );
      await AlarmDatabase.insertOrUpdate(updated);
      await _loadAlarms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update alarm: $e')));
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
                      'Alarm Database',
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
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
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
              Icons.alarm_off,
              size: 64,
              color:
                  isDark
                      ? AppColors.darkBackgroundText.withOpacity(0.3)
                      : AppColors.lightBackgroundText.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No alarms in database',
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _alarms!.length,
      itemBuilder: (context, index) {
        final alarm = _alarms![index];
        return _AlarmCard(
          alarm: alarm,
          isDark: isDark,
          onToggle: () => _toggleAlarm(alarm),
          onDelete: () => _deleteAlarm(alarm),
          formatTime: _formatTime,
          formatDays: _formatDays,
        );
      },
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final AlarmDbEntry alarm;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final String Function(TimeOfDay) formatTime;
  final String Function(List<int>) formatDays;

  const _AlarmCard({
    required this.alarm,
    required this.isDark,
    required this.onToggle,
    required this.onDelete,
    required this.formatTime,
    required this.formatDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.darkScaffold1.withOpacity(0.5)
                : AppColors.lightContainer1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBlueGrey,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        formatTime(alarm.time),
                        style: AppTextStyles.large(context).copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color:
                              alarm.enabled
                                  ? null
                                  : (isDark
                                      ? AppColors.darkBackgroundText
                                          .withOpacity(0.4)
                                      : AppColors.lightBackgroundText
                                          .withOpacity(0.4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!alarm.enabled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OFF',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDays(alarm.days),
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark
                              ? AppColors.darkBackgroundText.withOpacity(0.7)
                              : AppColors.lightBackgroundText.withOpacity(0.7),
                    ),
                  ),
                  if (alarm.body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? AppColors.darkScaffold2.withOpacity(0.5)
                                : AppColors.lightScaffold2.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        alarm.body,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              isDark
                                  ? AppColors.darkBackgroundText.withOpacity(
                                    0.8,
                                  )
                                  : AppColors.lightBackgroundText.withOpacity(
                                    0.8,
                                  ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: alarm.enabled,
                  onChanged: (_) => onToggle(),
                  activeColor: Colors.blue,
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red.withOpacity(0.7),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
