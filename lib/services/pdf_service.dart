import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/reminder_model.dart';
import '../models/adherence_log_model.dart';
import '../models/streak_model.dart';
import '../models/analytics_model.dart';

class PdfService {
  // Generate adherence report PDF
  Future<Uint8List> generateAdherenceReport({
    required String patientName,
    required String patientEmail,
    required List<ReminderModel> reminders,
    required List<AdherenceLogModel> logs,
    required StreakModel? streak,
    required AnalyticsSummary analytics,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final dateTimeFormat = DateFormat('MMM dd, yyyy HH:mm');

    final start = fromDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = toDate ?? DateTime.now();

    // Compute stats
    final takenCount = logs
        .where((l) => l.status == AdherenceStatus.taken)
        .length;
    final skippedCount = logs
        .where((l) => l.status == AdherenceStatus.skipped)
        .length;
    final totalLogs = logs.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(patientName, patientEmail, start, end, dateFormat),
          pw.SizedBox(height: 20),
          _buildSummaryBox(
            takenCount,
            skippedCount,
            totalLogs,
            streak?.currentStreak ?? 0,
            streak?.longestStreak ?? 0,
          ),
          pw.SizedBox(height: 20),
          _buildAdherenceStats(analytics),
          pw.SizedBox(height: 20),
          _buildRemindersTable(reminders),
          pw.SizedBox(height: 20),
          _buildRecentLogsTable(logs.take(30).toList(), dateTimeFormat),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  // Header section
  pw.Widget _buildHeader(
    String name,
    String email,
    DateTime from,
    DateTime to,
    DateFormat dateFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#00897B'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'MediRemind',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Adherence Report',
            style: pw.TextStyle(color: PdfColors.white, fontSize: 14),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: PdfColors.white, height: 1),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Patient: $name',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 12),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    email,
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Period:',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 10),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${dateFormat.format(from)} - ${dateFormat.format(to)}',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Summary box
  pw.Widget _buildSummaryBox(
    int taken,
    int skipped,
    int total,
    int currentStreak,
    int longestStreak,
  ) {
    final adherenceRate = total == 0
        ? 0
        : (taken / total * 100).toStringAsFixed(0);

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Adherence', '$adherenceRate%'),
              _buildStatItem('Taken', '$taken'),
              _buildStatItem('Skipped', '$skipped'),
              _buildStatItem('Total Logs', '$total'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Current Streak', '$currentStreak days'),
              _buildStatItem('Best Streak', '$longestStreak days'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#00897B'),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  // Adherence stats section
  pw.Widget _buildAdherenceStats(AnalyticsSummary analytics) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Adherence Analysis',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          _buildStatsRow(
            'Last 7 days',
            '${(analytics.weeklyAdherence * 100).toStringAsFixed(0)}%',
          ),
          _buildStatsRow(
            'Last 30 days',
            '${(analytics.monthlyAdherence * 100).toStringAsFixed(0)}%',
          ),
          _buildStatsRow('Perfect days', '${analytics.perfectDays}'),
          _buildStatsRow('Missed days', '${analytics.missedDays}'),
        ],
      ),
    );
  }

  pw.Widget _buildStatsRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Reminders table
  pw.Widget _buildRemindersTable(List<ReminderModel> reminders) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Active Reminders (${reminders.length})',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (reminders.isEmpty)
          pw.Text(
            'No active reminders',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#E0F2F1'),
                ),
                children: [
                  _buildTableCell('Name', isHeader: true),
                  _buildTableCell('Type', isHeader: true),
                  _buildTableCell('Times', isHeader: true),
                  _buildTableCell('Frequency', isHeader: true),
                ],
              ),
              // Rows
              ...reminders.map(
                (reminder) => pw.TableRow(
                  children: [
                    _buildTableCell(reminder.name),
                    _buildTableCell(
                      reminder.type == ReminderType.medication
                          ? 'Medication'
                          : 'Habit',
                    ),
                    _buildTableCell(reminder.timesDisplay),
                    _buildTableCell(reminder.frequencyDisplay),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // Recent logs table
  pw.Widget _buildRecentLogsTable(
    List<AdherenceLogModel> logs,
    DateFormat dateTimeFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Recent Activity (${logs.length} most recent)',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (logs.isEmpty)
          pw.Text(
            'No activity yet',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#E0F2F1'),
                ),
                children: [
                  _buildTableCell('Scheduled Time', isHeader: true),
                  _buildTableCell('Status', isHeader: true),
                  _buildTableCell('Action Time', isHeader: true),
                ],
              ),
              ...logs.map(
                (log) => pw.TableRow(
                  children: [
                    _buildTableCell(dateTimeFormat.format(log.scheduledTime)),
                    _buildTableCell(_statusText(log.status)),
                    _buildTableCell(
                      log.actionTime != null
                          ? dateTimeFormat.format(log.actionTime!)
                          : '-',
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _statusText(AdherenceStatus status) {
    switch (status) {
      case AdherenceStatus.taken:
        return 'Taken';
      case AdherenceStatus.skipped:
        return 'Skipped';
      case AdherenceStatus.snoozed:
        return 'Snoozed';
      case AdherenceStatus.pending:
        return 'Pending';
    }
  }

  // Footer
  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Generated by MediRemind',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Generated on: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'This report is for informational purposes only and does not constitute medical advice. '
            'Please consult with your healthcare provider for medical decisions.',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // Preview PDF (opens print/share dialog)
  Future<void> previewPdf(Uint8List pdfBytes, String filename) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: filename,
    );
  }

  // Share PDF
  Future<void> sharePdf(Uint8List pdfBytes, String filename) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }
}
