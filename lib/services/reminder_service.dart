import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import 'firebase_service.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;

  // Create a new reminder
  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('reminders')
          .add(reminder.toMap());

      // Update the reminder with its ID
      ReminderModel updatedReminder = reminder.copyWith(
        updatedAt: DateTime.now(),
      );

      return ReminderModel(
        id: docRef.id,
        userId: updatedReminder.userId,
        name: updatedReminder.name,
        type: updatedReminder.type,
        dosage: updatedReminder.dosage,
        notes: updatedReminder.notes,
        times: updatedReminder.times,
        frequency: updatedReminder.frequency,
        daysOfWeek: updatedReminder.daysOfWeek,
        intervalDays: updatedReminder.intervalDays,
        isActive: updatedReminder.isActive,
        createdAt: updatedReminder.createdAt,
        updatedAt: updatedReminder.updatedAt,
      );
    } catch (e) {
      throw Exception('Failed to create reminder: $e');
    }
  }

  // Get all reminders for a user
  Stream<List<ReminderModel>> getUserReminders(String userId) {
    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReminderModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Get a single reminder
  Future<ReminderModel?> getReminder(String reminderId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('reminders')
          .doc(reminderId)
          .get();
      if (doc.exists) {
        return ReminderModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get reminder: $e');
    }
  }

  // Update a reminder
  Future<void> updateReminder(ReminderModel reminder) async {
    try {
      await _firestore.collection('reminders').doc(reminder.id).update({
        ...reminder.toMap(),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to update reminder: $e');
    }
  }

  // Delete a reminder
  // Delete a reminder
  Future<bool> deleteReminder(String reminderId) async {
    try {
      debugPrint('🗑️ Service: Attempting to delete reminder: $reminderId');

      await _firestore.collection('reminders').doc(reminderId).delete();

      debugPrint('✅ Service: Reminder deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Service: Failed to delete reminder: $e');
      throw Exception('Failed to delete reminder: $e');
    }
  }

  // Toggle reminder active status
  Future<void> toggleReminderStatus(String reminderId, bool isActive) async {
    try {
      await _firestore.collection('reminders').doc(reminderId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to update reminder status: $e');
    }
  }
}
