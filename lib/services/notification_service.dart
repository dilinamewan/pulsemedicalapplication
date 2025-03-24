import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initNotifications() async {
    // Make sure this icon exists in your drawable folder
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'medication_channel',
          channelName: 'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          defaultColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
          // Add this for better Android 12+ compatibility
          ledColor: Colors.blue,
        ),
      ],
    );

    // Request permission and print result for debugging
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      print("Notification permission status: $isAllowed");
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> scheduleNotification(
    String medicationId,
    int reminderIndex,
    String medicationName,
    String category,
    DateTime scheduledTime,
  ) async {
    // Simpler ID generation to avoid parsing errors
    final int notificationId = medicationId.hashCode + reminderIndex;

    print(
        "Scheduling notification ID: $notificationId for $medicationName at ${scheduledTime.toString()}");

    try {
      bool success = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'medication_channel',
          title: 'Time to take $medicationName',
          body: 'Category: $category',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          // Add payload for handling notification taps
          payload: {'medicationId': medicationId},
        ),
        schedule: NotificationCalendar(
          hour: scheduledTime.hour,
          minute: scheduledTime.minute,
          second: 0,
          millisecond: 0,
          // For daily repeating notifications
          repeats: true,
          // Add this to ensure Android doesn't optimize it away
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
      print("Notification scheduled successfully: $success");
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  Future<void> cancelNotifications(String medicationId) async {
    final int baseId = medicationId.hashCode;
    print("Cancelling notifications for medication ID: $medicationId");

    for (int i = 0; i < 10; i++) {
      await AwesomeNotifications().cancel(baseId + i);
    }
  }

  Future<List<NotificationModel>> getNotificationLogs() async {
    try {
      final List<NotificationModel> activeSchedules =
          await AwesomeNotifications().listScheduledNotifications();
      print("Active scheduled notifications: ${activeSchedules.length}");
      return activeSchedules;
    } catch (e) {
      print("Error getting notification logs: $e");
      return [];
    }
  }

  // Add this method to check if notifications are working
  Future<void> sendTestNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 999,
        channelKey: 'medication_channel',
        title: 'Test Notification',
        body: 'This is a test notification',
        notificationLayout: NotificationLayout.Default,
      ),
    );
    print("Test notification sent");
  }
}
