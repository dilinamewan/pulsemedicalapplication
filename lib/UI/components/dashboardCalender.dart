import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PillStyleWeekCalendar extends StatefulWidget {
  const PillStyleWeekCalendar({super.key});

  @override
  State<PillStyleWeekCalendar> createState() => _PillStyleWeekCalendarState();
}

class _PillStyleWeekCalendarState extends State<PillStyleWeekCalendar> {
  List<DateTime> weekDays = [];
  DateTime today = DateTime.now();
  Map<String, List<Color>> dateIndicators = {};

  @override
  void initState() {
    super.initState();
    _generateWeekDays();
    _loadWeekSchedules();
  }

  void _generateWeekDays() {
    // Find Monday of the current week
    final monday = today.subtract(Duration(days: today.weekday - 1));

    // If today is Sunday (weekday == 7), it subtracts 6, which makes the week start from Monday
    if (today.weekday == 7) {
      weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    } else {
      weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    }

    // Debugging: Print the generated week days
    print('Generated Week Days:');
    weekDays.forEach((date) {
      print(date.toString());
    });
  }

  Future<void> _loadWeekSchedules() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in.');
      return;
    }

    final firestore = FirebaseFirestore.instance;

    DateTime start = weekDays.first;
    DateTime end = weekDays.last;

    // Set start time to 00:00:00.000000 (midnight)
    start = DateTime(start.year, start.month, start.day, 0, 0, 0, 0, 0);

    // Set end time to 23:59:59.999999 (just before midnight)
    end = DateTime(end.year, end.month, end.day, 23, 59, 59, 999, 999);

    // Debugging: Print the start and end dates
    print('Start: $start, End: $end');

    QuerySnapshot schedules = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('schedules')
        .get();

    // Debugging: Print the fetched schedule data
    print('Fetched Schedules: ${schedules.docs.length} documents');

    Map<String, List<Color>> tempIndicators = {};

    for (var doc in schedules.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Debugging: Print the schedule data being processed
      print('Processing schedule data: $data');

      if (!data.containsKey('date') || !data.containsKey('color')) continue;

      try {
        final scheduleDate = DateTime.parse(data['date']);
        print('Checking schedule for date: $scheduleDate'); // Debugging line

        if (scheduleDate.isBefore(start) || scheduleDate.isAfter(end)) {
          print('Skipping date: $scheduleDate'); // Debugging line
          continue;
        }

        final key = "${scheduleDate.year}-${scheduleDate.month}-${scheduleDate.day}";
        final colorValue = int.parse(data['color'].replaceFirst('#', '0xFF'));
        final color = Color(colorValue);

        if (!tempIndicators.containsKey(key)) {
          tempIndicators[key] = [];
        }

        if (tempIndicators[key]!.length < 3) {
          tempIndicators[key]!.add(color);
        }
      } catch (e) {
        print("Error processing schedule: $e");
      }
    }

    setState(() {
      dateIndicators = tempIndicators;
    });

    // Debugging: Print the final dateIndicators
    print('Date Indicators: $dateIndicators');
  }



  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: weekDays.map((date) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildDayPill(date),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDayPill(DateTime day) {
    bool isToday = _isSameDay(day, today);
    String key = "${day.year}-${day.month}-${day.day}";
    List<Color> indicators = dateIndicators[key] ?? [];

    return Container(
      width: 35,
      height: 75,
      decoration: BoxDecoration(
        color: isToday ? Colors.white70 : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            day.day.toString(),
            style: TextStyle(
              color: isToday ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          ...indicators.map((color) => Container(
            margin: const EdgeInsets.symmetric(vertical: 1),
            width: 20,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          )),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
