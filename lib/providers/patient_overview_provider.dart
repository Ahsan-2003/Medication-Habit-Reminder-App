import 'package:flutter/material.dart';
import '../models/patient_overview_model.dart';
import '../services/patient_overview_service.dart';

class PatientOverviewProvider extends ChangeNotifier {
  final PatientOverviewService _service = PatientOverviewService();

  PatientOverviewModel? _overview;
  List<DayAdherence> _weeklyData = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentPatientId;

  PatientOverviewModel? get overview => _overview;
  List<DayAdherence> get weeklyData => _weeklyData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load patient overview
  Future<void> loadPatientOverview({
    required String patientId,
    required String patientName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _currentPatientId = patientId;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getPatientOverview(
          patientId: patientId,
          patientName: patientName,
        ),
        _service.getWeeklyAdherence(patientId),
      ]);

      _overview = results[0] as PatientOverviewModel;
      _weeklyData = results[1] as List<DayAdherence>;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh current patient
  Future<void> refresh() async {
    if (_currentPatientId == null || _overview == null) return;

    await loadPatientOverview(
      patientId: _currentPatientId!,
      patientName: _overview!.patientName,
    );
  }

  // Clear data when leaving
  void clear() {
    _overview = null;
    _weeklyData = [];
    _currentPatientId = null;
    _errorMessage = null;
    notifyListeners();
  }
}
