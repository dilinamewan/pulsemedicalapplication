import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PillStyleTableCalendar extends StatefulWidget {
  const PillStyleTableCalendar({super.key});

  @override
  _PillStyleTableCalendarState createState() => _PillStyleTableCalendarState();
}

class _PillStyleTableCalendarState extends State<PillStyleTableCalendar> {
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();
  CalendarFormat calendarFormat = CalendarFormat.week;
  Map<int, List<Color>> dateIndicators = {};

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    await getWeekdaySchedules();
    if (mounted) {
      setState(() {}); // Ensure we only call setState if widget is still mounted
    }
  }

  void refreshCalendarData() {
    _loadSchedules();
  }

  Future<void> getWeekdaySchedules() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in.');
      return;
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday-1));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

    QuerySnapshot schedules = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('schedules')
        .get();

    Map<int, List<Color>> tempIndicators = {};

    for (var doc in schedules.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (!data.containsKey('date') || !data.containsKey('color')) continue;

      try {
        DateTime scheduleDate = DateTime.parse(data['date']);
        if (scheduleDate.isBefore(startOfWeek) || scheduleDate.isAfter(endOfWeek)) continue;

        int dayOfMonth = scheduleDate.day;
        int colorValue = int.parse(data['color'].replaceFirst('#', '0xFF'));
        Color color = Color(colorValue);

        // Limit to 3 indicators per day
        if (!tempIndicators.containsKey(dayOfMonth)) {
          tempIndicators[dayOfMonth] = [];
        }

        if (tempIndicators[dayOfMonth]!.length < 3) {
          tempIndicators[dayOfMonth]!.add(color);
        }
      } catch (e) {
        print("Error processing schedule: $e");
      }
    }

    setState(() {
      dateIndicators = tempIndicators;
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday-1));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: focusedDate,
            calendarFormat: CalendarFormat.week,
            daysOfWeekVisible: false,
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) => _buildDayCell(day),
              selectedBuilder: (context, day, focusedDay) => _buildDayCell(day, isSelected: true),
              todayBuilder: (context, day, focusedDay) => _buildDayCell(day, isToday: true),
            ),
            calendarStyle: CalendarStyle(outsideDaysVisible: false),
            headerVisible: false,
            selectedDayPredicate: (day) => isSameDay(selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                selectedDate = selectedDay;
                focusedDate = focusedDay;
              });
            },
            rowHeight: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, {bool isSelected = false, bool isToday = false}) {

    return Container(
      width: 30,
      height: 80,
      margin: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 12),
          Text(
            day.day.toString(),
            style: TextStyle(
              color: isSelected ? Colors.black : (isToday ? Colors.blue : Colors.white),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          if (dateIndicators.containsKey(day.day))
            ...dateIndicators[day.day]!.map((color) => Container(
              margin: EdgeInsets.symmetric(vertical: 1),
              width: 20,
              height: 4,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            )),
        ],
      ),
    );
  }
}
