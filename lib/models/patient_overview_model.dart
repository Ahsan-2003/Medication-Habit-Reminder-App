import '../models/reminder_model.dart';
import '../models/adherence_log_model.dart';
import '../models/streak_model.dart';

class PatientOverviewModel {
  final String patientId;
  final String patientName;
  final List<ReminderModel> reminders;
  final List<AdherenceLogModel> todayLogs;
  final StreakModel? streak;
  final DateTime lastUpdated;

  PatientOverviewModel({
    required this.patientId,
    required this.patientName,
    required this.reminders,
    required this.todayLogs,
    this.streak,
    required this.lastUpdated,
  });

  // Today's completion stats
  int get takenCount =>
      todayLogs.where((log) => log.status == AdherenceStatus.taken).length;

  int get skippedCount =>
      todayLogs.where((log) => log.status == AdherenceStatus.skipped).length;

  int get totalLogged => todayLogs.length;

  int get pendingCount => reminders.length - totalLogged;

  double get adherenceRate {
    if (reminders.isEmpty) return 0.0;
    return takenCount / reminders.length;
  }

  int get currentStreak => streak?.currentStreak ?? 0;
  int get longestStreak => streak?.longestStreak ?? 0;

  // Get reminder by ID
  ReminderModel? getReminder(String reminderId) {
    try {
      return reminders.firstWhere((r) => r.id == reminderId);
    } catch (e) {
      return null;
    }
  }

  // Get status for a reminder
  AdherenceStatus? getStatusForReminder(String reminderId) {
    for (var log in todayLogs) {
      if (log.reminderId == reminderId) {
        return log.status;
      }
    }
    return null;
  }

  // Get last action time for a reminder
  DateTime? getActionTimeForReminder(String reminderId) {
    for (var log in todayLogs) {
      if (log.reminderId == reminderId) {
        return log.actionTime;
      }
    }
    return null;
  }
}
