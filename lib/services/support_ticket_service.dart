import 'dart:async';

import 'package:alarm_walker/services/app_issue_log_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportTicketService {
  SupportTicketService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'support_tickets';

  final FirebaseFirestore _firestore;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchLatestTickets() {
    return _firestore
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();
  }

  Future<void> submitTicket({
    required String category,
    required String message,
    required String userName,
    int rating = 0,
  }) async {
    final cleanMessage = message.trim();
    final user = FirebaseAuth.instance.currentUser;

    try {
      final buildInfo = await AppIssueLogService.buildInfoFields();
      await _firestore.collection(collectionName).add({
        'category': category,
        'message': cleanMessage,
        'status': 'open',
        'rating': rating,
        'source': 'user_app',
        'userId': user?.uid ?? '',
        'userEmail': user?.email ?? '',
        'userName': userName.trim(),
        ...buildInfo,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'clientCreatedAt': DateTime.now().toIso8601String(),
      });
    } catch (error, stackTrace) {
      unawaited(
        AppIssueLogService.recordError(
          error,
          stackTrace,
          source: 'support_ticket_submit',
          screen: 'HelpFeedbackScreen',
          fatal: false,
        ),
      );
      rethrow;
    }
  }

  Future<void> updateStatus({
    required String ticketId,
    required String status,
  }) async {
    await _firestore.collection(collectionName).doc(ticketId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'resolvedAt': status == 'resolved' ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> deleteTicket(String ticketId) async {
    await _firestore.collection(collectionName).doc(ticketId).delete();
  }
}
