import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:medication_reminder_app/services/pdf_service.dart';
import 'package:provider/provider.dart';
import '../models/analytics_model.dart';
import '../providers/analytics_provider.dart';
import '../providers/auth_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        context.read<AnalyticsProvider>().loadAnalytics(
          authProvider.currentUser!.id,
        );
      }
    });
  }

  Future<void> _exportPdf(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final provider = context.read<AnalyticsProvider>();

    if (authProvider.currentUser == null) return;

    // Show generating indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating report...'),
              ],
            ),
          ),
        ),
      ),
    );

    final pdfBytes = await provider.generateReport(
      userId: authProvider.currentUser!.id,
      patientName: authProvider.currentUser!.name,
      patientEmail: authProvider.currentUser!.email,
      days: 30,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (pdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to generate report'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show preview/share options
    _showPdfOptions(context, pdfBytes);
  }

  void _showPdfOptions(BuildContext context, Uint8List pdfBytes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Adherence Report',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Preview PDF'),
              subtitle: const Text('View and print the report'),
              onTap: () async {
                Navigator.pop(context);
                final pdfService = PdfService();
                final filename =
                    'adherence_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
                await pdfService.previewPdf(pdfBytes, filename);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Share PDF'),
              subtitle: const Text('Send to doctor, family, or save'),
              onTap: () async {
                Navigator.pop(context);
                final pdfService = PdfService();
                final filename =
                    'adherence_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
                await pdfService.sharePdf(pdfBytes, filename);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final summary = provider.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Report',
            onPressed: () => _exportPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final authProvider = context.read<AuthProvider>();
              if (authProvider.currentUser != null) {
                provider.refresh(authProvider.currentUser!.id);
              }
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : summary == null
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                final authProvider = context.read<AuthProvider>();
                if (authProvider.currentUser != null) {
                  await provider.refresh(authProvider.currentUser!.id);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroStats(summary),
                    const SizedBox(height: 16),
                    _buildAdherenceCards(summary),
                    const SizedBox(height: 16),
                    _buildWeeklyChart(summary),
                    const SizedBox(height: 16),
                    _buildMonthlyGrid(summary),
                    const SizedBox(height: 16),
                    _buildInsights(summary),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Data Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start logging your reminders to see your analytics',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStats(AnalyticsSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Overall Adherence',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${(summary.overallAdherence * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeroStat(
                icon: Icons.check_circle,
                value: '${summary.totalRemindersTaken}',
                label: 'Total Taken',
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildHeroStat(
                icon: Icons.local_fire_department,
                value: '${summary.currentStreak}',
                label: 'Current Streak',
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildHeroStat(
                icon: Icons.emoji_events,
                value: '${summary.longestStreak}',
                label: 'Best Streak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildAdherenceCards(AnalyticsSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _buildAdherenceCard(
            title: 'Last 7 Days',
            rate: summary.weeklyAdherence,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAdherenceCard(
            title: 'Last 30 Days',
            rate: summary.monthlyAdherence,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildAdherenceCard({
    required String title,
    required double rate,
    required Color color,
  }) {
    return Container(
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
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            '${(rate * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(AnalyticsSummary summary) {
    return Container(
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
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: summary.last7Days.map((day) {
                final dayNames = [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun',
                ];
                final dayName = dayNames[day.date.weekday - 1];
                final rate = day.adherenceRate;
                final barHeight = day.hasData ? 90.0 * rate : 8.0;
                final isToday = _isSameDay(day.date, DateTime.now());

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (day.hasData)
                        Text(
                          '${(rate * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getRateColor(rate),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: barHeight.clamp(8, 90),
                        decoration: BoxDecoration(
                          color: !day.hasData
                              ? Colors.grey.withOpacity(0.2)
                              : _getRateColor(rate),
                          borderRadius: BorderRadius.circular(6),
                          border: isToday
                              ? Border.all(color: Colors.teal, width: 2)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: isToday ? Colors.teal : Colors.grey,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyGrid(AnalyticsSummary summary) {
    return Container(
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
              Icon(Icons.calendar_month, size: 20, color: Colors.teal),
              SizedBox(width: 8),
              Text(
                'Last 30 Days',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Each square represents a day',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: summary.last30Days.length,
            itemBuilder: (context, index) {
              final day = summary.last30Days[index];
              return Tooltip(
                message:
                    '${day.date.day}/${day.date.month}\n${day.taken}/${day.totalScheduled} taken',
                child: Container(
                  decoration: BoxDecoration(
                    color: !day.hasData
                        ? Colors.grey.withOpacity(0.15)
                        : _getRateColor(day.adherenceRate),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem(Colors.grey.withOpacity(0.15), 'No data'),
              const SizedBox(width: 12),
              _buildLegendItem(Colors.red, 'Missed'),
              const SizedBox(width: 12),
              _buildLegendItem(Colors.orange, 'Partial'),
              const SizedBox(width: 12),
              _buildLegendItem(Colors.green, 'Perfect'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInsights(AnalyticsSummary summary) {
    return Container(
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
              Icon(Icons.lightbulb, size: 20, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Insights',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            icon: Icons.check_circle,
            color: Colors.green,
            title: '${summary.perfectDays} Perfect Days',
            subtitle: 'Days with 100% adherence in the last 30 days',
          ),
          const Divider(height: 20),
          _buildInsightRow(
            icon: Icons.warning,
            color: Colors.red,
            title: '${summary.missedDays} Missed Days',
            subtitle: 'Days with no reminders taken',
          ),
          const Divider(height: 20),
          _buildInsightRow(
            icon: Icons.trending_up,
            color: Colors.blue,
            title: _getTrendText(
              summary.weeklyAdherence,
              summary.monthlyAdherence,
            ),
            subtitle: 'Weekly vs monthly trend',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTrendText(double weekly, double monthly) {
    if (weekly > monthly + 0.05) return 'Improving';
    if (weekly < monthly - 0.05) return 'Needs Attention';
    return 'Consistent';
  }

  Color _getRateColor(double rate) {
    if (rate == 0) return Colors.grey.withOpacity(0.15);
    if (rate < 0.5) return Colors.red;
    if (rate < 1.0) return Colors.orange;
    return Colors.green;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
