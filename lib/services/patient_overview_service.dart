import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';
import '../models/adherence_log_model.dart';
import '../models/streak_model.dart';
import '../models/patient_overview_model.dart';
import 'firebase_service.dart';

class PatientOverviewService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;

  // Get patient's reminders
  Future<List<ReminderModel>> getPatientReminders(String patientId) async {
    final snapshot = await _firestore
        .collection('reminders')
        .where('userId', isEqualTo: patientId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ReminderModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Get patient's today logs
  Future<List<AdherenceLogModel>> getPatientTodayLogs(String patientId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('adherence_logs')
        .where('userId', isEqualTo: patientId)
        .where('scheduledTime', isGreaterThanOrEqualTo: startOfDay)
        .where('scheduledTime', isLessThan: endOfDay)
        .get();

    return snapshot.docs
        .map((doc) => AdherenceLogModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Get patient's streak
  Future<StreakModel?> getPatientStreak(String patientId) async {
    final snapshot = await _firestore
        .collection('streaks')
        .where('userId', isEqualTo: patientId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return StreakModel.fromMap(
      snapshot.docs.first.id,
      snapshot.docs.first.data(),
    );
  }

  // Get full patient overview
  Future<PatientOverviewModel> getPatientOverview({
    required String patientId,
    required String patientName,
  }) async {
    final results = await Future.wait([
      getPatientReminders(patientId),
      getPatientTodayLogs(patientId),
      getPatientStreak(patientId),
    ]);

    return PatientOverviewModel(
      patientId: patientId,
      patientName: patientName,
      reminders: results[0] as List<ReminderModel>,
      todayLogs: results[1] as List<AdherenceLogModel>,
      streak: results[2] as StreakModel?,
      lastUpdated: DateTime.now(),
    );
  }

  // Stream patient overview (real-time updates)
  Stream<PatientOverviewModel> streamPatientOverview({
    required String patientId,
    required String patientName,
  }) {
    // Use a controller to combine multiple streams
    return _firestore
        .collection('adherence_logs')
        .where('userId', isEqualTo: patientId)
        .snapshots()
        .asyncMap(
          (_) => getPatientOverview(
            patientId: patientId,
            patientName: patientName,
          ),
        );
  }

  // Get weekly adherence data (last 7 days)
  Future<List<DayAdherence>> getWeeklyAdherence(String patientId) async {
    final now = DateTime.now();
    final List<DayAdherence> weeklyData = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('adherence_logs')
          .where('userId', isEqualTo: patientId)
          .where('scheduledTime', isGreaterThanOrEqualTo: startOfDay)
          .where('scheduledTime', isLessThan: endOfDay)
          .get();

      final logs = snapshot.docs
          .map((doc) => AdherenceLogModel.fromMap(doc.id, doc.data()))
          .toList();

      final taken = logs
          .where((log) => log.status == AdherenceStatus.taken)
          .length;
      final skipped = logs
          .where((log) => log.status == AdherenceStatus.skipped)
          .length;
      final total = logs.length;

      weeklyData.add(
        DayAdherence(
          date: startOfDay,
          taken: taken,
          skipped: skipped,
          total: total,
        ),
      );
    }

    return weeklyData;
  }
}

class DayAdherence {
  final DateTime date;
  final int taken;
  final int skipped;
  final int total;

  DayAdherence({
    required this.date,
    required this.taken,
    required this.skipped,
    required this.total,
  });

  double get rate => total == 0 ? 0.0 : taken / total;
  bool get hasData => total > 0;
}
