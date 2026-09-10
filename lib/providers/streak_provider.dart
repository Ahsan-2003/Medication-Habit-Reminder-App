import 'package:flutter/material.dart';
import '../models/streak_model.dart';
import '../services/streak_service.dart';
import '../services/adherence_service.dart';

class StreakProvider extends ChangeNotifier {
  final StreakService _streakService = StreakService();
  final AdherenceService _adherenceService = AdherenceService();

  StreakModel? _streak;
  List<bool> _weeklyData = List.filled(7, false);
  bool _isLoading = false;
  String? _errorMessage;

  StreakModel? get streak => _streak;
  List<bool> get weeklyData => _weeklyData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentStreak => _streak?.currentStreak ?? 0;
  int get longestStreak => _streak?.longestStreak ?? 0;

  // Load streak for user
  void loadStreak(String userId) {
    _isLoading = true;
    notifyListeners();

    _streakService
        .getUserStreakStream(userId)
        .listen(
          (streak) {
            _streak = streak;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );

    // Load weekly data
    _loadWeeklyData(userId);
  }

  Future<void> _loadWeeklyData(String userId) async {
    try {
      _weeklyData = await _streakService.getWeeklyStreakData(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Recalculate streak after an action (taken/skipped)
  Future<void> recalculateStreak(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get all adherence logs for the user
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final snapshot = await _adherenceService
          .getUserLogsInRange(
            userId,
            thirtyDaysAgo,
            now.add(const Duration(days: 1)),
          )
          .first;

      // Group by date and check if all reminders were taken
      final Map<String, List<String>> dayStatuses = {};

      for (var log in snapshot) {
        final dateKey =
            '${log.scheduledTime.year}-${log.scheduledTime.month}-${log.scheduledTime.day}';
        dayStatuses.putIfAbsent(dateKey, () => []);
        dayStatuses[dateKey]!.add(log.status.name);
      }

      // A day is "completed" if all reminders that day were taken (not skipped)
      final List<DateTime> completedDates = [];
      for (var entry in dayStatuses.entries) {
        final statuses = entry.value;
        // Consider day complete if all were taken
        if (statuses.every((s) => s == 'taken')) {
          final parts = entry.key.split('-');
          completedDates.add(
            DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            ),
          );
        }
      }

      await _streakService.calculateStreak(
        userId: userId,
        completedDates: completedDates,
        totalAdherenceDays: completedDates.length,
      );

      // Reload weekly data
      await _loadWeeklyData(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check and reset streak if broken
  Future<void> checkAndResetStreak(String userId) async {
    try {
      final isBroken = await _streakService.isStreakBroken(userId);
      if (isBroken) {
        await _streakService.resetStreak(userId);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
