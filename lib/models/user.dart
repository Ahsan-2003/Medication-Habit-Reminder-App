class AppUser {
  final String id; // Firebase Auth UID
  final String email;
  final String? inviteCode;
  final List<String> caregiverIds; // users who can see this patient's data
  final List<String> patientIds; // patients this caregiver is linked to

  AppUser({
    required this.id,
    required this.email,
    this.inviteCode,
    this.caregiverIds = const [],
    this.patientIds = const [],
  });

  Map<String, dynamic> toMap() => {
    'email': email,
    'inviteCode': inviteCode,
    'caregiverIds': caregiverIds,
    'patientIds': patientIds,
  };

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
    id: id,
    email: map['email'] ?? '',
    inviteCode: map['inviteCode'],
    caregiverIds: List<String>.from(map['caregiverIds'] ?? []),
    patientIds: List<String>.from(map['patientIds'] ?? []),
  );
}
