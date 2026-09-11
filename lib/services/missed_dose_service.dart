import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import '../models/adherence_log_model.dart';
import '../models/reminder_model.dart';
import '../models/caregiver_link_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class MissedDoseService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;
  final NotificationService _notificationService = NotificationService();

  // Check a reminder for missed dose and notify caregiver if needed
  Future<void> checkAndNotifyMissedDose({
    required ReminderModel reminder,
    required DateTime scheduledTime,
  }) async {
    try {
      // 1. Check if patient already logged this reminder
      final logSnapshot = await _firestore
          .collection('adherence_logs')
          .where('reminderId', isEqualTo: reminder.id)
          .where('userId', isEqualTo: reminder.userId)
          .where('scheduledTime', isEqualTo: scheduledTime)
          .get();

      // If already logged (taken/skipped), no alert needed
      if (logSnapshot.docs.isNotEmpty) {
        final log = AdherenceLogModel.fromMap(
          logSnapshot.docs.first.id,
          logSnapshot.docs.first.data(),
        );
        if (log.status == AdherenceStatus.taken ||
            log.status == AdherenceStatus.skipped) {
          debugPrint('✅ Reminder already logged, no alert needed');
          return;
        }
      }

      // 2. Find caregiver link for this patient
      final linkSnapshot = await _firestore
          .collection('caregiver_links')
          .where('patientId', isEqualTo: reminder.userId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (linkSnapshot.docs.isEmpty) {
        debugPrint('ℹ️ No caregiver linked, skipping alert');
        return;
      }

      final link = CaregiverLinkModel.fromMap(
        linkSnapshot.docs.first.id,
        linkSnapshot.docs.first.data(),
      );

      // 3. Check if alert is enabled and if grace period has passed
      if (!link.notifyOnMissedDose) {
        debugPrint('ℹ️ Missed dose alerts disabled by patient');
        return;
      }

      final gracePeriod = Duration(minutes: link.missedDoseGraceMinutes);
      final now = DateTime.now();

      if (now.difference(scheduledTime) < gracePeriod) {
        debugPrint('⏳ Grace period not passed yet');
        return;
      }

      // 4. Check if we already sent an alert for this reminder
      final alertSnapshot = await _firestore
          .collection('missed_dose_alerts')
          .where('reminderId', isEqualTo: reminder.id)
          .where('scheduledTime', isEqualTo: scheduledTime)
          .limit(1)
          .get();

      if (alertSnapshot.docs.isNotEmpty) {
        debugPrint('ℹ️ Alert already sent for this reminder');
        return;
      }

      // 5. Record the alert in Firestore
      await _firestore.collection('missed_dose_alerts').add({
        'patientId': reminder.userId,
        'caregiverId': link.caregiverId,
        'reminderId': reminder.id,
        'reminderName': reminder.name,
        'scheduledTime': scheduledTime,
        'sentAt': DateTime.now(),
        'graceMinutes': link.missedDoseGraceMinutes,
      });

      // 6. Send notification to caregiver
      final timeString =
          '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

      await _notificationService.notifyCaregiverMissedDose(
        patientName: link.patientName,
        reminderName: reminder.name,
        scheduledTime: timeString,
        dosage: reminder.dosage ?? '',
      );

      debugPrint('✅ Missed dose alert sent to caregiver');
    } catch (e) {
      debugPrint('❌ Failed to check missed dose: $e');
    }
  }

  // Get alerts for a caregiver
  Stream<List<Map<String, dynamic>>> getCaregiverAlerts(String caregiverId) {
    return _firestore
        .collection('missed_dose_alerts')
        .where('caregiverId', isEqualTo: caregiverId)
        .orderBy('sentAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // Get alerts for a patient
  Stream<List<Map<String, dynamic>>> getPatientAlerts(String patientId) {
    return _firestore
        .collection('missed_dose_alerts')
        .where('patientId', isEqualTo: patientId)
        .orderBy('sentAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }
}
