import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/caregiver_link_model.dart';
import '../models/reminder_model.dart';
import '../models/adherence_log_model.dart';
import '../providers/patient_overview_provider.dart';
import '../services/patient_overview_service.dart';

class CaregiverPatientViewScreen extends StatefulWidget {
  final CaregiverLinkModel link;

  const CaregiverPatientViewScreen({super.key, required this.link});

  @override
  State<CaregiverPatientViewScreen> createState() =>
      _CaregiverPatientViewScreenState();
}

class _CaregiverPatientViewScreenState
    extends State<CaregiverPatientViewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientOverviewProvider>().loadPatientOverview(
        patientId: widget.link.patientId,
        patientName: widget.link.patientName,
      );
    });
  }

  @override
  void dispose() {
    // Clear when leaving
    Future.microtask(() {
      if (mounted) {
        context.read<PatientOverviewProvider>().clear();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientOverviewProvider>();
    final overview = provider.overview;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.link.patientName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => provider.refresh(),
          ),
        ],
      ),
      body: provider.isLoading && overview == null
          ? const Center(child: CircularProgressIndicator())
          : overview == null
          ? _buildErrorState(provider)
          : RefreshIndicator(
              onRefresh: () => provider.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReadOnlyBanner(),
                    _buildPatientHeader(overview),
                    _buildStreakSection(overview),
                    _buildTodayStats(overview),
                    _buildWeeklyChart(provider.weeklyData),
                    _buildRemindersSection(overview),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReadOnlyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.visibility, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Read-only view — You cannot edit reminders',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientHeader(dynamic overview) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Text(
              overview.patientName.isNotEmpty
                  ? overview.patientName[0].toUpperCase()
                  : 'P',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overview.patientName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Linked Patient',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(overview.adherenceRate * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Today',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(dynamic overview) {
    final currentStreak = overview.currentStreak as int;
    final longestStreak = overview.longestStreak as int;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          _buildStreakStat(
            emoji: '🔥',
            value: '$currentStreak',
            label: 'Current Streak',
            color: Colors.orange,
          ),
          Container(width: 1, height: 50, color: Colors.grey.withOpacity(0.2)),
          _buildStreakStat(
            emoji: '🏆',
            value: '$longestStreak',
            label: 'Longest',
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat({
    required String emoji,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTodayStats(dynamic overview) {
    final taken = overview.takenCount as int;
    final skipped = overview.skippedCount as int;
    final pending = overview.pendingCount as int;
    final total = overview.reminders.length as int;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.today, size: 20, color: Colors.teal),
              SizedBox(width: 8),
              Text(
                "Today's Progress",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBox(
                value: '$taken',
                label: 'Taken',
                color: Colors.green,
                icon: Icons.check_circle,
              ),
              const SizedBox(width: 8),
              _buildStatBox(
                value: '$skipped',
                label: 'Skipped',
                color: Colors.red,
                icon: Icons.cancel,
              ),
              const SizedBox(width: 8),
              _buildStatBox(
                value: '$pending',
                label: 'Pending',
                color: Colors.orange,
                icon: Icons.schedule,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total > 0 ? taken / total : 0,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.green),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$taken of $total reminders completed',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(List<DayAdherence> weeklyData) {
    if (weeklyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, size: 20, color: Colors.teal),
              SizedBox(width: 8),
              Text(
                'Last 7 Days',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyData.map((day) {
                final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final dayLabel = dayLabels[day.date.weekday - 1];
                final rate = day.rate;
                final barHeight = day.hasData ? 80 * rate : 8.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (day.hasData)
                      Text(
                        '${day.taken}/${day.total}',
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: barHeight.clamp(8, 80),
                      decoration: BoxDecoration(
                        color: !day.hasData
                            ? Colors.grey.withOpacity(0.2)
                            : rate == 1.0
                            ? Colors.green
                            : rate >= 0.5
                            ? Colors.orange
                            : Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSection(dynamic overview) {
    final reminders = overview.reminders as List<ReminderModel>;

    if (reminders.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No reminders yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.medication, size: 20, color: Colors.teal),
              SizedBox(width: 8),
              Text(
                "Today's Reminders",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...reminders.map((reminder) {
          final status =
              overview.getStatusForReminder(reminder.id) as AdherenceStatus?;
          final actionTime =
              overview.getActionTimeForReminder(reminder.id) as DateTime?;
          return _buildReminderCard(reminder, status, actionTime);
        }),
      ],
    );
  }

  Widget _buildReminderCard(
    ReminderModel reminder,
    AdherenceStatus? status,
    DateTime? actionTime,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: status != null
            ? Border.all(color: status.statusColor.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '🕐 ${reminder.timesDisplay}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (reminder.dosage != null && reminder.dosage!.isNotEmpty)
                  Text(
                    '💊 ${reminder.dosage}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          if (status != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: status.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${status.statusIcon} ${status.statusDisplayName}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: status.statusColor,
                    ),
                  ),
                ),
                if (actionTime != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(actionTime),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '⏳ Pending',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(PatientOverviewProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load patient data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
