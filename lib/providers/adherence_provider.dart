import 'package:flutter/material.dart';
import '../models/adherence_log_model.dart';
import '../services/adherence_service.dart';

class AdherenceProvider extends ChangeNotifier {
  final AdherenceService _adherenceService = AdherenceService();

  List<AdherenceLogModel> _todayLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AdherenceLogModel> get todayLogs => _todayLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load today's logs
  void loadTodayLogs(String userId) {
    _isLoading = true;
    notifyListeners();

    _adherenceService
        .getTodayLogs(userId)
        .listen(
          (logs) {
            _todayLogs = logs;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Mark reminder as taken
  Future<bool> markAsTaken({
    required String reminderId,
    required String userId,
    required DateTime scheduledTime,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _adherenceService.markAsTaken(
        reminderId: reminderId,
        userId: userId,
        scheduledTime: scheduledTime,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mark reminder as skipped
  Future<bool> markAsSkipped({
    required String reminderId,
    required String userId,
    required DateTime scheduledTime,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _adherenceService.markAsSkipped(
        reminderId: reminderId,
        userId: userId,
        scheduledTime: scheduledTime,
        notes: notes,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mark reminder as snoozed
  Future<bool> markAsSnoozed({
    required String reminderId,
    required String userId,
    required DateTime scheduledTime,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _adherenceService.markAsSnoozed(
        reminderId: reminderId,
        userId: userId,
        scheduledTime: scheduledTime,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Check if log exists for a reminder
  Future<bool> hasExistingLog({
    required String reminderId,
    required DateTime scheduledTime,
  }) async {
    return await _adherenceService.hasExistingLog(
      reminderId: reminderId,
      scheduledTime: scheduledTime,
    );
  }

  // Get status for a reminder at a specific time
  AdherenceStatus? getStatusForReminder(
    String reminderId,
    DateTime scheduledTime,
  ) {
    for (var log in _todayLogs) {
      if (log.reminderId == reminderId &&
          log.scheduledTime.hour == scheduledTime.hour &&
          log.scheduledTime.minute == scheduledTime.minute) {
        return log.status;
      }
    }
    return null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
