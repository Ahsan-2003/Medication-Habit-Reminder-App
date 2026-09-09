import 'package:flutter/material.dart';
import '../models/reminder_model.dart';

class ReminderActionDialog extends StatelessWidget {
  final ReminderModel reminder;
  final DateTime scheduledTime;

  const ReminderActionDialog({
    super.key,
    required this.reminder,
    required this.scheduledTime,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text(reminder.typeIcon, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(reminder.name, style: const TextStyle(fontSize: 20)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reminder.type == ReminderType.medication &&
              reminder.dosage != null)
            ListTile(
              leading: const Icon(Icons.medication),
              title: Text('Dosage: ${reminder.dosage}'),
            ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(
              'Time: ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}',
            ),
          ),
          if (reminder.notes != null && reminder.notes!.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.notes),
              title: Text(reminder.notes!),
            ),
        ],
      ),
      actions: [
        // Skip button
        TextButton.icon(
          onPressed: () => Navigator.pop(context, 'skipped'),
          icon: const Icon(Icons.close, color: Colors.red),
          label: const Text('Skip', style: TextStyle(color: Colors.red)),
        ),
        // Snooze button
        TextButton.icon(
          onPressed: () => Navigator.pop(context, 'snoozed'),
          icon: const Icon(Icons.snooze, color: Colors.orange),
          label: const Text('Snooze', style: TextStyle(color: Colors.orange)),
        ),
        // Taken button
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, 'taken'),
          icon: const Icon(Icons.check),
          label: const Text('Taken'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
      ],
    );
  }
}
