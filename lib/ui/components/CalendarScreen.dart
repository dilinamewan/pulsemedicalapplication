import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pulse/UI/AddHMUI.dart';
import 'package:pulse/UI/components/MedicationHomeScreen.dart';
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
  DateTime _focusedDay = DateTime.now();
  late TabController _tabController;

  // Key to force ScheduleCalenderScreen rebuild
  final GlobalKey<ScheduleCalenderScreenState> _scheduleScreenKey = GlobalKey();
  final GlobalKey<MedicationHomeScreenState> _medicationScreenKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadSchedules();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Changed from Map<int, List<Color>> to Map<DateTime, List<Color>> to store full dates
  Map<DateTime, List<Color>> dateIndicators = {};

  Future<void> _loadSchedules() async {
    await getMonthSchedules(_focusedDay);
    if (mounted) {
      setState(() {}); // Ensure we only call setState if widget is still mounted
    }
  }

  // This method will refresh both the calendar and the schedule list
  void refreshCalendarData() {
    _loadSchedules(); // Refresh calendar indicators

    // Refresh the ScheduleCalenderScreen if it's created
    if (_scheduleScreenKey.currentState != null) {
      _scheduleScreenKey.currentState!.refreshSchedules();
    }
  }

  // Updated to fetch schedules for a specific month
  Future<void> getMonthSchedules(DateTime month) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in.');
      return;
    }

    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Get the first and last day of the month
    DateTime firstDayOfMonth = DateTime(month.year, month.month, 1);
    DateTime lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    QuerySnapshot schedules = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('schedules')
        .get();

    Map<DateTime, List<Color>> tempIndicators = {};

    for (var doc in schedules.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (!data.containsKey('date') || !data.containsKey('color')) continue;

      try {
        DateTime scheduleDate = DateTime.parse(data['date']);

        // Check if the schedule date is within the current month
        if (scheduleDate.isBefore(firstDayOfMonth) || scheduleDate.isAfter(lastDayOfMonth)) continue;

        // Create a DateTime with year, month, day (no time) for cleaner comparison
        DateTime dateKey = DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day);

        int colorValue = int.parse(data['color']);
        Color color = Color(colorValue);

        // Limit to 3 indicators per day
        if (!tempIndicators.containsKey(dateKey)) {
          tempIndicators[dateKey] = [];
        }

        if (tempIndicators[dateKey]!.length < 3) {
          tempIndicators[dateKey]!.add(color);
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
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime selectedDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

    bool isPastDate = selectedDate.isBefore(today);
    bool isFutureDate = selectedDate.isAfter(today);

    if (isPastDate && index < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot add schedule or medication for past dates"),
        ),
      );
    } else if (isFutureDate && index == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("HMUI can only be added for today or past dates"),
        ),
      );
    } else {
      Widget page;
      if (index == 0) {
        page = ScheduleFormScreen(scheduleDate: _selectedDay);
      } else if (index == 1) {
        page = AddMedicationScreen(scheduleDate: _selectedDay);
      } else {
        page = AddHMUI(scheduleDate: _selectedDay);
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      ).then((result) {
        // Check if a change was made (result == true)
        if (result == true) {
          // This will now refresh both the calendar and schedule list
          refreshCalendarData();
        }
      });
    }
  }

  Widget _buildDayCell(DateTime day, {bool isSelected = false, bool isToday = false}) {
    // Create a clean DateTime for the current day (no time) for proper comparison
    DateTime dateKey = DateTime(day.year, day.month, day.day);

    // Get the indicators for this specific date
    final indicators = dateIndicators.containsKey(dateKey)
        ? dateIndicators[dateKey]!.take(3).toList()
        : <Color>[];

    return Container(
      width: 48,
      height: 63,

      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15),
        border: isSelected ? Border.all(color: Colors.white.withOpacity(0.8), width: 1): Border.all(color: Colors.black.withOpacity(0.5), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important - use minimum space needed
        children: [
          SizedBox(height: 4),
          // Smaller top padding
          Container(
            decoration: BoxDecoration(
              color: isToday? Colors.white: (isSelected? Colors.transparent : Colors.black),
              borderRadius: BorderRadius.circular(5),
            ),

            padding: EdgeInsets.symmetric(horizontal: 7),

            child: Text(
                day.day.toString(),
                style: TextStyle(

                  color: isToday? Colors.black : Colors.white,
                  fontSize: 13, // Slightly smaller text
                  fontWeight: FontWeight.bold,
                )),
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
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: TableCalendar(
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                    },
                    headerVisible: true,
                    focusedDay: _focusedDay,
                    firstDay: DateTime.utc(2000, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    daysOfWeekVisible: false,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                      getMonthSchedules(focusedDay);
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
                    rowHeight: 65,
                    // Reduced row height
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
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
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              ScheduleCalenderScreen(
                key: _scheduleScreenKey,
                date: DateFormat('yyyy-MM-dd').format(_selectedDay),
                onScheduleUpdated: refreshCalendarData,
              ),
              MedicationHomeScreen(
                key: _medicationScreenKey,
                date:_selectedDay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom delegate to make the TabBar sticky
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Match the background color
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}