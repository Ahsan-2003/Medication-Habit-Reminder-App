import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AdherenceStatus { taken, skipped, snoozed, pending }

extension AdherenceStatusX on AdherenceStatus {
  // Status icon
  String get statusIcon {
    switch (this) {
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

  // Status color
  Color get statusColor {
    switch (this) {
      case AdherenceStatus.taken:
        return Colors.green;
      case AdherenceStatus.skipped:
        return Colors.red;
      case AdherenceStatus.snoozed:
        return Colors.orange;
      case AdherenceStatus.pending:
        return Colors.grey;
    }
  }

  // Status display name
  String get statusDisplayName {
    switch (this) {
      case AdherenceStatus.taken:
        return 'Taken';
      case AdherenceStatus.skipped:
        return 'Skipped';
      case AdherenceStatus.snoozed:
        return 'Snoozed';
      case AdherenceStatus.pending:
        return 'Pending';
    }
  }
}

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

  // Convenience passthroughs to the AdherenceStatus extension,
  // so existing code calling these directly on a log instance still works.
  String get statusIcon => status.statusIcon;
  Color get statusColor => status.statusColor;
  String get statusDisplayName => status.statusDisplayName;
}
