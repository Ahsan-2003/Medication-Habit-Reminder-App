import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/adherence_log_model.dart';
import '../models/reminder_model.dart';
import 'firebase_service.dart';

class AdherenceService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;

  // Create adherence log
  Future<AdherenceLogModel> createAdherenceLog(AdherenceLogModel log) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('adherence_logs')
          .add(log.toMap());

      return AdherenceLogModel(
        id: docRef.id,
        reminderId: log.reminderId,
        userId: log.userId,
        scheduledTime: log.scheduledTime,
        status: log.status,
        actionTime: log.actionTime,
        notes: log.notes,
      );
    } catch (e) {
      throw Exception('Failed to create adherence log: $e');
    }
  }

  // Update adherence log
  Future<void> updateAdherenceLog(AdherenceLogModel log) async {
    try {
      await _firestore
          .collection('adherence_logs')
          .doc(log.id)
          .update(log.toMap());
    } catch (e) {
      throw Exception('Failed to update adherence log: $e');
    }
  }

  // Get adherence logs for a reminder
  Stream<List<AdherenceLogModel>> getReminderLogs(String reminderId) {
    return _firestore
        .collection('adherence_logs')
        .where('reminderId', isEqualTo: reminderId)
        .orderBy('scheduledTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdherenceLogModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Get today's adherence logs for a user
  Stream<List<AdherenceLogModel>> getTodayLogs(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('adherence_logs')
        .where('userId', isEqualTo: userId)
        .where('scheduledTime', isGreaterThanOrEqualTo: startOfDay)
        .where('scheduledTime', isLessThan: endOfDay)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdherenceLogModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Get adherence logs for a user within date range
  Stream<List<AdherenceLogModel>> getUserLogsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection('adherence_logs')
        .where('userId', isEqualTo: userId)
        .where('scheduledTime', isGreaterThanOrEqualTo: startDate)
        .where('scheduledTime', isLessThan: endDate)
        .orderBy('scheduledTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdherenceLogModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Mark reminder as taken
  Future<AdherenceLogModel> markAsTaken({
    required String reminderId,
    required String userId,
    required DateTime scheduledTime,
  }) async {
    final log = AdherenceLogModel(
      reminderId: reminderId,
      userId: userId,
      scheduledTime: scheduledTime,
      status: AdherenceStatus.taken,
      actionTime: DateTime.now(),
    );

    return await createAdherenceLog(log);
  }

  // Mark reminder as skipped
  Future<AdherenceLogModel> markAsSkipped({
    required String reminderId,
    required String userId,
    required DateTime scheduledTime,
    String? notes,
  }) async {
    final log = AdherenceLogModel(
      reminderId: reminderId,
      userId: userId,
      scheduledTime: scheduledTime,
      status: AdherenceStatus.skipped,
      actionTime: DateTime.now(),
      notes: notes,
    );

    return await createAdherenceLog(log);
  }

  // Mark reminder as snoozed
  Future<AdherenceLogModel> markAsSnoozed({
    required String reminderId,
    required String userId,
    required DateTime scheduledTime,
  }) async {
    final log = AdherenceLogModel(
      reminderId: reminderId,
      userId: userId,
      scheduledTime: scheduledTime,
      status: AdherenceStatus.snoozed,
      actionTime: DateTime.now(),
    );

    return await createAdherenceLog(log);
  }

  // Check if reminder was already logged for a specific time
  Future<bool> hasExistingLog({
    required String reminderId,
    required DateTime scheduledTime,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('adherence_logs')
          .where('reminderId', isEqualTo: reminderId)
          .where('scheduledTime', isEqualTo: scheduledTime)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
