import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pulse/UI/components/HMUI.dart';
import 'package:pulse/UI/components/NotificationLogsComponent.dart';
import 'package:pulse/UI/components/dashboardCalender.dart';

import '../allHMUI.dart';

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
            PillStyleWeekCalendar(),
            const SizedBox(height: 7),
            Text("Health Matrix"),
            const SizedBox(height: 7),
            HMUIScreen(),
            SizedBox(
              height: 32,
              width: 80, // Adjust width as needed
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HealthMetricsPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white24, width: 1),
                  ),
                  textStyle: TextStyle(fontSize: 12),
                ),
                child: Text(
                  'See More',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text("Upcoming Notification"),
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
