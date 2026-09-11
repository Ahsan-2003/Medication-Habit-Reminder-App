import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medication_reminder_app/providers/alert_provider.dart';
import 'package:medication_reminder_app/providers/caregiver_provider.dart';
import 'package:medication_reminder_app/providers/streak_provider.dart';
import 'package:medication_reminder_app/providers/theme_provider.dart';
import 'package:medication_reminder_app/screens/alerts_screen.dart';
import 'package:medication_reminder_app/screens/analytics_screen.dart';
import 'package:medication_reminder_app/screens/caregiver_dashboard_screen.dart';
import 'package:medication_reminder_app/screens/caregiver_invite_screen.dart';
import 'package:medication_reminder_app/screens/edit_reminder_screen.dart';
import 'package:medication_reminder_app/screens/settings_screen.dart';
import 'package:medication_reminder_app/services/missed_dose_service.dart';
import 'package:medication_reminder_app/services/notification_service.dart';
import 'package:medication_reminder_app/widgets/streak_card.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
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
    // Delay initialization to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _initializeApp() async {
    final reminderProvider = context.read<ReminderProvider>();
    final adherenceProvider = context.read<AdherenceProvider>();
    final streakProvider = context.read<StreakProvider>();
    final caregiverProvider = context.read<CaregiverProvider>();
    final alertProvider = context.read<AlertProvider>();
    final authProvider = context.read<AuthProvider>();

    await reminderProvider.initializeNotifications();

    if (authProvider.currentUser != null) {
      reminderProvider.loadReminders(authProvider.currentUser!.id);
      adherenceProvider.loadTodayLogs(authProvider.currentUser!.id);
      streakProvider.loadStreak(authProvider.currentUser!.id);
      streakProvider.checkAndResetStreak(authProvider.currentUser!.id);

      if (authProvider.currentUser!.role == 'patient') {
        caregiverProvider.loadPatientLink(authProvider.currentUser!.id);
        alertProvider.loadPatientAlerts(authProvider.currentUser!.id);
      } else {
        caregiverProvider.loadCaregiverLinks(authProvider.currentUser!.id);
        alertProvider.loadCaregiverAlerts(authProvider.currentUser!.id);
      }
    }
  }

  Widget _buildCaregiverHome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.visibility, size: 64, color: Colors.teal),
            ),
            const SizedBox(height: 24),
            const Text(
              'Caregiver Account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap the People icon at the top to view and manage your linked patients.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CaregiverDashboardScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('View My Patients'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Run the 3 alarm tests
  Future<void> _runAlarmTests(BuildContext context) async {
    final plugin = FlutterLocalNotificationsPlugin();

    // Test 1: Exact alarm (15 seconds)
    final exactTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 15));
    print('🧪 TEST 1: Exact alarm at $exactTime');

    try {
      await plugin.zonedSchedule(
        id: 88881,
        title: '🧪 TEST 1: Exact Alarm',
        body: 'This is exactAllowWhileIdle',
        scheduledDate: exactTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminders',
            'Medication Reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'test_exact',
      );
      print('✅ Exact scheduled');
    } catch (e) {
      print('❌ Exact failed: $e');
    }

    // Test 2: Inexact alarm (20 seconds)
    final inexactTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 20));
    print('🧪 TEST 2: Inexact alarm at $inexactTime');

    try {
      await plugin.zonedSchedule(
        id: 88882,
        title: '🧪 TEST 2: Inexact Alarm',
        body: 'This is inexactAllowWhileIdle',
        scheduledDate: inexactTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminders',
            'Medication Reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'test_inexact',
      );
      print('✅ Inexact scheduled');
    } catch (e) {
      print('❌ Inexact failed: $e');
    }

    // Test 3: Short delay (5 seconds)
    final immediateTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 5));
    print('🧪 TEST 3: Immediate alarm at $immediateTime');

    try {
      await plugin.zonedSchedule(
        id: 88883,
        title: '🧪 TEST 3: Short Delay',
        body: 'This is 5 seconds away',
        scheduledDate: immediateTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminders',
            'Medication Reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'test_short',
      );
      print('✅ Short scheduled');
    } catch (e) {
      print('❌ Short failed: $e');
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scheduled 3 tests. Close app NOW!'),
        duration: Duration(seconds: 5),
      ),
    );
  }

  // Show pending notifications dialog
  Future<void> _showPendingNotifications(BuildContext context) async {
    final plugin = FlutterLocalNotificationsPlugin();
    final requests = await plugin.pendingNotificationRequests();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pending: ${requests.length}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: requests.isEmpty
                ? [
                    const Text(
                      '❌ No pending notifications!\n\nThis means scheduling failed.',
                    ),
                  ]
                : requests
                      .map(
                        (r) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'ID: ${r.id}\n'
                              'Title: ${r.title}\n'
                              'Body: ${r.body}\n'
                              'Payload: ${r.payload}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      )
                      .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Confirm logout
  Future<void> _confirmLogout(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authProvider.signOut();
    }
  }

  Future<void> _handleReminderAction(
    ReminderModel reminder,
    String action,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final adherenceProvider = context.read<AdherenceProvider>();
    final streakProvider = context.read<StreakProvider>();
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
          await notificationService.cancelReminderNotifications(reminder.id);
          _showSnackBar('Marked as taken! 💊', Colors.green);
          adherenceProvider.loadTodayLogs(authProvider.currentUser!.id);
          // Recalculate streak
          await streakProvider.recalculateStreak(authProvider.currentUser!.id);
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
          adherenceProvider.loadTodayLogs(authProvider.currentUser!.id);
          await streakProvider.recalculateStreak(authProvider.currentUser!.id);
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
          adherenceProvider.loadTodayLogs(authProvider.currentUser!.id);
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showReminderActionDialog(ReminderModel reminder) async {
    final now = DateTime.now();

    final action = await showDialog<String>(
      context: context,
      builder: (context) =>
          ReminderActionDialog(reminder: reminder, scheduledTime: now),
    );

    if (action != null && mounted) {
      await _handleReminderAction(reminder, action);
    }
  }

  Future<void> _navigateToEditScreen(ReminderModel reminder) async {
    print('✏️ Navigating to edit screen for: ${reminder.name}');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReminderScreen(reminder: reminder),
      ),
    );

    // Reload data when returning from edit screen
    if (result == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      final reminderProvider = context.read<ReminderProvider>();
      final adherenceProvider = context.read<AdherenceProvider>();

      if (authProvider.currentUser != null) {
        reminderProvider.loadReminders(authProvider.currentUser!.id);
        adherenceProvider.loadTodayLogs(authProvider.currentUser!.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final adherenceProvider = context.watch<AdherenceProvider>();
    final streakProvider = context.watch<StreakProvider>();

    print('🔄 Building HomeScreen');
    print('📋 Reminders: ${reminderProvider.reminders.length}');
    print('📊 Today Logs: ${adherenceProvider.todayLogs.length}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediRemind'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ── Analytics ──
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsScreen(),
                ),
              );
            },
          ),

          // ── Caregiver / Patients (role-based) ──
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: authProvider.currentUser?.role == 'caregiver'
                ? 'My Patients'
                : 'Caregiver',
            onPressed: () {
              if (authProvider.currentUser?.role == 'caregiver') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CaregiverDashboardScreen(),
                  ),
                ).then((_) {
                  if (authProvider.currentUser != null) {
                    context.read<CaregiverProvider>().loadCaregiverLinks(
                      authProvider.currentUser!.id,
                    );
                  }
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CaregiverInviteScreen(),
                  ),
                );
              }
            },
          ),

          // ── Overflow Menu ──
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) async {
              switch (value) {
                case 'refresh':
                  if (authProvider.currentUser != null) {
                    reminderProvider.loadReminders(
                      authProvider.currentUser!.id,
                    );
                    adherenceProvider.loadTodayLogs(
                      authProvider.currentUser!.id,
                    );
                    streakProvider.loadStreak(authProvider.currentUser!.id);
                    context.read<AlertProvider>().loadPatientAlerts(
                      authProvider.currentUser!.id,
                    );
                  }
                  break;

                case 'alerts':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AlertsScreen(),
                    ),
                  );
                  break;

                case 'profile':
                  _showProfileDialog(context, authProvider);
                  break;

                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  break;

                case 'logout':
                  _confirmLogout(context, authProvider);
                  break;
              }
            },
            itemBuilder: (context) => [
              // Refresh
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 12),
                    Text('Refresh'),
                  ],
                ),
              ),

              // Alerts with badge
              PopupMenuItem(
                value: 'alerts',
                child: Row(
                  children: [
                    Consumer<AlertProvider>(
                      builder: (context, alertProvider, _) {
                        return Stack(
                          children: [
                            const Icon(Icons.notifications_outlined, size: 20),
                            if (alertProvider.unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 10,
                                    minHeight: 10,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    const Text('Alerts'),
                  ],
                ),
              ),

              const PopupMenuDivider(),

              // Profile
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
              ),

              // Settings
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),

              const PopupMenuDivider(),

              // Logout
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
                : [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: authProvider.currentUser?.role == 'caregiver'
            ? _buildCaregiverHome()
            : Column(
                children: [
                  // REPLACE the streak summary with StreakCard
                  StreakCard(
                    streak: streakProvider.streak,
                    weeklyData: streakProvider.weeklyData,
                  ),
                  // Daily stats
                  _buildDailyStats(adherenceProvider),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Reminders",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${reminderProvider.reminders.length} active',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: reminderProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : reminderProvider.reminders.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: reminderProvider.reminders.length,
                            itemBuilder: (context, index) {
                              final reminder =
                                  reminderProvider.reminders[index];
                              return _buildReminderCard(
                                reminder,
                                adherenceProvider,
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: authProvider.currentUser?.role == 'caregiver'
          ? null // Caregivers don't add reminders
          : FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddReminderScreen(),
                  ),
                );
                if (result == true && authProvider.currentUser != null) {
                  reminderProvider.loadReminders(authProvider.currentUser!.id);
                  adherenceProvider.loadTodayLogs(authProvider.currentUser!.id);
                }
              },
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add),
            ),
    );
  }

  // Add this new method for compact daily stats
  Widget _buildDailyStats(AdherenceProvider adherenceProvider) {
    final takenCount = adherenceProvider.todayLogs
        .where((log) => log.status == AdherenceStatus.taken)
        .length;
    final totalCount = adherenceProvider.todayLogs.length;
    final pendingCount = totalCount - takenCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSmallStat(
            icon: Icons.check_circle,
            value: '$takenCount/$totalCount',
            label: 'Today',
            color: Colors.green,
          ),
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
          _buildSmallStat(
            icon: Icons.schedule,
            value: '$pendingCount',
            label: 'Pending',
            color: Colors.blue,
          ),
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
          _buildSmallStat(
            icon: Icons.local_fire_department,
            value:
                '${adherenceProvider.todayLogs.where((log) => log.status == AdherenceStatus.taken).length}',
            label: 'Done Today',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
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
            if (status != null) _buildStatusBadge(status),
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
                  _navigateToEditScreen(reminder);
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

  Widget _buildStatusBadge(AdherenceStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${status.statusIcon} ${status.statusDisplayName.toUpperCase()}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: status.statusColor,
        ),
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
              final authProvider = context.read<AuthProvider>();

              print('🗑️ Deleting reminder: ${reminder.id}');

              bool success = await reminderProvider.deleteReminder(reminder.id);

              if (mounted) {
                Navigator.pop(context);

                if (success) {
                  // Reload reminders
                  if (authProvider.currentUser != null) {
                    reminderProvider.loadReminders(
                      authProvider.currentUser!.id,
                    );
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reminder deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        reminderProvider.errorMessage ?? 'Failed to delete',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
