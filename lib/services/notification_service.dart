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
      "resource://drawable/icon",
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
          playSound: true,
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
          playSound: true,
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
      DateTime? endDate,
      ) async {
    final int notificationId = medicationId.hashCode + reminderIndex;

    String? endDateString = endDate?.toIso8601String();

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: _medicationChannelKey,
          title: 'Time to take $medicationName',
          body: 'Category: $category',
          payload: {
            'medicationId': medicationId,
            'endDate': endDateString ?? '',
          },
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
    } catch (e) {
      print("Error scheduling notification: $e");
      rethrow;
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

    // Daily check for tomorrow's schedules - runs at 8 PM every day
    final now = DateTime.now();
    final checkTomorrowTime = DateTime(now.year, now.month, now.day, 20, 0);
    final tomorrowTriggerTime = now.isAfter(checkTomorrowTime)
        ? checkTomorrowTime.add(Duration(days: 1))
        : checkTomorrowTime;

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
        hour: tomorrowTriggerTime.hour,
        minute: tomorrowTriggerTime.minute,
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

    // NEW: Check today's schedules at 6:00 AM
    final today6am = DateTime(now.year, now.month, now.day, 6, 0);
    final sixAMTriggerTime = now.isAfter(today6am)
        ? today6am.add(Duration(days: 1))
        : today6am;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 100003,
        channelKey: _scheduleChannelKey,
        title: 'Check Today Schedules',
        body: 'This is a system notification to trigger schedule checks at 6AM',
        displayOnForeground: false,
        displayOnBackground: false,
      ),
      schedule: NotificationCalendar(
        hour: sixAMTriggerTime.hour,
        minute: sixAMTriggerTime.minute,
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
  void setupNotificationActionListeners() {
    // The correct way to listen for notification actions
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction receivedAction) async {
        // Handle notification actions
        if (receivedAction.channelKey == _medicationChannelKey) {
          final medicationId = receivedAction.payload?['medicationId'];
          final endDateString = receivedAction.payload?['endDate'];

          if (medicationId != null && endDateString?.isNotEmpty == true) {
            final endDate = DateTime.parse(endDateString!);
            final today = DateTime.now();

            // Compare dates without time components
            final normalizedEndDate = DateTime(endDate.year, endDate.month, endDate.day);
            final normalizedToday = DateTime(today.year, today.month, today.day);

            if (normalizedEndDate.isBefore(normalizedToday)) {
              // Cancel all notifications for this medication
              await cancelMedicationNotifications(medicationId);
              return;
            }
          }
        } else if (receivedAction.channelKey == _scheduleChannelKey) {


        }
      },
    );
  }
}