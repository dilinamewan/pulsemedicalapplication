import 'package:flutter/material.dart';
import 'package:pulse/ui//components/AppBarWidget.dart';
import 'package:pulse/ui/components/CalendarScreen.dart';
import 'package:pulse/ui/MedicationHomeScreen.dart';
import 'package:pulse/ui/add_medication_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<CalendarScreenState> _calendarKey =
      GlobalKey<CalendarScreenState>();
  // Use a GlobalKey of State instead of the private state class
  final GlobalKey<State<MedicationHomeScreen>> _medicationScreenKey =
      GlobalKey();

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      MedicationHomeScreen(key: _medicationScreenKey),
      CalendarScreen(key: _calendarKey),
      const Center(child: Text("Profile Screen")),
    ];

    return Scaffold(
      appBar: const AppBarWidget(),
      body: screens[_selectedIndex],
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
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[500],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Calendar'),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : _selectedIndex == 0
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddMedicationScreen()),
                    ).then((_) {
                      // Use the proper way to access the component's refresh method
                      (_medicationScreenKey.currentWidget
                              as MedicationHomeScreen)
                          .refreshMedications(context);
                    });
                  },
                  backgroundColor: Colors.blue,
                  child:
                      const Icon(Icons.medical_services, color: Colors.white),
                )
              : null,
    );
  }
}
