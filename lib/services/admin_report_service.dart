import 'package:alarm_walker/models/alarm_model.dart';
import 'package:alarm_walker/models/profile_category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserSummary {
  final String docId;
  final String userId;
  final String name;
  final String email;
  final ProfileCategory profileCategory;

  bool get hasEmail => email.trim().isNotEmpty;
  String get displayEmail => hasEmail ? email : 'Email unavailable';

  const AdminUserSummary({
    required this.docId,
    required this.userId,
    required this.name,
    required this.email,
    required this.profileCategory,
  });
}

class AdminReportMetrics {
  final int totalUsers;
  final int issueLogs;
  final int usersWithEmail;
  final bool issueLogsAvailable;
  final bool usageStatsAvailable;
  final String? issueLogsError;
  final String? usageStatsError;
  final Map<ProfileCategory, int> categoryCounts;
  final List<AdminUserSummary> recentUsers;
  final DateTime generatedAt;

  final int usersWithUsageStats;
  final int totalAlarms;
  final int enabledAlarms;
  final int disabledAlarms;
  final int repeatAlarms;
  final int oneTimeAlarms;
  final int totalWakeLogs;
  final int successfulWakeLogs;
  final int failedWakeLogs;
  final int totalSnoozeCount;
  final int totalDisarmDurationMs;
  final Map<AlarmDisarmMode, int> disarmModeCounts;

  const AdminReportMetrics({
    required this.totalUsers,
    required this.issueLogs,
    required this.usersWithEmail,
    required this.issueLogsAvailable,
    required this.usageStatsAvailable,
    required this.categoryCounts,
    required this.recentUsers,
    required this.generatedAt,
    required this.usersWithUsageStats,
    required this.totalAlarms,
    required this.enabledAlarms,
    required this.disabledAlarms,
    required this.repeatAlarms,
    required this.oneTimeAlarms,
    required this.totalWakeLogs,
    required this.successfulWakeLogs,
    required this.failedWakeLogs,
    required this.totalSnoozeCount,
    required this.totalDisarmDurationMs,
    required this.disarmModeCounts,
    this.issueLogsError,
    this.usageStatsError,
  });

  int countFor(ProfileCategory category) => categoryCounts[category] ?? 0;
  int disarmModeCountFor(AlarmDisarmMode mode) => disarmModeCounts[mode] ?? 0;

  int get childUsers => countFor(ProfileCategory.child);
  int get adultUsers => countFor(ProfileCategory.adult);
  int get seniorUsers => countFor(ProfileCategory.senior);

  ProfileCategory get topCategory {
    var selected = ProfileCategory.adult;
    var highest = -1;

    for (final entry in categoryCounts.entries) {
      if (entry.value > highest) {
        highest = entry.value;
        selected = entry.key;
      }
    }

    return selected;
  }

  String get topCategoryLabel => topCategory.label;

  AlarmDisarmMode get topDisarmMode {
    var selected = AlarmDisarmMode.normal;
    var highest = -1;

    for (final entry in disarmModeCounts.entries) {
      if (entry.value > highest) {
        highest = entry.value;
        selected = entry.key;
      }
    }

    return selected;
  }

  String get topDisarmModeLabel => _modeLabel(topDisarmMode);

  int get usersMissingEmail => totalUsers - usersWithEmail;

  double get emailCoveragePercent {
    if (totalUsers == 0) return 0;
    return (usersWithEmail / totalUsers) * 100;
  }

  double get usageStatsCoveragePercent {
    if (totalUsers == 0) return 0;
    return (usersWithUsageStats / totalUsers) * 100;
  }

  double get alarmEnabledPercent {
    if (totalAlarms == 0) return 0;
    return (enabledAlarms / totalAlarms) * 100;
  }

  double get wakeSuccessRate {
    if (totalWakeLogs == 0) return 0;
    return (successfulWakeLogs / totalWakeLogs) * 100;
  }

  double get averageSnoozeCount {
    if (totalWakeLogs == 0) return 0;
    return totalSnoozeCount / totalWakeLogs;
  }

  double get averageDisarmDurationSeconds {
    if (totalWakeLogs == 0) return 0;
    return (totalDisarmDurationMs / totalWakeLogs) / 1000;
  }

  double percentFor(ProfileCategory category) {
    if (totalUsers == 0) return 0;
    return (countFor(category) / totalUsers) * 100;
  }

  double disarmModePercentFor(AlarmDisarmMode mode) {
    final total = disarmModeCounts.values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) return 0;
    return (disarmModeCountFor(mode) / total) * 100;
  }

  static String modeLabel(AlarmDisarmMode mode) => _modeLabel(mode);

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

class AdminReportService {
  final FirebaseFirestore _firestore;

  AdminReportService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<AdminReportMetrics> loadMetrics() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final users =
        usersSnapshot.docs.map((doc) {
          final data = doc.data();
          return AdminUserSummary(
            docId: doc.id,
            userId: _readText(data, 'userId', fallback: doc.id),
            name: _readText(data, 'name', fallback: 'Unnamed User'),
            email: _readText(data, 'email', fallback: ''),
            profileCategory: ProfileCategory.fromName(
              _readText(data, 'profileCategory', fallback: 'adult'),
            ),
          );
        }).toList();

    final categoryCounts = <ProfileCategory, int>{
      ProfileCategory.child: 0,
      ProfileCategory.adult: 0,
      ProfileCategory.senior: 0,
    };

    for (final user in users) {
      categoryCounts[user.profileCategory] =
          (categoryCounts[user.profileCategory] ?? 0) + 1;
    }

    var issueLogs = 0;
    var issueLogsAvailable = true;
    String? issueLogsError;

    try {
      final issueSnapshot =
          await _firestore.collection('app_issue_logs').limit(200).get();
      issueLogs = issueSnapshot.docs.length;
    } catch (error) {
      issueLogsAvailable = false;
      issueLogsError = error.toString();
    }

    var usageStatsAvailable = true;
    String? usageStatsError;
    var usersWithUsageStats = 0;
    var totalAlarms = 0;
    var enabledAlarms = 0;
    var disabledAlarms = 0;
    var repeatAlarms = 0;
    var oneTimeAlarms = 0;
    var totalWakeLogs = 0;
    var successfulWakeLogs = 0;
    var failedWakeLogs = 0;
    var totalSnoozeCount = 0;
    var totalDisarmDurationMs = 0;
    final disarmModeCounts = <AlarmDisarmMode, int>{
      AlarmDisarmMode.math: 0,
      AlarmDisarmMode.retype: 0,
      AlarmDisarmMode.shake: 0,
      AlarmDisarmMode.walk: 0,
      AlarmDisarmMode.normal: 0,
    };

    try {
      final usageSnapshot =
          await _firestore.collection('user_usage_summaries').limit(500).get();
      usersWithUsageStats = usageSnapshot.docs.length;

      for (final doc in usageSnapshot.docs) {
        final data = doc.data();
        totalAlarms += _readInt(data, 'totalAlarms');
        enabledAlarms += _readInt(data, 'enabledAlarms');
        disabledAlarms += _readInt(data, 'disabledAlarms');
        repeatAlarms += _readInt(data, 'repeatAlarms');
        oneTimeAlarms += _readInt(data, 'oneTimeAlarms');
        totalWakeLogs += _readInt(data, 'totalWakeLogs');
        successfulWakeLogs += _readInt(data, 'successfulWakeLogs');
        failedWakeLogs += _readInt(data, 'failedWakeLogs');
        totalSnoozeCount += _readInt(data, 'totalSnoozeCount');
        totalDisarmDurationMs += _readInt(data, 'totalDisarmDurationMs');

        final rawCounts = data['disarmModeCounts'];
        if (rawCounts is Map) {
          for (final entry in rawCounts.entries) {
            final mode = AlarmDisarmModeX.fromDb(entry.key.toString());
            final count = _toInt(entry.value);
            disarmModeCounts[mode] = (disarmModeCounts[mode] ?? 0) + count;
          }
        }
      }
    } catch (error) {
      usageStatsAvailable = false;
      usageStatsError = error.toString();
    }

    return AdminReportMetrics(
      totalUsers: users.length,
      issueLogs: issueLogs,
      usersWithEmail: users.where((user) => user.hasEmail).length,
      issueLogsAvailable: issueLogsAvailable,
      usageStatsAvailable: usageStatsAvailable,
      issueLogsError: issueLogsError,
      usageStatsError: usageStatsError,
      categoryCounts: categoryCounts,
      recentUsers: users.take(5).toList(),
      generatedAt: DateTime.now(),
      usersWithUsageStats: usersWithUsageStats,
      totalAlarms: totalAlarms,
      enabledAlarms: enabledAlarms,
      disabledAlarms: disabledAlarms,
      repeatAlarms: repeatAlarms,
      oneTimeAlarms: oneTimeAlarms,
      totalWakeLogs: totalWakeLogs,
      successfulWakeLogs: successfulWakeLogs,
      failedWakeLogs: failedWakeLogs,
      totalSnoozeCount: totalSnoozeCount,
      totalDisarmDurationMs: totalDisarmDurationMs,
      disarmModeCounts: disarmModeCounts,
    );
  }

  static String _readText(
    Map<String, dynamic> data,
    String key, {
    required String fallback,
  }) {
    final value = data[key];
    if (value == null) return fallback;

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static int _readInt(Map<String, dynamic> data, String key) {
    return _toInt(data[key]);
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
