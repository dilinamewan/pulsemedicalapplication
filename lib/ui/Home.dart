import 'package:flutter/material.dart';
import 'package:pulse/ui/components/AppBarWidget.dart';
import 'package:pulse/ui/components/CalendarScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<CalendarScreenState> _calendarKey = GlobalKey<CalendarScreenState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      Center(child: Text("Home Screen")),
      CalendarScreen(key: _calendarKey), 
      Center(child: Text("Profile Screen")),
    ];

    return Scaffold(
      appBar: AppBarWidget(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        iconSize: 17,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                _calendarKey.currentState?.fabClick(); 
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
