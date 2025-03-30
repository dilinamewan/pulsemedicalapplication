import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:pulse/UI/AddHMUI.dart';
import 'package:pulse/UI/MedicationHomeScreen.dart';
import 'package:pulse/UI/add_medication_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pulse/ui/components/ScheduleCalenderScreen.dart';
import 'package:pulse/ui/ScheduleFormScreen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void fabClick(int index) {
    if (_selectedDay.microsecondsSinceEpoch < DateTime.now().microsecondsSinceEpoch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot add schedule for past dates"),
        ),
      );
    } else {
      if (index == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleFormScreen(
              scheduleDate: _selectedDay,
            ),
          ),
        );
      } else if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddMedicationScreen(),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddHMUI(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Calendar section
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

            // Tab bar section
            Container(
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: "Clinic Schedules"),
                  Tab(text: "Medication Reminders"),
                ],
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(width: 2.0, color: Colors.white),
                  insets: EdgeInsets.symmetric(horizontal: 16.0),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.label,
              ),
            ),
            SizedBox(height: 5,),
            // Tab content with fixed height
            SizedBox(
              height: 500,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Schedule tab
                  ScheduleCalenderScreen(
                    date: DateFormat('yyyy-MM-dd').format(_selectedDay),
                  ),
                  MedicationHomeScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}