class Reminder {
  final String id;
  final String name;
  final String dosage;
  final int timeOfDay; // minutes since midnight (0-1439)
  final bool active;
  final String userId;

  Reminder({
    required this.id,
    required this.name,
    required this.dosage,
    required this.timeOfDay,
    this.active = true,
    required this.userId,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'dosage': dosage,
    'timeOfDay': timeOfDay,
    'active': active,
    'userId': userId,
  };

  factory Reminder.fromMap(String id, Map<String, dynamic> map) => Reminder(
    id: id,
    name: map['name'] ?? '',
    dosage: map['dosage'] ?? '',
    timeOfDay: map['timeOfDay'] ?? 0,
    active: map['active'] ?? true,
    userId: map['userId'] ?? '',
  );
}
