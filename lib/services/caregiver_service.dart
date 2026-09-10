import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/caregiver_link_model.dart';
import 'firebase_service.dart';

class CaregiverService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;

  // Generate a random 6-character invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid confusing chars
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // Create invite link (patient side)
  Future<CaregiverLinkModel> createInviteLink({
    required String patientId,
    required String patientName,
  }) async {
    try {
      // Check if patient already has an active/pending invite
      final existing = await _firestore
          .collection('caregiver_links')
          .where('patientId', isEqualTo: patientId)
          .where('status', whereIn: ['pending', 'active'])
          .get();

      // If there's an active link, return it
      for (var doc in existing.docs) {
        final link = CaregiverLinkModel.fromMap(doc.id, doc.data());
        if (link.status == LinkStatus.active) {
          throw Exception('You already have a caregiver linked');
        }
      }

      // If there's a pending invite, return it
      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        return CaregiverLinkModel.fromMap(doc.id, doc.data());
      }

      // Create new invite
      String inviteCode = _generateInviteCode();

      // Ensure code is unique
      int attempts = 0;
      while (attempts < 5) {
        final check = await _firestore
            .collection('caregiver_links')
            .where('inviteCode', isEqualTo: inviteCode)
            .where('status', isEqualTo: 'pending')
            .get();

        if (check.docs.isEmpty) break;

        inviteCode = _generateInviteCode();
        attempts++;
      }

      final link = CaregiverLinkModel(
        patientId: patientId,
        patientName: patientName,
        inviteCode: inviteCode,
        status: LinkStatus.pending,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('caregiver_links')
          .add(link.toMap());

      return CaregiverLinkModel(
        id: docRef.id,
        patientId: link.patientId,
        patientName: link.patientName,
        inviteCode: link.inviteCode,
        status: link.status,
        createdAt: link.createdAt,
      );
    } catch (e) {
      throw Exception('Failed to create invite: $e');
    }
  }

  // Get patient's link (for patient to see their current link status)
  Future<CaregiverLinkModel?> getPatientLink(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('caregiver_links')
          .where('patientId', isEqualTo: patientId)
          .where('status', whereIn: ['pending', 'active'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return CaregiverLinkModel.fromMap(
        snapshot.docs.first.id,
        snapshot.docs.first.data(),
      );
    } catch (e) {
      return null;
    }
  }

  // Stream patient's link
  Stream<CaregiverLinkModel?> getPatientLinkStream(String patientId) {
    return _firestore
        .collection('caregiver_links')
        .where('patientId', isEqualTo: patientId)
        .where('status', whereIn: ['pending', 'active'])
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return CaregiverLinkModel.fromMap(
            snapshot.docs.first.id,
            snapshot.docs.first.data(),
          );
        });
  }

  // Get caregiver's linked patients
  Stream<List<CaregiverLinkModel>> getCaregiverLinks(String caregiverId) {
    return _firestore
        .collection('caregiver_links')
        .where('caregiverId', isEqualTo: caregiverId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CaregiverLinkModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  // Link caregiver using invite code (caregiver side)
  Future<CaregiverLinkModel> linkWithInviteCode({
    required String inviteCode,
    required String caregiverId,
    required String caregiverName,
  }) async {
    try {
      final code = inviteCode.trim().toUpperCase();

      // Find the invite
      final snapshot = await _firestore
          .collection('caregiver_links')
          .where('inviteCode', isEqualTo: code)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw Exception('Invalid or expired invite code');
      }

      final doc = snapshot.docs.first;
      final link = CaregiverLinkModel.fromMap(doc.id, doc.data());

      // Check if caregiver is trying to link to themselves
      if (link.patientId == caregiverId) {
        throw Exception('You cannot link to your own account');
      }

      // Update the link with caregiver info
      final updatedLink = link.copyWith(
        caregiverId: caregiverId,
        caregiverName: caregiverName,
        status: LinkStatus.active,
        linkedAt: DateTime.now(),
      );

      await _firestore
          .collection('caregiver_links')
          .doc(doc.id)
          .update(updatedLink.toMap());

      return updatedLink;
    } catch (e) {
      throw Exception('Failed to link: $e');
    }
  }

  // Revoke link (patient side)
  Future<void> revokeLink(String linkId) async {
    try {
      await _firestore.collection('caregiver_links').doc(linkId).update({
        'status': 'revoked',
        'caregiverId': null,
        'caregiverName': null,
        'linkedAt': null,
      });
    } catch (e) {
      throw Exception('Failed to revoke link: $e');
    }
  }

  // Unlink (caregiver side)
  Future<void> unlink(String linkId) async {
    await revokeLink(linkId);
  }

  // Update missed dose notification settings (patient side)
  Future<void> updateMissedDoseSettings({
    required String linkId,
    required bool notifyOnMissedDose,
    required int graceMinutes,
  }) async {
    try {
      await _firestore.collection('caregiver_links').doc(linkId).update({
        'notifyOnMissedDose': notifyOnMissedDose,
        'missedDoseGraceMinutes': graceMinutes,
      });
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }

  // Delete old/revoked invites
  Future<void> deleteOldInvites(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('caregiver_links')
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'revoked')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete old invites: $e');
    }
  }
}
