import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:pulse/models/Schedules.dart';
import 'package:intl/intl.dart';

class NotificationService {
  // Singleton implementation
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // Channel keys
  final String _medicationChannelKey = 'medication_channel';
  final String _scheduleChannelKey = 'schedule_alerts';

  // Schedule service
  final ScheduleService _scheduleService = ScheduleService();

  // Initialize notifications
  Future<void> initNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        // Medication channel
        NotificationChannel(
          channelKey: _medicationChannelKey,
          channelName: 'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          defaultColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Colors.blue,
        ),
        // Schedule channel
        NotificationChannel(
          channelKey: _scheduleChannelKey,
          channelName: 'Schedule Alerts',
          channelDescription: 'Notifications for scheduled events',
          defaultColor: Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          enableVibration: true,
          enableLights: true,
          ledColor: Colors.white,
        ),
      ],
      debug: true,
    );

    // Request permission
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      print("Notification permission status: $isAllowed");
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    // Setup periodic checking for upcoming schedules
    await _setupPeriodicScheduleChecks();
  }

  // MEDICATION NOTIFICATIONS

  // Schedule medication notification
  Future<void> scheduleMedicationNotification(
      String medicationId,
      int reminderIndex,
      String medicationName,
      String category,
      DateTime scheduledTime,
      ) async {
    // Generate notification ID
    final int notificationId = medicationId.hashCode + reminderIndex;

    print("Scheduling medication notification ID: $notificationId for $medicationName at ${scheduledTime.toString()}");

    try {
      bool success = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: _medicationChannelKey,
          title: 'Time to take $medicationName',
          body: 'Category: $category',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          payload: {'medicationId': medicationId},
        ),
        schedule: NotificationCalendar(
          hour: scheduledTime.hour,
          minute: scheduledTime.minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
      print("Medication notification scheduled successfully: $success");
    } catch (e) {
      print("Error scheduling medication notification: $e");
    }
  }

  // Cancel medication notifications
  Future<void> cancelMedicationNotifications(String medicationId) async {
    final int baseId = medicationId.hashCode;
    print("Cancelling notifications for medication ID: $medicationId");
    for (int i = 0; i < 10; i++) {
      await AwesomeNotifications().cancel(baseId + i);
    }
  }

  // SCHEDULE NOTIFICATIONS

  // Setup periodic checks for schedules
  Future<void> _setupPeriodicScheduleChecks() async {
    // Schedule initial checks
    await checkSchedulesForToday();
    await checkSchedulesForTomorrow();

    // We'll use the awesome_notifications scheduling instead of workmanager
    // Schedule daily check for tomorrow's schedules - runs at 8 PM every day
    final now = DateTime.now();
    final checkTime = DateTime(now.year, now.month, now.day, 20, 0);
    final checkTimeToUse = now.isAfter(checkTime)
        ? checkTime.add(Duration(days: 1))
        : checkTime;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 100001,
        channelKey: _scheduleChannelKey,
        title: 'Check Tomorrow Schedules',
        body: 'This is a system notification to trigger schedule checks',
        displayOnForeground: false,
        displayOnBackground: false,
      ),
      schedule: NotificationCalendar(
        hour: checkTimeToUse.hour,
        minute: checkTimeToUse.minute,
        second: 0,
        millisecond: 0,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'CHECK_TOMORROW_SCHEDULES',
          label: 'Check Schedules',
        )
      ],
    );

    // Setup hourly checks for today's schedule alerts
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 100002,
        channelKey: _scheduleChannelKey,
        title: 'Check Today Schedules',
        body: 'This is a system notification to trigger schedule checks',
        displayOnForeground: false,
        displayOnBackground: false,
      ),
      schedule: NotificationCalendar(
        minute: 0,  // Run at the top of every hour
        second: 0,
        millisecond: 0,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'CHECK_TODAY_SCHEDULES',
          label: 'Check Schedules',
        )
      ],
    );
  }

  // Check schedules for tomorrow
  Future<void> checkSchedulesForTomorrow() async {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    final tomorrowFormatted = DateFormat('yyyy-MM-dd').format(tomorrow);

    List<Schedule> schedules = await _scheduleService.getSchedule(tomorrowFormatted);

    if (schedules.isNotEmpty) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: _scheduleChannelKey,
          title: 'You have ${schedules.length} schedules for tomorrow',
          body: 'Tap to view details.',
          notificationLayout: NotificationLayout.Default,
        ),
      );
    }
  }

  // Check schedules for today and schedule alerts
  Future<void> checkSchedulesForToday() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    List<Schedule> schedules = await _scheduleService.getSchedule(today);

    if (schedules.isNotEmpty) {
      for (Schedule schedule in schedules) {
        await scheduleNotificationForEvent(schedule);
      }
    }
  }

  // Schedule notifications for a specific event
  Future<void> scheduleNotificationForEvent(Schedule schedule) async {
    DateTime now = DateTime.now();

    // Convert "HH:mm" to DateTime today
    DateTime scheduleTime = DateFormat("HH:mm").parse(schedule.startTime);
    DateTime scheduleDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        scheduleTime.hour,
        scheduleTime.minute
    );

    // Only schedule notifications for future times
    if (scheduleDateTime.isAfter(now)) {
      // Calculate times for different alert preferences
      DateTime fiveHoursBefore = scheduleDateTime.subtract(Duration(hours: 5));
      DateTime oneHourBefore = scheduleDateTime.subtract(Duration(hours: 1));
      DateTime tenMinutesBefore = scheduleDateTime.subtract(Duration(minutes: 10));

      // Schedule based on alert preference
      if (schedule.alert == "5h" && fiveHoursBefore.isAfter(now)) {
        await _createScheduleAlert(
            schedule,
            "Your schedule is starting in 5 hours",
            fiveHoursBefore,
            1
        );
      }

      if (schedule.alert == "1h" && oneHourBefore.isAfter(now)) {
        await _createScheduleAlert(
            schedule,
            "Your schedule is starting in 1 hour",
            oneHourBefore,
            2
        );
      }

      if (schedule.alert == "10m" && tenMinutesBefore.isAfter(now)) {
        await _createScheduleAlert(
            schedule,
            "Your schedule is starting in 10 minutes",
            tenMinutesBefore,
            3
        );
      }
    }
  }

  // Create a schedule alert notification
  Future<void> _createScheduleAlert(
      Schedule schedule,
      String message,
      DateTime notificationTime,
      int alertIndex
      ) async {
    // Generate a unique ID based on the schedule ID and alert type
    final int notificationId = schedule.scheduleId.hashCode + alertIndex;

    try {
      bool success = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: _scheduleChannelKey,
          title: schedule.title,
          body: message,
          notificationLayout: NotificationLayout.Default,
          payload: {'scheduleId': schedule.scheduleId},
        ),
        schedule: NotificationCalendar.fromDate(date: notificationTime),
      );
      print("Schedule alert notification scheduled successfully: $success");
    } catch (e) {
      print("Error scheduling alert notification: $e");
    }
  }

  // Cancel schedule notifications
  Future<void> cancelScheduleNotifications(String scheduleId) async {
    final int baseId = scheduleId.hashCode;
    print("Cancelling notifications for schedule ID: $scheduleId");
    // Cancel all possible alert types
    for (int i = 1; i <= 3; i++) {
      await AwesomeNotifications().cancel(baseId + i);
    }
  }

  // COMMON FUNCTIONS

  // Get all notification logs
  Future<List<NotificationModel>> getNotificationLogs() async {
    try {
      final List<NotificationModel> activeSchedules = await AwesomeNotifications().listScheduledNotifications();
      print("Active scheduled notifications: ${activeSchedules.length}");
      return activeSchedules;
    } catch (e) {
      print("Error getting notification logs: $e");
      return [];
    }
  }

  // Setup notification action listeners
  // Setup notification action listeners
  void setupNotificationActionListeners(Function(String) onNotificationPressed) {
    // The correct way to listen for notification actions
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction receivedAction) async {
        // Handle notification actions
        if (receivedAction.channelKey == _medicationChannelKey) {
          final medicationId = receivedAction.payload?['medicationId'];
          if (medicationId != null) {
            onNotificationPressed(medicationId);
          }
        } else if (receivedAction.channelKey == _scheduleChannelKey) {
          final scheduleId = receivedAction.payload?['scheduleId'];
          if (scheduleId != null) {
            onNotificationPressed(scheduleId);
          }
        } else if (receivedAction.buttonKeyPressed == 'CHECK_TOMORROW_SCHEDULES') {
          await checkSchedulesForTomorrow();
        } else if (receivedAction.buttonKeyPressed == 'CHECK_TODAY_SCHEDULES') {
          await checkSchedulesForToday();
        }
      },
    );
  }
}