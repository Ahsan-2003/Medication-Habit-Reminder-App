import 'package:flutter/material.dart';
import '../models/caregiver_link_model.dart';
import '../services/caregiver_service.dart';

class CaregiverProvider extends ChangeNotifier {
  final CaregiverService _caregiverService = CaregiverService();

  CaregiverLinkModel? _patientLink; // For patients: their own link
  List<CaregiverLinkModel> _caregiverLinks =
      []; // For caregivers: patients they follow
  bool _isLoading = false;
  String? _errorMessage;

  CaregiverLinkModel? get patientLink => _patientLink;
  List<CaregiverLinkModel> get caregiverLinks => _caregiverLinks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLinked => _patientLink?.isLinked ?? false;

  // Load patient's link
  void loadPatientLink(String patientId) {
    _caregiverService
        .getPatientLinkStream(patientId)
        .listen(
          (link) {
            _patientLink = link;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  // Load caregiver's patients
  void loadCaregiverLinks(String caregiverId) {
    _isLoading = true;
    notifyListeners();

    _caregiverService
        .getCaregiverLinks(caregiverId)
        .listen(
          (links) {
            _caregiverLinks = links;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Create invite link
  Future<CaregiverLinkModel?> createInvite({
    required String patientId,
    required String patientName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final link = await _caregiverService.createInviteLink(
        patientId: patientId,
        patientName: patientName,
      );

      _patientLink = link;
      _isLoading = false;
      notifyListeners();
      return link;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Link with invite code
  Future<bool> linkWithCode({
    required String inviteCode,
    required String caregiverId,
    required String caregiverName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _caregiverService.linkWithInviteCode(
        inviteCode: inviteCode,
        caregiverId: caregiverId,
        caregiverName: caregiverName,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Revoke link
  Future<bool> revokeLink(String linkId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _caregiverService.revokeLink(linkId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Unlink (caregiver)
  Future<bool> unlink(String linkId) async {
    return await revokeLink(linkId);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> updateMissedDoseSettings({
    required String linkId,
    required bool notifyOnMissedDose,
    required int graceMinutes,
  }) async {
    try {
      await _caregiverService.updateMissedDoseSettings(
        linkId: linkId,
        notifyOnMissedDose: notifyOnMissedDose,
        graceMinutes: graceMinutes,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
