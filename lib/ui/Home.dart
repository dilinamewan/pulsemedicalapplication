import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pulse/ui/components/NoteScreen.dart';
import 'package:pulse/ui/components/ScheduleScreen.dart';
import 'package:pulse/ui/components/DocumentScreen.dart';
import 'package:pulse/ui/components/CalendarScreen.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String userId = "ir4cVfO1ASPuTiHpMammsQLnU8t2"; // Replace with actual user ID
  String? selectedScheduleId;
  String? selectedNoteId;
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now()); // Default to today

  void _onScheduleSelected(String scheduleId) {
    setState(() {
      selectedScheduleId = scheduleId;
      selectedNoteId = null;
    });
  }

  void _onNoteSelected(String noteId) {
    setState(() {
      selectedNoteId = noteId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medical Calendar App")),
      body: 
      CalendarScreen(),
    );
  }
}
