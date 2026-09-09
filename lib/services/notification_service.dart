import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/reminder_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    try {
      final TimezoneInfo currentTimeZone =
          await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
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

    // FIX: `settings` is a positional param, not named.
    await _notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _initialized = true;
  }

  // Create notification channels
  Future<void> _createNotificationChannels() async {
    // Channel for medication reminders
    final AndroidNotificationChannel medicationChannel =
        AndroidNotificationChannel(
          'medication_reminders',
          'Medication Reminders',
          description: 'Notifications for medication reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 500, 500]),
        );

    // Channel for habit reminders
    const AndroidNotificationChannel habitChannel = AndroidNotificationChannel(
      'habit_reminders',
      'Habit Reminders',
      description: 'Notifications for habit reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Channel for missed dose alerts
    const AndroidNotificationChannel missedDoseChannel =
        AndroidNotificationChannel(
          'missed_dose_alerts',
          'Missed Dose Alerts',
          description: 'Alerts for missed doses',
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
    await androidImplementation?.createNotificationChannel(missedDoseChannel);
  }

  // Request permissions
  Future<bool> requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    // Android permission
    final bool? androidPermission = await androidImplementation
        ?.requestNotificationsPermission();

    // iOS permission
    final bool? iosPermission = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

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

    // Parse the time
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Calculate next occurrence
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Check frequency and adjust schedule
    scheduledDate = _getNextValidDate(reminder, scheduledDate);

    // Create notification details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          ongoing: false,
          autoCancel: false,
          fullScreenIntent: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Create unique notification ID
    final notificationId = _generateNotificationId(reminder.id, time);

    // FIX: id, title, body, scheduledDate, notificationDetails are all
    // positional params — only androidScheduleMode/payload/matchDateTimeComponents are named.
    await _notificationsPlugin.zonedSchedule(
      id: notificationId,
      title: reminder.type == ReminderType.medication
          ? '💊 Medication Reminder'
          : '🎯 Habit Reminder',
      body: _buildNotificationBody(reminder),
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: reminder.id,
      matchDateTimeComponents: _getMatchDateTimeComponents(reminder),
    );
  }

  // Schedule all notifications for a reminder
  Future<void> scheduleReminderNotifications(ReminderModel reminder) async {
    for (String time in reminder.times) {
      await scheduleReminderNotification(reminder: reminder, time: time);
    }
  }

  // Cancel notifications for a reminder
  Future<void> cancelReminderNotifications(String reminderId) async {
    final pendingNotifications = await _notificationsPlugin
        .pendingNotificationRequests();

    for (var notification in pendingNotifications) {
      if (notification.payload == reminderId) {
        await _notificationsPlugin.cancel(id: notification.id);
      }
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Show immediate notification (for testing or missed dose alert)
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'missed_dose_alerts',
          'Missed Dose Alerts',
          channelDescription: 'Alerts for missed doses',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
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

    // FIX: id, title, body, notificationDetails are positional; only payload is named.
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  // Snooze notification
  Future<void> snoozeNotification({
    required int notificationId,
    required String title,
    required String body,
    Duration snoozeDuration = const Duration(minutes: 10),
  }) async {
    final scheduledTime = tz.TZDateTime.now(tz.local).add(snoozeDuration);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Snoozed medication reminders',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
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

    // FIX: id, title, body, scheduledDate, notificationDetails are positional.
    await _notificationsPlugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'snoozed',
    );
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      // Navigate to reminder details or mark as done
      print('Notification tapped with payload: ${response.payload}');
    }
  }

  // Generate unique notification ID
  int _generateNotificationId(String reminderId, String time) {
    final hash = '$reminderId$time'.hashCode;
    return hash.abs() % 100000; // Keep within reasonable range
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
        // Find next matching day
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
        // For simplicity, schedule for the next occurrence
        return date;

      default:
        return date;
    }
  }

  // Get match date time components for recurring notifications
  DateTimeComponents? _getMatchDateTimeComponents(ReminderModel reminder) {
    switch (reminder.frequency) {
      case ReminderFrequency.daily:
        return DateTimeComponents.time;

      case ReminderFrequency.specificDays:
        return DateTimeComponents.dayOfWeekAndTime;

      case ReminderFrequency.customInterval:
        return null; // Custom interval needs different handling

      default:
        return DateTimeComponents.time;
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      return await androidImplementation.areNotificationsEnabled() ?? false;
    }

    return true;
  }
}
