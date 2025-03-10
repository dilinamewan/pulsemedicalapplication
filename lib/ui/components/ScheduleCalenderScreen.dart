import 'package:flutter/material.dart';
import 'package:pulse/models/Schedules.dart';

class ScheduleCalenderScreen extends StatefulWidget {
  final String userId;
  final Function(String) onScheduleSelected;
  final String date;

  const ScheduleCalenderScreen(
      {super.key,
      required this.userId,
      required this.onScheduleSelected,
      required this.date});

  @override
  _ScheduleCalenderScreenState createState() => _ScheduleCalenderScreenState();
}

class _ScheduleCalenderScreenState extends State<ScheduleCalenderScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  List<Schedule> _schedules = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }
  
  @override
  void didUpdateWidget(covariant ScheduleCalenderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _fetchSchedules();
    }
  }
  
  void _fetchSchedules() async {
    setState(() {
      _isLoading = true;
    });
    List<Schedule> schedules =
        await _scheduleService.getSchedule(widget.userId, widget.date);
    
    setState(() {
      _schedules = schedules;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return _schedules.isEmpty
        ? const Center(child: Text("No schedules found",style: TextStyle(color: Colors.white),))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _schedules.length,
            itemBuilder: (context, index) {
              final schedule = _schedules[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                 decoration: BoxDecoration(
                  color: Colors.grey[900], // Dark gray background for list items
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => widget.onScheduleSelected(schedule.scheduleId),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Color(int.parse(schedule.color)),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appointment Reminder: "${schedule.title}"',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}

