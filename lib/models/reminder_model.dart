import 'package:cloud_firestore/cloud_firestore.dart';

enum ReminderType { medication, habit }

enum ReminderFrequency { daily, specificDays, customInterval }

class ReminderModel {
  final String id;
  final String userId;
  final String name;
  final ReminderType type;
  final String? dosage;
  final String? notes;
  final List<String> times; // List of times like ["08:00", "20:00"]
  final ReminderFrequency frequency;
  final List<int>? daysOfWeek; // 1=Monday, 7=Sunday (if specificDays)
  final int? intervalDays; // For custom interval (e.g., every 2 days)
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReminderModel({
    this.id = '',
    required this.userId,
    required this.name,
    required this.type,
    this.dosage,
    this.notes,
    required this.times,
    required this.frequency,
    this.daysOfWeek,
    this.intervalDays,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'type': type.name,
      'dosage': dosage,
      'notes': notes,
      'times': times,
      'frequency': frequency.name,
      'daysOfWeek': daysOfWeek,
      'intervalDays': intervalDays,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ReminderModel.fromMap(String id, Map<String, dynamic> map) {
    return ReminderModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      type: ReminderType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReminderType.medication,
      ),
      dosage: map['dosage'],
      notes: map['notes'],
      times: List<String>.from(map['times'] ?? []),
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => ReminderFrequency.daily,
      ),
      daysOfWeek: map['daysOfWeek'] != null
          ? List<int>.from(map['daysOfWeek'])
          : null,
      intervalDays: map['intervalDays'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  ReminderModel copyWith({
    String? name,
    ReminderType? type,
    String? dosage,
    String? notes,
    List<String>? times,
    ReminderFrequency? frequency,
    List<int>? daysOfWeek,
    int? intervalDays,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      dosage: dosage ?? this.dosage,
      notes: notes ?? this.notes,
      times: times ?? this.times,
      frequency: frequency ?? this.frequency,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      intervalDays: intervalDays ?? this.intervalDays,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper method to get display string for frequency
  String get frequencyDisplay {
    switch (frequency) {
      case ReminderFrequency.daily:
        return 'Daily';
      case ReminderFrequency.specificDays:
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final selectedDays =
            daysOfWeek?.map((d) => dayNames[d - 1]).join(', ') ?? '';
        return 'Days: $selectedDays';
      case ReminderFrequency.customInterval:
        return 'Every $intervalDays days';
    }
  }

  // Helper method to get display string for times
  String get timesDisplay {
    return times.join(', ');
  }

  // Helper method to get icon based on type
  String get typeIcon {
    switch (type) {
      case ReminderType.medication:
        return '💊';
      case ReminderType.habit:
        return '🎯';
    }
  }
}
