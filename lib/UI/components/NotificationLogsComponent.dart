import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

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

class NotificationLogsComponent extends StatefulWidget {
  const NotificationLogsComponent({super.key});

  @override
  State<NotificationLogsComponent> createState() => _NotificationLogsComponentState();
}

class _NotificationLogsComponentState extends State<NotificationLogsComponent> {
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _notifications.isEmpty
        ? const Center(child: Text('No scheduled notifications'))
        : ListView.builder(
      itemCount: _notifications.take(4).length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    String scheduleInfo = 'No schedule info';

    if (notification.schedule is NotificationCalendar) {
      final schedule = notification.schedule as NotificationCalendar;
      final hour = schedule.hour ?? 0;
      final minute = schedule.minute ?? 0;

      final time = TimeOfDay(hour: hour, minute: minute);
      scheduleInfo = 'Scheduled for: ${time.format(context)}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4, // Adds subtle shadow to the card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners for a more modern look
      ),
      child: ListTile(
        title: Text(
          notification.content?.title ?? 'No title',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4), // Small space between body text and schedule info
            Text(
              scheduleInfo,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic, // To differentiate schedule info
              ),
            ),
          ],
        ),

      ),
    );
  }
}
