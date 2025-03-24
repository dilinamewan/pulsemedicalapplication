import 'package:flutter/material.dart';
import 'package:pulse/ui/components/AppBarWidget.dart';
import 'package:pulse/ui/components/CalendarScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;
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
        backgroundColor: Colors.black,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        iconSize: 17,
        selectedFontSize: 11,
        unselectedFontSize: 10,
         selectedItemColor: Colors.white, // White selected item
        unselectedItemColor: Colors.grey[500], // Gray unselected items
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
              backgroundColor: Colors.grey[800],
              shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}