import 'package:flutter/material.dart';
import '../models/analytics_model.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _service = AnalyticsService();

  AnalyticsSummary? _summary;
  WeeklyAnalytics? _currentWeek;
  bool _isLoading = false;
  String? _errorMessage;

  AnalyticsSummary? get summary => _summary;
  WeeklyAnalytics? get currentWeek => _currentWeek;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load analytics summary
  Future<void> loadAnalytics(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _service.getAnalyticsSummary(userId);

      // Load current week
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      _currentWeek = await _service.getWeeklyAnalytics(
        userId: userId,
        weekStart: weekStart,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load a specific month
  Future<MonthlyAnalytics?> loadMonth({
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      return await _service.getMonthlyAnalytics(
        userId: userId,
        year: year,
        month: month,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Refresh
  Future<void> refresh(String userId) async {
    await loadAnalytics(userId);
  }

  void clear() {
    _summary = null;
    _currentWeek = null;
    _errorMessage = null;
    notifyListeners();
  }
}
