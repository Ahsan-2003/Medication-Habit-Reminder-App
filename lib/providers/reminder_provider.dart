import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';

class ReminderProvider extends ChangeNotifier {
  final ReminderService _reminderService = ReminderService();

  List<ReminderModel> _reminders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReminderModel> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load reminders for a user
  void loadReminders(String userId) {
    _isLoading = true;
    notifyListeners();

    _reminderService
        .getUserReminders(userId)
        .listen(
          (reminders) {
            _reminders = reminders;
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

  // Create a new reminder
  Future<bool> createReminder(ReminderModel reminder) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _reminderService.createReminder(reminder);

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

  // Update a reminder
  Future<bool> updateReminder(ReminderModel reminder) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _reminderService.updateReminder(reminder);

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

  // Delete a reminder
  Future<bool> deleteReminder(String reminderId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _reminderService.deleteReminder(reminderId);

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

  // Toggle reminder status
  Future<bool> toggleReminder(String reminderId, bool isActive) async {
    try {
      _errorMessage = null;
      await _reminderService.toggleReminderStatus(reminderId, isActive);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
