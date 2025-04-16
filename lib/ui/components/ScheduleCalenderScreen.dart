import 'package:flutter/material.dart';
import 'package:pulse/models/Schedules.dart';

import '../ScheduleFormScreen.dart';

class ScheduleCalenderScreen extends StatefulWidget {
  final String date;
  final VoidCallback? onScheduleUpdated; // Callback parameter

  const ScheduleCalenderScreen({
    super.key,
    required this.date,
    this.onScheduleUpdated,
  });

  @override
  ScheduleCalenderScreenState createState() => ScheduleCalenderScreenState();
}

class ScheduleCalenderScreenState extends State<ScheduleCalenderScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  List<Schedule> _schedules = [];
  bool _isLoading = false;

  void refreshSchedules() {
    _fetchSchedules();
  }

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
    List<Schedule> schedules = await _scheduleService.getSchedule(widget.date);

    // Only update state if the widget is still mounted
    if (mounted) {
      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _schedules.isEmpty
        ? const Center(
        child: Text(
          "No schedules found",
          style: TextStyle(color: Colors.white),
        ))
        : ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white10, // Dark gray background for list items
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            // Replace the InkWell.onTap callback with this updated version
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScheduleFormScreen(
                    scheduleId: schedule.scheduleId,
                    scheduleDate: DateTime.parse(schedule.date),
                  ),
                ),
              ).then((_) {
                // Always refresh when returning from the form screen
                print("Returned from ScheduleFormScreen, refreshing data...");
                _fetchSchedules();
                if (widget.onScheduleUpdated != null) {
                  widget.onScheduleUpdated!();
                }
              });
            },
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                schedule.title,
                                style: TextStyle(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red),
                              alignment: Alignment.centerRight,
                              onPressed: () {
                                _scheduleService.deleteSchedule(schedule.scheduleId).then((_) {
                                  refreshSchedules();
                                  if (widget.onScheduleUpdated != null) {
                                    widget.onScheduleUpdated!();
                                  }
                                });
                              },
                            ),
                          ],
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