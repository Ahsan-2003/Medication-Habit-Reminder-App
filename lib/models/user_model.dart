import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { patient, caregiver }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? inviteCode; // Used for patient-caregiver linking later

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.inviteCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.name,
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.patient,
      ),
      inviteCode: map['inviteCode'],
    );
  }
}
