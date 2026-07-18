import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reminder_provider.dart';
import '../utils/helpers.dart';
import 'add_reminder_screen.dart';
import 'caregiver_link_screen.dart';
import 'caregiver_view_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final reminderProv = context.watch<ReminderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('MediHab'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CaregiverLinkScreen()),
            ),
            tooltip: 'Caregiver Link',
          ),
          IconButton(
            icon: Icon(Icons.visibility),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CaregiverViewScreen()),
            ),
            tooltip: 'Caregiver View',
          ),
          IconButton(icon: Icon(Icons.logout), onPressed: () => auth.signOut()),
        ],
      ),
      body: Consumer<ReminderProvider>(
        builder: (ctx, provider, _) {
          final activeReminders = provider.reminders
              .where((r) => r.active)
              .toList();
          if (activeReminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No active reminders.'),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddReminderScreen()),
                    ),
                    child: Text('Add One'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: activeReminders.length,
            itemBuilder: (ctx, idx) {
              final r = activeReminders[idx];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text('${r.name} (${r.dosage})'),
                  subtitle: Text('Time: ${formatTimeOfDay(r.timeOfDay)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => provider.markTaken(r.id, true),
                      ),
                      IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => provider.markTaken(r.id, false),
                      ),
                      Switch(
                        value: r.active,
                        onChanged: (_) => provider.toggleReminder(r.id),
                      ),
                    ],
                  ),
                  onTap: () async {
                    final streak = await provider.getStreak(r.id);
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Streak for ${r.name}'),
                        content: Text('Current streak: $streak days'),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddReminderScreen()),
        ),
      ),
    );
  }
}
