import 'package:flutter/material.dart';
import 'package:medication_reminder_app/services/notification_service.dart';
import 'package:provider/provider.dart';
import '../models/reminder_model.dart';
import '../models/adherence_log_model.dart';
import '../providers/auth_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/adherence_provider.dart';
import '../widgets/reminder_action_dialog.dart';
import 'add_reminder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    final reminderProvider = context.read<ReminderProvider>();
    final adherenceProvider = context.read<AdherenceProvider>();
    final authProvider = context.read<AuthProvider>();

    // Initialize notifications
    await reminderProvider.initializeNotifications();

    // Load reminders and logs
    if (authProvider.currentUser != null) {
      reminderProvider.loadReminders(authProvider.currentUser!.id);
      adherenceProvider.loadTodayLogs(authProvider.currentUser!.id);
    }
  }

  Future<void> _handleReminderAction(
    ReminderModel reminder,
    String action,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final adherenceProvider = context.read<AdherenceProvider>();
    final notificationService = NotificationService();

    if (authProvider.currentUser == null) return;

    final now = DateTime.now();
    bool success = false;

    switch (action) {
      case 'taken':
        success = await adherenceProvider.markAsTaken(
          reminderId: reminder.id,
          userId: authProvider.currentUser!.id,
          scheduledTime: now,
        );
        if (success) {
          // Cancel notification for this reminder
          await notificationService.cancelReminderNotifications(reminder.id);
          _showSnackBar('Marked as taken! 💊', Colors.green);
        }
        break;

      case 'skipped':
        success = await adherenceProvider.markAsSkipped(
          reminderId: reminder.id,
          userId: authProvider.currentUser!.id,
          scheduledTime: now,
        );
        if (success) {
          await notificationService.cancelReminderNotifications(reminder.id);
          _showSnackBar('Marked as skipped', Colors.orange);
        }
        break;

      case 'snoozed':
        success = await adherenceProvider.markAsSnoozed(
          reminderId: reminder.id,
          userId: authProvider.currentUser!.id,
          scheduledTime: now,
        );
        if (success) {
          _showSnackBar('Snoozed for 10 minutes', Colors.blue);
        }
        break;
    }

    if (!success) {
      _showSnackBar(
        adherenceProvider.errorMessage ?? 'Failed to update status',
        Colors.red,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showReminderActionDialog(ReminderModel reminder) async {
    final now = DateTime.now();

    final action = await showDialog<String>(
      context: context,
      builder: (context) =>
          ReminderActionDialog(reminder: reminder, scheduledTime: now),
    );

    if (action != null) {
      await _handleReminderAction(reminder, action);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final adherenceProvider = context.watch<AdherenceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediRemind'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              _showProfileDialog(context, authProvider);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            _buildStreakSummary(context, adherenceProvider),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Reminders",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${reminderProvider.reminders.length} active',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: reminderProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : reminderProvider.reminders.isEmpty
                  ? _buildEmptyState()
                  : _buildReminderList(
                      reminderProvider.reminders,
                      adherenceProvider,
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddReminderScreen()),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStreakSummary(
    BuildContext context,
    AdherenceProvider adherenceProvider,
  ) {
    final takenCount = adherenceProvider.todayLogs
        .where((log) => log.status == AdherenceStatus.taken)
        .length;
    final totalCount = adherenceProvider.todayLogs.length;
    final pendingCount = totalCount - takenCount;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.local_fire_department,
            value: '0',
            label: 'Day Streak',
            color: Colors.orange,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.check_circle,
            value: '$takenCount/$totalCount',
            label: 'Completed',
            color: Colors.green,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.schedule,
            value: '$pendingCount',
            label: 'Pending',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderList(
    List<ReminderModel> reminders,
    AdherenceProvider adherenceProvider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return _buildReminderCard(reminder, adherenceProvider);
      },
    );
  }

  Widget _buildReminderCard(
    ReminderModel reminder,
    AdherenceProvider adherenceProvider,
  ) {
    final now = DateTime.now();
    final status = adherenceProvider.getStatusForReminder(reminder.id, now);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: reminder.type == ReminderType.medication
                ? Colors.blue.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              reminder.typeIcon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                reminder.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (status != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status.statusColor.withOpacity(
                    0.1,
                  ), // No Color() wrapper needed
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${status.statusIcon} ${status.statusDisplayName.toUpperCase()}', // Use statusDisplayName
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: status.statusColor, // No Color() wrapper needed
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '🕐 ${reminder.timesDisplay}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              '📅 ${reminder.frequencyDisplay}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (reminder.dosage != null && reminder.dosage!.isNotEmpty)
              Text(
                '💊 ${reminder.dosage}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick action buttons
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: status == null
                  ? () => _handleReminderAction(reminder, 'taken')
                  : null,
              tooltip: 'Mark as taken',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: status == null
                  ? () => _handleReminderAction(reminder, 'skipped')
                  : null,
              tooltip: 'Skip',
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'action',
                  child: Row(
                    children: [
                      Icon(Icons.more_horiz, size: 20),
                      SizedBox(width: 8),
                      Text('More Actions'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'action') {
                  _showReminderActionDialog(reminder);
                } else if (value == 'edit') {
                  // TODO: Navigate to edit screen
                } else if (value == 'delete') {
                  _showDeleteDialog(reminder);
                }
              },
            ),
          ],
        ),
        onTap: () => _showReminderActionDialog(reminder),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 60, color: Colors.grey.withOpacity(0.3));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'No reminders yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap the + button to add your first reminder',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(ReminderModel reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final reminderProvider = context.read<ReminderProvider>();
              await reminderProvider.deleteReminder(reminder.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reminder deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(authProvider.currentUser?.name ?? 'User'),
              subtitle: Text(authProvider.currentUser?.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: Text(authProvider.currentUser?.role ?? ''),
              subtitle: const Text('Role'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
