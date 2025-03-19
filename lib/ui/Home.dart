import 'package:flutter/material.dart';
import 'package:pulse/ui/components/CalendarScreen.dart';
import 'package:pulse/screens/add_medication_screen.dart';
import 'package:pulse/screens/notification_logs_screen.dart'; // Import the NotificationLogsScreen
import 'package:pulse/models/medication.dart';
import 'package:pulse/widgets/medication_list_item.dart';
import 'package:pulse/services/medication_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<CalendarScreenState> _calendarKey =
      GlobalKey<CalendarScreenState>();

  final MedicationService _medicationService = MedicationService();
  List<Medication> medications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _error = "You need to be logged in to view medications";
        });
        return;
      }

      final medicationsList =
          await _medicationService.getUserMedications(userId);

      setState(() {
        medications = medicationsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Error loading medications: ${e.toString()}";
      });
    }
  }

  void _onTakenStatusChanged(
      Medication medication, int index, bool value) async {
    try {
      await _medicationService.updateTakenStatus(medication.id, index, value);

      setState(() {
        medication.takenStatus[index] = value;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status: ${e.toString()}")),
      );
    }
  }

  void _onDeleteMedication(Medication medication) async {
    try {
      await _medicationService.deleteMedication(medication.id);

      setState(() {
        medications.removeWhere((med) => med.id == medication.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Medication deleted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting medication: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeScreen(),
      CalendarScreen(key: _calendarKey),
      Center(child: Text("Profile Screen")),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Navigate to NotificationLogsScreen when the button is pressed
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationLogsScreen()),
              );
            },
          ),
        ],
      ),
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
        items: [
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
              child: Icon(Icons.add, color: Colors.white),
            )
          : _selectedIndex == 0
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddMedicationScreen()),
                    ).then((_) {
                      _loadMedications();
                    });
                  },
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.medical_services, color: Colors.white),
                )
              : null,
    );
  }

  Widget _buildHomeScreen() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMedications,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (medications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No medications added yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add your medications',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMedications,
      child: ListView.builder(
        itemCount: medications.length,
        itemBuilder: (context, index) {
          return MedicationListItem(
            medication: medications[index],
            onTakenStatusChanged: (timeIndex, value) =>
                _onTakenStatusChanged(medications[index], timeIndex, value),
            onDelete: () => _onDeleteMedication(medications[index]),
          );
        },
      ),
    );
  }
}
