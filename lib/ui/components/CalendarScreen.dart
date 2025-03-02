import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:pulse/ui/components/ScheduleScreen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  final String userId = "ir4cVfO1ASPuTiHpMammsQLnU8t2";

  void _onScheduleSelected(String scheduleId) {}

  void fabClick() {
    print(_selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
          },
          headerVisible: true,
          focusedDay: _selectedDay,
          firstDay: DateTime.utc(2000, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          daysOfWeekVisible: false,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
            });
          },
          headerStyle: const HeaderStyle(
            titleCentered: true,
          ),
          calendarStyle: CalendarStyle(
  defaultTextStyle: const TextStyle(fontSize: 12),
  weekendTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
  outsideTextStyle: const TextStyle(fontSize: 10, color: Colors.grey),
  todayDecoration: BoxDecoration(
    color: Colors.orange,
    shape: BoxShape.circle, 
    
  ),
  selectedDecoration: BoxDecoration(
    color: Colors.blue,
    shape: BoxShape.circle,
    
  ),
  cellMargin: const EdgeInsets.all(5),
  cellPadding: const EdgeInsets.symmetric(vertical: 10),
),

        ),
        Flexible(
          fit: FlexFit.loose,
          child: ScheduleScreen(
            userId: userId,
            onScheduleSelected: _onScheduleSelected,
            date: DateFormat('yyyy-MM-dd').format(_selectedDay),
          ),
        ),
      ],
    );
  }
}
