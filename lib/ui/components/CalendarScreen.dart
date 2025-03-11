import 'package:intl/intl.dart'; 
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pulse/ui/components/ScheduleCalenderScreen.dart';
import 'package:pulse/ui/ScheduleFormScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pulse/Globals.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();



  void _onScheduleSelected(String scheduleId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleFormScreen(
          scheduleId: scheduleId,
          scheduleDate: _selectedDay,
        ),
      ),
    );
  }

  void fabClick() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleFormScreen(scheduleDate: _selectedDay),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Sets the background to black
      child: Column(
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
              formatButtonVisible: false,
              titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(fontSize: 16, color: Colors.white),
              weekendTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              outsideTextStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              todayDecoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.grey[600],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 4),
              ),
              cellMargin: const EdgeInsets.all(5),
              cellPadding: const EdgeInsets.symmetric(vertical: 10),
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: ScheduleCalenderScreen(

              onScheduleSelected: _onScheduleSelected,
              date: DateFormat('yyyy-MM-dd').format(_selectedDay),
            ),
          ),
        ],
      ),
    );
  }
}
