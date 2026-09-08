import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // "patient" or "caregiver"
  final String? linkedPatientId; // for caregivers only
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.linkedPatientId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'linkedPatientId': linkedPatientId,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'patient',
      linkedPatientId: map['linkedPatientId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
