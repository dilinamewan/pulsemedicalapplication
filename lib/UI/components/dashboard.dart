import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pulse/UI/components/HMUI.dart';
import 'package:pulse/UI/components/NotificationLogsComponent.dart';
import 'package:pulse/UI/components/dashboardCalender.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('d\'th\' MMMM yyyy').format(DateTime.now());
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Welcome to',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Pulse',
              style: TextStyle(
                color: Color(0xFFFF6B6B), // Coral/Reddish pink color
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Today is $formattedDate',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 7),
            PillStyleTableCalendar(),
            const SizedBox(height: 7),
            Text("Health Matrix"),
            const SizedBox(height: 7),
            HMUIScreen(),
            const SizedBox(height: 7),
            Text("Recent Notification"),
            const SizedBox(height: 7),
            // Just include NotificationLogsComponent without Expanded
            const SizedBox(
              height: 300,  // Add height constraint to avoid size issue
              child: NotificationLogsComponent(),
            ),
          ],
        ),
      ),
    );
  }
}
