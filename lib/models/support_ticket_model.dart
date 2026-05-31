import 'package:cloud_firestore/cloud_firestore.dart';

/// User-submitted help or feedback record stored in Firestore.
class SupportTicket {
  final String id;
  final String category;
  final String message;
  final String status;
  final int rating;
  final String userId;
  final String userName;
  final String userEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupportTicket({
    required this.id,
    required this.category,
    required this.message,
    required this.status,
    required this.rating,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.createdAt,
    this.updatedAt,
  });

  factory SupportTicket.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return SupportTicket(
      id: doc.id,
      category: _readText(data, 'category', fallback: 'general'),
      message: _readText(data, 'message', fallback: 'No message provided'),
      status: _readText(data, 'status', fallback: 'open'),
      rating: _readInt(data, 'rating'),
      userId: _readText(data, 'userId', fallback: ''),
      userName: _readText(data, 'userName', fallback: 'Unknown user'),
      userEmail: _readText(data, 'userEmail', fallback: ''),
      createdAt: _readDate(data['createdAt']) ?? _readDate(data['clientCreatedAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  String get categoryLabel => SupportTicketCategory.labelFor(category);
  String get statusLabel => status == 'resolved' ? 'Resolved' : 'Open';
  bool get isResolved => status == 'resolved';

  String get userLabel {
    if (userName.trim().isNotEmpty && userEmail.trim().isNotEmpty) {
      return '$userName · $userEmail';
    }
    if (userName.trim().isNotEmpty) return userName;
    if (userEmail.trim().isNotEmpty) return userEmail;
    if (userId.trim().isNotEmpty) return userId;
    return 'Unknown user';
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
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class SupportTicketCategory {
  SupportTicketCategory._();

  static const String alarmProblem = 'alarm_problem';
  static const String accountProblem = 'account_problem';
  static const String backupRestore = 'backup_restore';
  static const String suggestion = 'suggestion';
  static const String general = 'general';

  static const List<String> values = [
    alarmProblem,
    accountProblem,
    backupRestore,
    suggestion,
    general,
  ];

  static String labelFor(String value) {
    return switch (value) {
      alarmProblem => 'Alarm Problem',
      accountProblem => 'Account Problem',
      backupRestore => 'Backup / Restore',
      suggestion => 'Suggestion',
      general => 'General Feedback',
      _ => 'General Feedback',
    };
  }
}
