import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/adherence_log_model.dart';
import '../models/reminder_model.dart';
import '../models/analytics_model.dart';
import '../models/streak_model.dart';
import 'firebase_service.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;

  // Get analytics summary for a user
  Future<AnalyticsSummary> getAnalyticsSummary(String userId) async {
    final now = DateTime.now();

    // Get data in parallel
    final results = await Future.wait([
      _getDailyAdherence(userId, now.subtract(const Duration(days: 29)), now),
      _getDailyAdherence(userId, now.subtract(const Duration(days: 6)), now),
      _getStreak(userId),
      _getTotalCounts(userId),
    ]);

    final last30 = results[0] as List<DailyAdherence>;
    final last7 = results[1] as List<DailyAdherence>;
    final streak = results[2] as StreakModel?;
    final counts = results[3] as Map<String, int>;

    return AnalyticsSummary(
      last30Days: last30,
      last7Days: last7,
      currentStreak: streak?.currentStreak ?? 0,
      longestStreak: streak?.longestStreak ?? 0,
      totalRemindersTaken: counts['taken'] ?? 0,
      totalRemindersScheduled: counts['total'] ?? 0,
    );
  }

  // Get weekly analytics for a specific week
  Future<WeeklyAnalytics> getWeeklyAnalytics({
    required String userId,
    required DateTime weekStart,
  }) async {
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));
    final days = await _getDailyAdherence(
      userId,
      start,
      end.subtract(const Duration(days: 1)),
    );

    return WeeklyAnalytics(
      weekStart: start,
      weekEnd: end.subtract(const Duration(days: 1)),
      days: days,
    );
  }

  // Get monthly analytics
  Future<MonthlyAnalytics> getMonthlyAnalytics({
    required String userId,
    required int year,
    required int month,
  }) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0); // Last day of month

    final days = await _getDailyAdherence(userId, start, end);

    return MonthlyAnalytics(year: year, month: month, days: days);
  }

  // Internal: Get daily adherence for a date range
  Future<List<DailyAdherence>> _getDailyAdherence(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    // Normalize dates
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    // Get all reminders (for total scheduled count)
    final remindersSnapshot = await _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    final reminders = remindersSnapshot.docs
        .map((doc) => ReminderModel.fromMap(doc.id, doc.data()))
        .toList();

    // Get all adherence logs in range
    final logsSnapshot = await _firestore
        .collection('adherence_logs')
        .where('userId', isEqualTo: userId)
        .where(
          'scheduledTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(normalizedStart),
        )
        .where(
          'scheduledTime',
          isLessThanOrEqualTo: Timestamp.fromDate(normalizedEnd),
        )
        .get();

    final logs = logsSnapshot.docs
        .map((doc) => AdherenceLogModel.fromMap(doc.id, doc.data()))
        .toList();

    // Group logs by date
    final Map<String, List<AdherenceLogModel>> logsByDate = {};
    for (var log in logs) {
      final key =
          '${log.scheduledTime.year}-${log.scheduledTime.month}-${log.scheduledTime.day}';
      logsByDate.putIfAbsent(key, () => []).add(log);
    }

    // Build daily adherence list
    final List<DailyAdherence> result = [];
    DateTime current = normalizedStart;

    while (!current.isAfter(normalizedEnd)) {
      final key = '${current.year}-${current.month}-${current.day}';
      final dayLogs = logsByDate[key] ?? [];

      final taken = dayLogs
          .where((log) => log.status == AdherenceStatus.taken)
          .length;
      final skipped = dayLogs
          .where((log) => log.status == AdherenceStatus.skipped)
          .length;

      // For scheduled count, use logs if available, else count reminders
      // that should have fired on this day
      final scheduledCount = dayLogs.isNotEmpty
          ? dayLogs.length
          : reminders.length; // Approximation

      // Missed = scheduled but not taken or skipped
      final logged = taken + skipped;
      final missed = scheduledCount - logged > 0 ? scheduledCount - logged : 0;

      result.add(
        DailyAdherence(
          date: current,
          totalScheduled: dayLogs.isNotEmpty ? dayLogs.length : 0,
          taken: taken,
          skipped: skipped,
          missed: missed,
        ),
      );

      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  // Internal: Get streak for user
  Future<StreakModel?> _getStreak(String userId) async {
    final snapshot = await _firestore
        .collection('streaks')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return StreakModel.fromMap(
      snapshot.docs.first.id,
      snapshot.docs.first.data(),
    );
  }

  // Internal: Get total counts
  Future<Map<String, int>> _getTotalCounts(String userId) async {
    final snapshot = await _firestore
        .collection('adherence_logs')
        .where('userId', isEqualTo: userId)
        .get();

    int taken = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['status'] == 'taken') taken++;
    }

    return {'taken': taken, 'total': snapshot.docs.length};
  }
}
