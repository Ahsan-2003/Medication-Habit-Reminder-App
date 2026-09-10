import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';
import '../services/notification_service.dart';

class ReminderProvider extends ChangeNotifier {
  final ReminderService _reminderService = ReminderService();
  final NotificationService _notificationService = NotificationService();

  List<ReminderModel> _reminders = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _notificationsEnabled = false;

  List<ReminderModel> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get notificationsEnabled => _notificationsEnabled;

  // Initialize notification service
  Future<void> initializeNotifications() async {
    await _notificationService.initialize();
    _notificationsEnabled = await _notificationService.requestPermissions();
    notifyListeners();
  }

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

      final createdReminder = await _reminderService.createReminder(reminder);

      // Schedule notifications for the reminder
      if (_notificationsEnabled) {
        // Cancel any existing first (safety)
        await _notificationService.cancelReminderNotifications(
          createdReminder.id,
        );
        // Then schedule
        await _notificationService.scheduleReminderNotifications(
          createdReminder,
        );
      }

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

      // Reschedule notifications
      if (_notificationsEnabled) {
        await _notificationService.cancelReminderNotifications(reminder.id);
        await _notificationService.scheduleReminderNotifications(reminder);
      }

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

      print('🗑️ Provider: Deleting reminder: $reminderId');

      await _reminderService.deleteReminder(reminderId);

      // Cancel notifications
      if (_notificationsEnabled) {
        await _notificationService.cancelReminderNotifications(reminderId);
      }

      // Remove from local list immediately
      _reminders.removeWhere((r) => r.id == reminderId);

      _isLoading = false;
      notifyListeners();

      print('✅ Provider: Reminder deleted successfully');
      return true;
    } catch (e) {
      print('❌ Provider: Failed to delete: $e');
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

      // Cancel or reschedule notifications
      if (_notificationsEnabled) {
        if (isActive) {
          final reminder = _reminders.firstWhere((r) => r.id == reminderId);
          await _notificationService.scheduleReminderNotifications(reminder);
        } else {
          await _notificationService.cancelReminderNotifications(reminderId);
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Show test notification
  Future<void> showTestNotification() async {
    await _notificationService.showTestNotification();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
