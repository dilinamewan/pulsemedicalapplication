import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar with rowDecoration"),
      ),
      body: Column(

        children: [
          // Limit the calendar height in some way (e.g. 60% of screen height)
          SizedBox(
            child: TableCalendar(
              focusedDay: _selectedDay,
              firstDay: DateTime.utc(2000, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                });
                String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDay);
                debugPrint("Selected Date: $formattedDate");
              },
              // ----------------- CALENDAR STYLE -----------------
              // This is where rowDecoration is used
              calendarStyle: CalendarStyle(
                // rowDecoration modifies the background/border style
                // of each interior row in the calendar.

                // You can still configure other styles here:
                todayDecoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                // e.g., margin inside each cell
                cellMargin: const EdgeInsets.all(1),
                defaultTextStyle: const TextStyle(fontSize: 16),
                // ...
              ),
              // ----------------- CALENDAR BUILDERS -----------------
              // Use builders for more detailed cell styling.
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, focusedDay) {
                  bool isSelected = isSameDay(date, _selectedDay);
                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
