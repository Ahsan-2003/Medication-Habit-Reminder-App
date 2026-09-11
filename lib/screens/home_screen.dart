import 'package:flutter/material.dart';
import 'package:medication_reminder_app/providers/alert_provider.dart';
import 'package:medication_reminder_app/providers/caregiver_provider.dart';
import 'package:medication_reminder_app/providers/streak_provider.dart';
import 'package:medication_reminder_app/screens/alerts_screen.dart';
import 'package:medication_reminder_app/screens/analytics_screen.dart';
import 'package:medication_reminder_app/screens/caregiver_dashboard_screen.dart';
import 'package:medication_reminder_app/screens/caregiver_invite_screen.dart';
import 'package:medication_reminder_app/screens/edit_reminder_screen.dart';
import 'package:medication_reminder_app/screens/settings_screen.dart';
import 'package:medication_reminder_app/services/notification_service.dart';
import 'package:medication_reminder_app/widgets/app_background.dart';
import 'package:medication_reminder_app/widgets/streak_card.dart';
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
      final user = authProvider.currentUser!;

      if (user.role == 'caregiver') {
        // Caregiver: only load patients & alerts
        caregiverProvider.loadCaregiverLinks(user.id);
        alertProvider.loadCaregiverAlerts(user.id);
      } else {
        // Patient: load all data
        reminderProvider.loadReminders(user.id);
        adherenceProvider.loadTodayLogs(user.id);
        streakProvider.loadStreak(user.id);
        streakProvider.checkAndResetStreak(user.id);
        caregiverProvider.loadPatientLink(user.id);
        alertProvider.loadPatientAlerts(user.id);
      }
    }
  }

  Widget _buildCaregiverHome() {
    final authProvider = context.read<AuthProvider>();
    final userName = authProvider.currentUser?.name ?? 'Caregiver';

    return AppBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Welcome illustration
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade400, Colors.teal.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Greeting
              Text(
                'Welcome, $userName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "You're signed in as a caregiver.\nMonitor your loved ones' adherence from here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // Primary action button
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
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Secondary action button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AlertsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_outlined),
                label: const Text('View Alerts'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: const BorderSide(color: Colors.teal, width: 1.5),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber[700],
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Quick Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTipRow(
                      Icons.link,
                      'Link new patients using their invite code',
                    ),
                    const SizedBox(height: 10),
                    _buildTipRow(
                      Icons.warning_amber,
                      'Get notified when a dose is missed',
                    ),
                    const SizedBox(height: 10),
                    _buildTipRow(
                      Icons.bar_chart,
                      'Track adherence trends in analytics',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final adherenceProvider = context.watch<AdherenceProvider>();
    final streakProvider = context.watch<StreakProvider>();

    final isCaregiver = authProvider.currentUser?.role == 'caregiver';

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediRemind'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Analytics
          // Analytics (only for patients)
          if (!isCaregiver)
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

          // Caregiver / Patients
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: isCaregiver ? 'My Patients' : 'Caregiver',
            onPressed: () {
              if (isCaregiver) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CaregiverDashboardScreen(),
                  ),
                );
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

          // Overflow menu
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
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    const Text('Refresh'),
                  ],
                ),
              ),

              // Alerts
              PopupMenuItem(
                value: 'alerts',
                child: Row(
                  children: [
                    Consumer<AlertProvider>(
                      builder: (context, alertProvider, _) {
                        return Stack(
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
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
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    const Text('Profile'),
                  ],
                ),
              ),

              // Settings
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    const Text('Settings'),
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

      // ⭐ Role-based body
      body: isCaregiver
          ? _buildCaregiverHome()
          : _buildPatientHome(
              authProvider,
              reminderProvider,
              adherenceProvider,
              streakProvider,
            ),

      // ⭐ Role-based FAB (hidden for caregivers)
      floatingActionButton: isCaregiver
          ? null
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

  Widget _buildPatientHome(
    AuthProvider authProvider,
    ReminderProvider reminderProvider,
    AdherenceProvider adherenceProvider,
    StreakProvider streakProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF121212), const Color(0xFF1E1E1E)]
              : [Colors.teal.shade50, Colors.white],
        ),
      ),
      child: Column(
        children: [
          StreakCard(
            streak: streakProvider.streak,
            weeklyData: streakProvider.weeklyData,
          ),
          _buildDailyStats(adherenceProvider),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Reminders",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${reminderProvider.reminders.length} active',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: reminderProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : reminderProvider.reminders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: reminderProvider.reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = reminderProvider.reminders[index];
                      return _buildReminderCard(reminder, adherenceProvider);
                    },
                  ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSmallStat(
            icon: Icons.check_circle,
            value: '$takenCount',
            label: 'Taken',
            color: const Color(0xFF2E7D32),
          ),
          _verticalDivider(),
          _buildSmallStat(
            icon: Icons.schedule,
            value: '$pendingCount',
            label: 'Pending',
            color: const Color(0xFFF57C00),
          ),
          _verticalDivider(),
          _buildSmallStat(
            icon: Icons.list_alt,
            value: '$totalCount',
            label: 'Total',
            color: const Color(0xFF1565C0),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.grey.withOpacity(0.15),
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
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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

  Widget _buildReminderCard(
    ReminderModel reminder,
    AdherenceProvider adherenceProvider,
  ) {
    final now = DateTime.now();
    final status = adherenceProvider.getStatusForReminder(reminder.id, now);
    final isTaken = status == AdherenceStatus.taken;
    final isSkipped = status == AdherenceStatus.skipped;
    final isSnoozed = status == AdherenceStatus.snoozed;
    final isPending = status == null;

    // Accent color based on status
    final accentColor = isTaken
        ? const Color(0xFF2E7D32)
        : isSkipped
        ? const Color(0xFFC62828)
        : isSnoozed
        ? const Color(0xFFF57C00)
        : const Color(0xFF00897B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: accentColor, width: 5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.06,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showReminderActionDialog(reminder),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: icon + name + status ──
                Row(
                  children: [
                    // Icon container with gradient
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: reminder.type == ReminderType.medication
                              ? [
                                  const Color(0xFF42A5F5),
                                  const Color(0xFF1565C0),
                                ]
                              : [
                                  const Color(0xFF66BB6A),
                                  const Color(0xFF2E7D32),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (reminder.type == ReminderType.medication
                                        ? const Color(0xFF1565C0)
                                        : const Color(0xFF2E7D32))
                                    .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          reminder.typeIcon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Name + time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 13,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                reminder.timesDisplay,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  reminder.frequencyDisplay,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status badge or more menu
                    if (status != null)
                      _buildModernStatusBadge(status)
                    else
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.more_vert,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),

                // ── Middle: dosage / notes chip row ──
                if (reminder.dosage != null && reminder.dosage!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.medication_outlined,
                          size: 14,
                          color: Color(0xFF1565C0),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          reminder.dosage!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Bottom: Action buttons (if pending) ──
                if (isPending) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Taken button
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.check_circle,
                          label: 'Taken',
                          color: const Color(0xFF2E7D32),
                          onTap: () => _handleReminderAction(reminder, 'taken'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Skip button
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.close,
                          label: 'Skip',
                          color: const Color(0xFFC62828),
                          onTap: () =>
                              _handleReminderAction(reminder, 'skipped'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Snooze button
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.snooze,
                          label: 'Snooze',
                          color: const Color(0xFFF57C00),
                          onTap: () =>
                              _handleReminderAction(reminder, 'snoozed'),
                        ),
                      ),
                    ],
                  ),
                ],

                // ── If actioned, show action time ──
                if (!isPending) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Action recorded',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern status badge
  Widget _buildModernStatusBadge(AdherenceStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: status.statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status.statusIcon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            status.statusDisplayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: status.statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // Action button builder
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
