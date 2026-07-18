import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/reminder.dart';

class CaregiverViewScreen extends StatefulWidget {
  @override
  _CaregiverViewScreenState createState() => _CaregiverViewScreenState();
}

class _CaregiverViewScreenState extends State<CaregiverViewScreen> {
  List<String> _patientIds = [];
  String? _selectedPatientId;
  List<Reminder> _patientReminders = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final caregiverId = context.read<AuthProvider>().firebaseUser!.uid;
    final ids = await FirestoreService.getCaregiverPatientIds(caregiverId);
    setState(() => _patientIds = ids);
  }

  Future<void> _loadRemindersForPatient(String patientId) async {
    final list = await FirestoreService.getRemindersForUser(patientId);
    setState(() => _patientReminders = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Caregiver Dashboard')),
      body: _patientIds.isEmpty
          ? Center(child: Text('No patients linked yet.'))
          : Column(
              children: [
                DropdownButton<String>(
                  hint: Text('Select patient'),
                  value: _selectedPatientId,
                  items: _patientIds
                      .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedPatientId = val);
                    if (val != null) _loadRemindersForPatient(val);
                  },
                ),
                Expanded(
                  child: _patientReminders.isEmpty
                      ? Center(child: Text('No reminders for this patient.'))
                      : ListView.builder(
                          itemCount: _patientReminders.length,
                          itemBuilder: (ctx, idx) {
                            final r = _patientReminders[idx];
                            return ListTile(
                              title: Text(r.name),
                              subtitle: Text(
                                '${r.dosage}  |  Active: ${r.active ? 'Yes' : 'No'}',
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
