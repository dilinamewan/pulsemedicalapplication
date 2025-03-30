import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    _loadSchedules();
    _tabController = TabController(length: 2, vsync: this);
  }

  Map<int, List<Color>> dateIndicators = {};

  Future<void> _loadSchedules() async {
    await getWeekdaySchedules();
    setState(() {}); // Trigger UI update after fetching data
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

  Widget _buildDayCell(DateTime day, {bool isSelected = false, bool isToday = false}) {
    // Get the indicators for this day, limited to at most 3
    final indicators = dateIndicators.containsKey(day.day)
        ? dateIndicators[day.day]!.take(3).toList()
        : <Color>[];

    return Container(
      width: 28,
      height: 42, // Further reduced height
      margin: EdgeInsets.symmetric(horizontal: 0.5, vertical: 1), // Reduced margins
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important - use minimum space needed
        children: [
          SizedBox(height: 4), // Smaller top padding
          Text(
            day.day.toString(),
            style: TextStyle(
              color: isSelected ? Colors.black : (isToday ? Colors.blue : Colors.white),
              fontSize: 13, // Slightly smaller text
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2), // Minimal spacing
          // Create a fixed size container for indicators
          Container(
            height: 12, // Fixed height for all indicators
            width: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: indicators.map((color) => Container(
                margin: EdgeInsets.symmetric(vertical: 0.5),
                width: 16,
                height: 2.5, // Even smaller indicators
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) => _buildDayCell(day),
              selectedBuilder: (context, day, focusedDay) => _buildDayCell(day, isSelected: true),
              todayBuilder: (context, day, focusedDay) => _buildDayCell(day, isToday: true),
            ),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            rowHeight: 50, // Reduced row height
          ),
          SizedBox(height: 5),
          // Tab bar section
          TabBar(
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
          SizedBox(height: 5),
          // Tab content with expanded height
          Expanded(
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
    );
  }
}