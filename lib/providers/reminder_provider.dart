import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class ReminderProvider extends ChangeNotifier {
  List<Reminder> _reminders = [];
  List<Reminder> get reminders => _reminders;
  String? userId;

  void init(String userId) {
    userId = userId;
    FirestoreService.getRemindersStream(userId).listen((list) {
      _reminders = list;
      // Reschedule active reminders
      for (var r in _reminders.where((r) => r.active)) {
        NotificationService.scheduleDailyReminder(r);
      }
      notifyListeners();
    });
  }

  Future<void> addReminder(Reminder r) async {
    await FirestoreService.addReminder(r);
  }

  Future<void> toggleReminder(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;
    final updated = _reminders[index].copyWith(
      active: !_reminders[index].active,
    );
    await FirestoreService.updateReminder(updated);
    // Stream will update, but we also manually cancel/reschedule
    if (!updated.active) {
      NotificationService.cancelReminder(updated.id);
    } else {
      NotificationService.scheduleDailyReminder(updated);
    }
  }

  Future<void> markTaken(String reminderId, bool taken) async {
    final now = DateTime.now();
    await FirestoreService.markAdherence(reminderId, now, taken);
  }

  Future<int> getStreak(String reminderId) async {
    final days = 365;
    final adherenceList = await FirestoreService.getAdherenceForLastNDays(
      reminderId,
      days,
    );
    int streak = 0;
    for (int i = 0; i < adherenceList.length; i++) {
      if (adherenceList[i] == true) {
        streak++;
      } else {
        break; // miss, skip, or not logged → break streak
      }
    }
    return streak;
  }
}

// Add copyWith method to Reminder
extension ReminderCopy on Reminder {
  Reminder copyWith({bool? active}) {
    return Reminder(
      id: id,
      name: name,
      dosage: dosage,
      timeOfDay: timeOfDay,
      active: active ?? this.active,
      userId: userId,
    );
  }
}
