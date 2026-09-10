import 'package:flutter/material.dart';
import '../services/missed_dose_service.dart';

class AlertProvider extends ChangeNotifier {
  final MissedDoseService _service = MissedDoseService();

  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _alerts.length;

  // Load alerts for caregiver
  void loadCaregiverAlerts(String caregiverId) {
    _isLoading = true;
    notifyListeners();

    _service
        .getCaregiverAlerts(caregiverId)
        .listen(
          (alerts) {
            _alerts = alerts;
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

  // Load alerts for patient
  void loadPatientAlerts(String patientId) {
    _isLoading = true;
    notifyListeners();

    _service
        .getPatientAlerts(patientId)
        .listen(
          (alerts) {
            _alerts = alerts;
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
}
