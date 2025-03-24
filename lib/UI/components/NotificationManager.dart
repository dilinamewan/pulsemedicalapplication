import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:pulse/models/Schedules.dart';
import 'package:workmanager/workmanager.dart';
import 'package:intl/intl.dart';

class PushNotificationService {
  final ScheduleService _scheduleService = ScheduleService();

  static void initialize() {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'schedule_alerts',
          channelName: 'Schedule Alerts',
          channelDescription: 'Notifications for scheduled events',
          defaultColor: Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          ledColor: Colors.white,
        )
      ],
      debug: true,
    );

    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true for debugging
    );

    // Register periodic background task
    Workmanager().registerPeriodicTask(
      "check_schedules",
      "fetchFirestoreSchedules",
      frequency: Duration(minutes: 15),
    );

    // Register one-time background task
    Workmanager().registerOneOffTask(
      "check_schedules_once",
      "fetchFirestoreSchedulesOnce",
    );
  }

  Future<void> checkSchedulesForTomorrow() async {
    List<Schedule> schedules =
    await _scheduleService.getSchedule(DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: 1))));

    if (schedules.isNotEmpty) {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000), // Unique ID
          channelKey: 'schedule_alerts',
          title: 'You have ${schedules.length} schedules for tomorrow',
          body: 'Tap to view details.',
          notificationLayout: NotificationLayout.Default,
        ),
      );
    }
  }

  Future<void> scheduleAlerts() async {
    List<Schedule> schedules =
    await _scheduleService.getSchedule(DateFormat('yyyy-MM-dd').format(DateTime.now()));

    if (schedules.isNotEmpty) {
      for (Schedule schedule in schedules) {
        DateTime now = DateTime.now();

        // Convert "HH:mm" to DateTime today
        DateTime scheduleTime = DateFormat("HH:mm").parse(schedule.startTime);
        scheduleTime = DateTime(now.year, now.month, now.day, scheduleTime.hour, scheduleTime.minute);

        int minutesDiff = scheduleTime.difference(now).inMinutes;

        if (schedule.alert == "5h" && (minutesDiff >= 300 && minutesDiff < 315)) {
          _showNotification(schedule, "Your schedule is starting in 5 hours");
        } else if (schedule.alert == "1h" && (minutesDiff >= 60 && minutesDiff < 75)) {
          _showNotification(schedule, "Your schedule is starting in 1 hour");
        } else if (schedule.alert == "10m" && (minutesDiff >= 10 && minutesDiff < 25)) {
          _showNotification(schedule, "Your schedule is starting in 10 minutes");
        }
      }
    }
  }

  void _showNotification(Schedule schedule, String message) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: schedule.scheduleId.hashCode, // Unique ID based on schedule ID
        channelKey: 'schedule_alerts',
        title: schedule.title,
        body: message,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    PushNotificationService notificationService = PushNotificationService();
    await notificationService.checkSchedulesForTomorrow();
    await notificationService.scheduleAlerts();
    return Future.value(true);
  });
}
