import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/alert_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final alertProvider = context.read<AlertProvider>();

      if (authProvider.currentUser != null) {
        if (authProvider.currentUser!.role == 'caregiver') {
          alertProvider.loadCaregiverAlerts(authProvider.currentUser!.id);
        } else {
          alertProvider.loadPatientAlerts(authProvider.currentUser!.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isCaregiver = authProvider.currentUser?.role == 'caregiver';

    return Scaffold(
      appBar: AppBar(
        title: Text(isCaregiver ? 'Alerts' : 'Alert History'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: alertProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : alertProvider.alerts.isEmpty
          ? _buildEmptyState(isCaregiver)
          : _buildAlertList(alertProvider.alerts, isCaregiver),
    );
  }

  Widget _buildEmptyState(bool isCaregiver) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isCaregiver ? 'No Missed Doses' : 'No Alerts',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              isCaregiver
                  ? 'Your patient has not missed any doses. Great job!'
                  : 'You have not missed any doses. Keep up the great work!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertList(List<Map<String, dynamic>> alerts, bool isCaregiver) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertCard(alert);
      },
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final reminderName = alert['reminderName'] ?? 'Reminder';
    final patientName = alert['patientName'] ?? '';
    final scheduledTime = alert['scheduledTime'] != null
        ? (alert['scheduledTime'] as Timestamp).toDate()
        : null;
    final sentAt = alert['sentAt'] != null
        ? (alert['sentAt'] as Timestamp).toDate()
        : null;
    final graceMinutes = alert['graceMinutes'] ?? 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_amber,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Missed: $reminderName',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (patientName.isNotEmpty)
                        Text(
                          'Patient: $patientName',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Scheduled: ${_formatTime(scheduledTime)}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.notifications, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Alerted: ${_formatTime(sentAt)} (after ${graceMinutes}m grace)',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'unknown';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${time.day}/${time.month}/${time.year} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
