import 'package:flutter/material.dart';
import 'package:pulse/models/Schedules.dart';

class ScheduleScreen extends StatefulWidget {
  final String userId;
  final Function(String) onScheduleSelected;
  final String date = "2024-02-01";

  const ScheduleScreen({Key? key, required this.userId, required this.onScheduleSelected}) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  List<Schedule> _schedules = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  void _fetchSchedules() async {
    List<Schedule> schedules = await _scheduleService.getSchedule(widget.userId, widget.date);
    setState(() {
      _schedules = schedules;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(_schedules[index].title),
          titleTextStyle : TextStyle(
            color: Color(int.parse(_schedules[index].color)),
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),

          onTap: () => widget.onScheduleSelected(_schedules[index].scheduleId),
        );
      },
    );
  }
}
