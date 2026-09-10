import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import '../models/reminder_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _canScheduleExactAlarms = false;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    try {
      final TimezoneInfo timezoneInfo =
          await FlutterTimezone.getLocalTimezone();
      final String currentTimeZone = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
      debugPrint('🌍 Timezone set to: $currentTimeZone');
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
      debugPrint('⚠️ Failed to get timezone, using UTC: $e');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createNotificationChannels();

    // ADD THIS LINE
    await _checkExactAlarmPermission();

    _initialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  // Add this method to check exact alarm permission
  Future<void> _checkExactAlarmPermission() async {
    if (!Platform.isAndroid) {
      _canScheduleExactAlarms = true;
      return;
    }

    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        _canScheduleExactAlarms =
            await androidPlugin.canScheduleExactNotifications() ?? false;
        debugPrint('🔔 Can schedule exact alarms: $_canScheduleExactAlarms');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to check exact alarm permission: $e');
      _canScheduleExactAlarms = false;
    }
  }

  // Create notification channels
  Future<void> _createNotificationChannels() async {
    debugPrint('📢 Creating notification channels...');

    const AndroidNotificationChannel medicationChannel =
        AndroidNotificationChannel(
          'medication_reminders',
          'Medication Reminders',
          description: 'Notifications for medication reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

    const AndroidNotificationChannel habitChannel = AndroidNotificationChannel(
      'habit_reminders',
      'Habit Reminders',
      description: 'Notifications for habit reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.createNotificationChannel(medicationChannel);
    await androidImplementation?.createNotificationChannel(habitChannel);

    debugPrint('✅ Notification channels created');
  }

  // Request permissions
  Future<bool> requestPermissions() async {
    debugPrint('🔐 Requesting notification permissions...');

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    final bool? androidPermission = await androidImplementation
        ?.requestNotificationsPermission();
    final bool? iosPermission = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('📱 Android permission: $androidPermission');
    debugPrint('🍎 iOS permission: $iosPermission');

    return (androidPermission ?? true) && (iosPermission ?? true);
  }

  // Schedule notification for a reminder
  Future<void> scheduleReminderNotification({
    required ReminderModel reminder,
    required String time,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final normalizedTime = _normalizeTime(time);

    debugPrint(
      '📅 Scheduling notification for: ${reminder.name} at $normalizedTime',
    );

    final parts = normalizedTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    scheduledDate = _getNextValidDate(reminder, scheduledDate);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = _generateNotificationId(reminder.id, normalizedTime);

    // Determine schedule mode based on permission
    AndroidScheduleMode scheduleMode;
    if (_canScheduleExactAlarms) {
      scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      debugPrint('🎯 Using EXACT scheduling');
    } else {
      scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      debugPrint('⚠️ Using INEXACT scheduling (exact alarm not permitted)');
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: reminder.type == ReminderType.medication
            ? '💊 Medication Reminder'
            : '🎯 Habit Reminder',
        body: _buildNotificationBody(reminder),
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: scheduleMode,
        payload: reminder.id,
      );

      debugPrint(
        '✅ Notification scheduled: ID=$notificationId, Time=$scheduledDate',
      );
    } catch (e) {
      debugPrint('❌ Scheduling failed: $e');

      // Force inexact as last resort
      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: reminder.type == ReminderType.medication
            ? '💊 Medication Reminder'
            : '🎯 Habit Reminder',
        body: _buildNotificationBody(reminder),
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminder.id,
      );

      debugPrint('✅ Retry scheduled (inexact)');
    }
  }

  // Schedule all notifications for a reminder
  Future<void> scheduleReminderNotifications(ReminderModel reminder) async {
    debugPrint('📋 Scheduling all notifications for: ${reminder.name}');
    debugPrint('📋 Times: ${reminder.times}');

    for (String time in reminder.times) {
      await scheduleReminderNotification(reminder: reminder, time: time);
    }
  }

  // Cancel notifications for a reminder
  Future<void> cancelReminderNotifications(String reminderId) async {
    debugPrint('🔕 Cancelling notifications for reminder: $reminderId');

    final pendingNotifications = await _notificationsPlugin
        .pendingNotificationRequests();

    debugPrint(
      '📋 Pending notifications before cancel: ${pendingNotifications.length}',
    );

    for (var notification in pendingNotifications) {
      if (notification.payload == reminderId) {
        await _notificationsPlugin.cancel(id: notification.id);
        debugPrint('❌ Cancelled notification: ${notification.id}');
      }
    }
  }

  // Show immediate notification for testing
  Future<void> showTestNotification() async {
    if (!_initialized) {
      await initialize();
    }

    debugPrint('🧪 Showing test notification...');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Test notification',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: 9999,
      title: 'Test Notification',
      body: 'This is a test notification from MediRemind!',
      notificationDetails: notificationDetails,
    );

    debugPrint('✅ Test notification shown');
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('👆 Notification tapped: ${response.payload}');
    // Handle navigation here
  }

  // Generate unique notification ID - DETERMINISTIC
  int _generateNotificationId(String reminderId, String time) {
    // Normalize the time string to ensure consistency
    final normalizedTime = _normalizeTime(time);

    // Create a stable string
    final key = '$reminderId|$normalizedTime';

    // Use a simpler deterministic hash (Dart's hashCode is NOT stable across runs!)
    int hash = 0;
    for (int i = 0; i < key.length; i++) {
      hash = (hash * 31 + key.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  // Normalize time to HH:mm format
  String _normalizeTime(String time) {
    // If already HH:mm, return as-is
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(time)) {
      final parts = time.split(':');
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return time;
  }

  // Build notification body
  String _buildNotificationBody(ReminderModel reminder) {
    String body = 'Time to ${reminder.name}';

    if (reminder.type == ReminderType.medication) {
      if (reminder.dosage != null && reminder.dosage!.isNotEmpty) {
        body += ' - ${reminder.dosage}';
      }
    }

    if (reminder.notes != null && reminder.notes!.isNotEmpty) {
      body += '\n${reminder.notes}';
    }

    return body;
  }

  // Get next valid date based on frequency
  tz.TZDateTime _getNextValidDate(ReminderModel reminder, tz.TZDateTime date) {
    switch (reminder.frequency) {
      case ReminderFrequency.daily:
        return date;

      case ReminderFrequency.specificDays:
        int attempts = 0;
        while (attempts < 7) {
          if (reminder.daysOfWeek!.contains(date.weekday)) {
            return date;
          }
          date = date.add(const Duration(days: 1));
          attempts++;
        }
        return date;

      case ReminderFrequency.customInterval:
        return date;

      default:
        return date;
    }
  }

  // Get pending notifications count
  Future<int> getPendingNotificationCount() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    return pending.length;
  }

  // Notify caregiver about missed dose
  Future<void> notifyCaregiverMissedDose({
    required String patientName,
    required String reminderName,
    required String scheduledTime,
    required String dosage,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    debugPrint(
      '📢 Notifying caregiver: $patientName missed $reminderName at $scheduledTime',
    );

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'missed_dose_alerts',
          'Missed Dose Alerts',
          channelDescription: 'Alerts for missed doses',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(''),
          color: Colors.red,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    await _notificationsPlugin.show(
      id: notificationId,
      title: '⚠️ Missed Dose: $patientName',
      body:
          '$patientName missed $reminderName ($dosage) scheduled for $scheduledTime',
      notificationDetails: notificationDetails,
      payload: 'missed_dose',
    );

    debugPrint('✅ Caregiver notification sent');
  }
}
