import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      mainAxisAlignment: MainAxisAlignment.center,
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
      ],
    )));
  }
}
