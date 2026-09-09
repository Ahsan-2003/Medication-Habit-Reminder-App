import 'package:cloud_firestore/cloud_firestore.dart';

enum AdherenceStatus { taken, skipped, snoozed, pending }

class AdherenceLogModel {
  final String id;
  final String reminderId;
  final String userId;
  final DateTime scheduledTime;
  final AdherenceStatus status;
  final DateTime? actionTime;
  final String? notes;

  AdherenceLogModel({
    this.id = '',
    required this.reminderId,
    required this.userId,
    required this.scheduledTime,
    required this.status,
    this.actionTime,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'reminderId': reminderId,
      'userId': userId,
      'scheduledTime': scheduledTime,
      'status': status.name,
      'actionTime': actionTime,
      'notes': notes,
    };
  }

  factory AdherenceLogModel.fromMap(String id, Map<String, dynamic> map) {
    return AdherenceLogModel(
      id: id,
      reminderId: map['reminderId'] ?? '',
      userId: map['userId'] ?? '',
      scheduledTime: (map['scheduledTime'] as Timestamp).toDate(),
      status: AdherenceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AdherenceStatus.pending,
      ),
      actionTime: map['actionTime'] != null
          ? (map['actionTime'] as Timestamp).toDate()
          : null,
      notes: map['notes'],
    );
  }

  AdherenceLogModel copyWith({
    AdherenceStatus? status,
    DateTime? actionTime,
    String? notes,
  }) {
    return AdherenceLogModel(
      id: id,
      reminderId: reminderId,
      userId: userId,
      scheduledTime: scheduledTime,
      status: status ?? this.status,
      actionTime: actionTime ?? this.actionTime,
      notes: notes ?? this.notes,
    );
  }

  // Helper to check if this log is for today
  bool get isToday {
    final now = DateTime.now();
    return scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day;
  }

  // Helper to get status icon
  String get statusIcon {
    switch (status) {
      case AdherenceStatus.taken:
        return '✅';
      case AdherenceStatus.skipped:
        return '❌';
      case AdherenceStatus.snoozed:
        return '⏰';
      case AdherenceStatus.pending:
        return '⏳';
    }
  }

  // Helper to get status color
  int get statusColor {
    switch (status) {
      case AdherenceStatus.taken:
        return 0xFF4CAF50; // Green
      case AdherenceStatus.skipped:
        return 0xFFF44336; // Red
      case AdherenceStatus.snoozed:
        return 0xFFFF9800; // Orange
      case AdherenceStatus.pending:
        return 0xFF9E9E9E; // Grey
    }
  }
}
