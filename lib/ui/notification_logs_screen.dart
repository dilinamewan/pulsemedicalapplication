import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:pulse/services/notification_service.dart';
import 'package:intl/intl.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: AppBarTheme(
    color: Colors.transparent,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.blue[300]!),
    ),
    labelStyle: TextStyle(color: Colors.grey[400]),
    iconColor: Colors.grey[400],
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
);

class NotificationLogsScreen extends StatefulWidget {
  const NotificationLogsScreen({super.key});

  @override
  State<NotificationLogsScreen> createState() => _NotificationLogsScreenState();
}

class _NotificationLogsScreenState extends State<NotificationLogsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await AwesomeNotifications().listScheduledNotifications();
      
      // Debug: Print notification details
      for (var notification in notifications) {
        print('Notification ID: ${notification.content?.id}');
        print('Title: ${notification.content?.title}');
        print('Schedule: ${notification.schedule?.toString()}');
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: darkTheme,
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Notification Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.add_alert),
            onPressed: () {
              _notificationService.sendTestNotification();
              Future.delayed(const Duration(seconds: 1), _loadNotifications);
            },
            tooltip: 'Send test notification',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No scheduled notifications'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationItem(notification);
                  },
                ),
    ));
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final medicationId = notification.content?.payload?['medicationId'] ?? 'Unknown';
    
    // Extract date from schedule string if available
    String scheduleInfo = 'Schedule information not available';
    if (notification.schedule != null) {
      final scheduleStr = notification.schedule.toString();
      scheduleInfo = 'Raw schedule: $scheduleStr';
      
      // Try to extract date with regex if it contains a date pattern
      try {
        RegExp dateRegex = RegExp(r'(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})');
        final match = dateRegex.firstMatch(scheduleStr);
        
        if (match != null && match.groupCount >= 5) {
          final year = int.parse(match.group(1)!);
          final month = int.parse(match.group(2)!);
          final day = int.parse(match.group(3)!);
          final hour = int.parse(match.group(4)!);
          final minute = int.parse(match.group(5)!);
          
          final dateTime = DateTime(year, month, day, hour, minute);
          final dateFormat = DateFormat('MMM d, yyyy');
          final timeFormat = DateFormat('h:mm a');
          
          scheduleInfo = 'Scheduled for: ${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
        }
      } catch (e) {
        print('Error extracting date from string: $e');
      }
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(notification.content?.title ?? 'No title'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.content?.body ?? 'No body'),
            Text(
              scheduleInfo,
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Medication ID: $medicationId',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              'Notification ID: ${notification.content?.id}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.notifications, color: Colors.white),
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            await AwesomeNotifications().cancel(notification.content?.id ?? 0);
            _loadNotifications();
          },
          tooltip: 'Cancel notification',
        ),
      ),
    );
  }
}