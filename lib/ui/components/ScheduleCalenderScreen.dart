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

  // Format time string from "hour:minute" to "hour:minute AM/PM"
  String formatTimeString(String timeStr) {
    // Split the time string into hours and minutes
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr; // Return original if format is unexpected

    try {
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);

      // Determine AM/PM
      String period = hours >= 12 ? 'PM' : 'AM';

      // Convert to 12-hour format
      hours = hours % 12;
      if (hours == 0) hours = 12; // 0 hour is 12 in 12-hour format

      // Format with padding for minutes
      return '$hours:${minutes.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeStr; // Return original if parsing fails
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
          margin: const EdgeInsets.only(bottom: 8), // Reduced bottom margin
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
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
                  height: 60, // Reduced height from 80 to 60
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // Reduced vertical padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Use minimum space vertically
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                schedule.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14, // Slightly smaller font size
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), // Slightly smaller icon
                                padding: EdgeInsets.zero, // Remove padding around the icon
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 2), // Reduced spacing
                        Text(
                          "${formatTimeString(schedule.startTime)} - ${formatTimeString(schedule.endTime)}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11, // Reduced font size
                          ),
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