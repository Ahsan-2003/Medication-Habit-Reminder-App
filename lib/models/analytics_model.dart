class DailyAdherence {
  final DateTime date;
  final int totalScheduled;
  final int taken;
  final int skipped;
  final int missed;

  DailyAdherence({
    required this.date,
    required this.totalScheduled,
    required this.taken,
    required this.skipped,
    required this.missed,
  });

  double get adherenceRate {
    if (totalScheduled == 0) return 0.0;
    return taken / totalScheduled;
  }

  bool get hasData => totalScheduled > 0;

  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class WeeklyAnalytics {
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<DailyAdherence> days;

  WeeklyAnalytics({
    required this.weekStart,
    required this.weekEnd,
    required this.days,
  });

  int get totalTaken => days.fold(0, (sum, d) => sum + d.taken);
  int get totalScheduled => days.fold(0, (sum, d) => sum + d.totalScheduled);
  int get totalSkipped => days.fold(0, (sum, d) => sum + d.skipped);
  int get totalMissed => days.fold(0, (sum, d) => sum + d.missed);

  double get adherenceRate {
    if (totalScheduled == 0) return 0.0;
    return totalTaken / totalScheduled;
  }
}

class MonthlyAnalytics {
  final int year;
  final int month;
  final List<DailyAdherence> days;

  MonthlyAnalytics({
    required this.year,
    required this.month,
    required this.days,
  });

  int get totalTaken => days.fold(0, (sum, d) => sum + d.taken);
  int get totalScheduled => days.fold(0, (sum, d) => sum + d.totalScheduled);
  int get totalSkipped => days.fold(0, (sum, d) => sum + d.skipped);
  int get totalMissed => days.fold(0, (sum, d) => sum + d.missed);
  int get activeDays => days.where((d) => d.hasData).length;

  double get adherenceRate {
    if (totalScheduled == 0) return 0.0;
    return totalTaken / totalScheduled;
  }

  // Best day
  DailyAdherence? get bestDay {
    final daysWithData = days.where((d) => d.hasData).toList();
    if (daysWithData.isEmpty) return null;
    return daysWithData.reduce(
      (a, b) => a.adherenceRate >= b.adherenceRate ? a : b,
    );
  }

  // Worst day
  DailyAdherence? get worstDay {
    final daysWithData = days.where((d) => d.hasData).toList();
    if (daysWithData.isEmpty) return null;
    return daysWithData.reduce(
      (a, b) => a.adherenceRate <= b.adherenceRate ? a : b,
    );
  }
}

class AnalyticsSummary {
  final List<DailyAdherence> last30Days;
  final List<DailyAdherence> last7Days;
  final int currentStreak;
  final int longestStreak;
  final int totalRemindersTaken;
  final int totalRemindersScheduled;

  AnalyticsSummary({
    required this.last30Days,
    required this.last7Days,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalRemindersTaken,
    required this.totalRemindersScheduled,
  });

  double get overallAdherence {
    if (totalRemindersScheduled == 0) return 0.0;
    return totalRemindersTaken / totalRemindersScheduled;
  }

  double get weeklyAdherence {
    if (last7Days.isEmpty) return 0.0;
    final total = last7Days.fold(0, (s, d) => s + d.totalScheduled);
    final taken = last7Days.fold(0, (s, d) => s + d.taken);
    if (total == 0) return 0.0;
    return taken / total;
  }

  double get monthlyAdherence {
    if (last30Days.isEmpty) return 0.0;
    final total = last30Days.fold(0, (s, d) => s + d.totalScheduled);
    final taken = last30Days.fold(0, (s, d) => s + d.taken);
    if (total == 0) return 0.0;
    return taken / total;
  }

  int get perfectDays =>
      last30Days.where((d) => d.hasData && d.adherenceRate == 1.0).length;

  int get missedDays =>
      last30Days.where((d) => d.hasData && d.taken == 0).length;
}
