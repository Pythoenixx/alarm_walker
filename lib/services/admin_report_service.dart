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
  final String? issueLogsError;
  final Map<ProfileCategory, int> categoryCounts;
  final List<AdminUserSummary> recentUsers;
  final DateTime generatedAt;

  const AdminReportMetrics({
    required this.totalUsers,
    required this.issueLogs,
    required this.usersWithEmail,
    required this.issueLogsAvailable,
    required this.categoryCounts,
    required this.recentUsers,
    required this.generatedAt,
    this.issueLogsError,
  });

  int countFor(ProfileCategory category) => categoryCounts[category] ?? 0;

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

  int get usersMissingEmail => totalUsers - usersWithEmail;

  double get emailCoveragePercent {
    if (totalUsers == 0) return 0;
    return (usersWithEmail / totalUsers) * 100;
  }

  double percentFor(ProfileCategory category) {
    if (totalUsers == 0) return 0;
    return (countFor(category) / totalUsers) * 100;
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

    return AdminReportMetrics(
      totalUsers: users.length,
      issueLogs: issueLogs,
      usersWithEmail: users.where((user) => user.hasEmail).length,
      issueLogsAvailable: issueLogsAvailable,
      issueLogsError: issueLogsError,
      categoryCounts: categoryCounts,
      recentUsers: users.take(5).toList(),
      generatedAt: DateTime.now(),
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
}
