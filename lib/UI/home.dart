import 'package:flutter/material.dart';
import 'package:pulse/UI/components/dashboard.dart';
import 'package:pulse/ui/components/AppBarWidget.dart';
import 'package:pulse/ui/components/CalendarScreen.dart';
import 'components/chatUi.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.grey[900],
  appBarTheme: AppBarTheme(
    color: Colors.grey[900],
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.blue[300]!),
    ),
    labelStyle: TextStyle(color: Colors.grey[400]),
    iconColor: Colors.grey[400],
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
);

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
      CalendarScreen(key: _calendarKey),
      DashboardPage(),
      ChatPage()
    ];

    return Theme(
        data: darkTheme,
        child:Scaffold(
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
         selectedItemColor: Colors.white, // White selected item
        unselectedItemColor: Colors.grey[500], // Gray unselected items
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
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
    ));
  }
}