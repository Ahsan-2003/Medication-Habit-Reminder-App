import 'package:cloud_firestore/cloud_firestore.dart';

enum LinkStatus { pending, active, revoked }

class CaregiverLinkModel {
  final String id;
  final String patientId;
  final String patientName;
  final String? caregiverId;
  final String? caregiverName;
  final String inviteCode;
  final LinkStatus status;
  final DateTime createdAt;
  final DateTime? linkedAt;
  final bool notifyOnMissedDose;
  final int missedDoseGraceMinutes;

  CaregiverLinkModel({
    this.id = '',
    required this.patientId,
    required this.patientName,
    this.caregiverId,
    this.caregiverName,
    required this.inviteCode,
    this.status = LinkStatus.pending,
    required this.createdAt,
    this.linkedAt,
    this.notifyOnMissedDose = true,
    this.missedDoseGraceMinutes = 30,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'inviteCode': inviteCode,
      'status': status.name,
      'createdAt': createdAt,
      'linkedAt': linkedAt,
      'notifyOnMissedDose': notifyOnMissedDose,
      'missedDoseGraceMinutes': missedDoseGraceMinutes,
    };
  }

  factory CaregiverLinkModel.fromMap(String id, Map<String, dynamic> map) {
    return CaregiverLinkModel(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      caregiverId: map['caregiverId'],
      caregiverName: map['caregiverName'],
      inviteCode: map['inviteCode'] ?? '',
      status: LinkStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => LinkStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      linkedAt: map['linkedAt'] != null
          ? (map['linkedAt'] as Timestamp).toDate()
          : null,
      notifyOnMissedDose: map['notifyOnMissedDose'] ?? true,
      missedDoseGraceMinutes: map['missedDoseGraceMinutes'] ?? 30,
    );
  }

  CaregiverLinkModel copyWith({
    String? caregiverId,
    String? caregiverName,
    LinkStatus? status,
    DateTime? linkedAt,
    bool? notifyOnMissedDose,
    int? missedDoseGraceMinutes,
  }) {
    return CaregiverLinkModel(
      id: id,
      patientId: patientId,
      patientName: patientName,
      caregiverId: caregiverId ?? this.caregiverId,
      caregiverName: caregiverName ?? this.caregiverName,
      inviteCode: inviteCode,
      status: status ?? this.status,
      createdAt: createdAt,
      linkedAt: linkedAt ?? this.linkedAt,
      notifyOnMissedDose: notifyOnMissedDose ?? this.notifyOnMissedDose,
      missedDoseGraceMinutes:
          missedDoseGraceMinutes ?? this.missedDoseGraceMinutes,
    );
  }

  bool get isLinked => status == LinkStatus.active && caregiverId != null;
}
