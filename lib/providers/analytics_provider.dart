import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/analytics_model.dart';
import '../models/adherence_log_model.dart';
import '../models/reminder_model.dart';
import '../models/streak_model.dart';
import '../services/analytics_service.dart';
import '../services/pdf_service.dart';
import '../services/reminder_service.dart';
import '../services/adherence_service.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _service = AnalyticsService();
  final PdfService _pdfService = PdfService();
  final ReminderService _reminderService = ReminderService();
  final AdherenceService _adherenceService = AdherenceService();
  final FirebaseFirestore _firestore = FirebaseService().firestore;

  AnalyticsSummary? _summary;
  WeeklyAnalytics? _currentWeek;
  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  String? _errorMessage;

  AnalyticsSummary? get summary => _summary;
  WeeklyAnalytics? get currentWeek => _currentWeek;
  bool get isLoading => _isLoading;
  bool get isGeneratingPdf => _isGeneratingPdf;
  String? get errorMessage => _errorMessage;

  Future<void> loadAnalytics(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _service.getAnalyticsSummary(userId);

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      _currentWeek = await _service.getWeeklyAnalytics(
        userId: userId,
        weekStart: weekStart,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<MonthlyAnalytics?> loadMonth({
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      return await _service.getMonthlyAnalytics(
        userId: userId,
        year: year,
        month: month,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> refresh(String userId) async {
    await loadAnalytics(userId);
  }

  // Generate PDF report
  Future<Uint8List?> generateReport({
    required String userId,
    required String patientName,
    required String patientEmail,
    int days = 30,
  }) async {
    try {
      _isGeneratingPdf = true;
      notifyListeners();

      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      // Fetch data in parallel
      final remindersFuture = _reminderService.getUserReminders(userId).first;
      final logsFuture = _adherenceService
          .getUserLogsInRange(userId, start, now.add(const Duration(days: 1)))
          .first;
      final streakFuture = _getStreak(userId);
      final analyticsFuture = _service.getAnalyticsSummary(userId);

      final results = await Future.wait([
        remindersFuture,
        logsFuture,
        streakFuture,
        analyticsFuture,
      ]);

      final reminders = results[0] as List<ReminderModel>;
      final logs = results[1] as List<AdherenceLogModel>;
      final streak = results[2] as StreakModel?;
      final analytics = results[3] as AnalyticsSummary;

      // Generate PDF
      final pdfBytes = await _pdfService.generateAdherenceReport(
        patientName: patientName,
        patientEmail: patientEmail,
        reminders: reminders,
        logs: logs,
        streak: streak,
        analytics: analytics,
        fromDate: start,
        toDate: now,
      );

      _isGeneratingPdf = false;
      notifyListeners();

      return pdfBytes;
    } catch (e) {
      _errorMessage = e.toString();
      _isGeneratingPdf = false;
      notifyListeners();
      return null;
    }
  }

  Future<StreakModel?> _getStreak(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('streaks')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return StreakModel.fromMap(
        snapshot.docs.first.id,
        snapshot.docs.first.data(),
      );
    } catch (e) {
      return null;
    }
  }

  void clear() {
    _summary = null;
    _currentWeek = null;
    _errorMessage = null;
    notifyListeners();
  }
}
