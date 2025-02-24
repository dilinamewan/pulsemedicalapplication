import 'package:flutter/material.dart';
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
      body: Column(
        children: [
          // Expanded(
          //   // child: CalendarScreen(),
          // ),
          Expanded(
            flex: 2,
            child: ScheduleScreen(userId: userId, onScheduleSelected: _onScheduleSelected),
          ),
          if (selectedScheduleId != null)
            Expanded(
              //flex: 2,
              child: NoteScreen(userId: userId, scheduleId: selectedScheduleId!, onNoteSelected: _onNoteSelected),
            ),
          if (selectedNoteId != null)
            Expanded(
              //flex: 3,
              child: DocumentScreen(userId: userId, scheduleId: selectedScheduleId!, noteId: selectedNoteId!),
            ),
        ],
      ),
    );
  }
}
