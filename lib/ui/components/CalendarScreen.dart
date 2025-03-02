import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pulse/ui/components/ScheduleScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      appBar: AppBar(title: const Text("Calendar")),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _selectedDay,
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(child: _buildScheduleList()), // Fetch and display schedules
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleScreen(
                userId: "user_id_here",  // Replace with actual user ID
                onScheduleSelected: (schedule) {},
                date: formattedDate,
              ),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildScheduleList() {
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);
    
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('schedules')
          .where('date', isEqualTo: formattedDate)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No schedules for this date."));
        }

        var schedules = snapshot.data!.docs;
        return ListView.builder(
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            var schedule = schedules[index];
            return ListTile(
              title: Text(schedule['title']),
              subtitle: Text(schedule['description']),
            );
          },
        );
      },
    );
  }
}
