import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pulse/UI/NoteScreen.dart';
import 'package:pulse/ui/components/AppBarWidget.dart';
import 'package:pulse/models/Schedules.dart';
import 'package:url_launcher/url_launcher.dart';


class ScheduleFormScreen extends StatefulWidget {
  final DateTime scheduleDate;
  final String? scheduleId;

  const ScheduleFormScreen({
    super.key,
    required this.scheduleDate,
    this.scheduleId,
  });

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  bool isAllDay = false;
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();
  TextEditingController titleController = TextEditingController();
  String? alerts;
  GeoPoint? location;

  @override
  void initState() {
    super.initState();
    if (widget.scheduleId != null) {
      fetchScheduleDetails();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> fetchScheduleDetails() async {
    if (widget.scheduleId == null) return;

    try {
      // Format the date to match the format used in the database
      String formattedDate = "${widget.scheduleDate.year}-${widget.scheduleDate.month.toString().padLeft(2, '0')}-${widget.scheduleDate.day.toString().padLeft(2, '0')}";

      // Create an instance of ScheduleService
      ScheduleService scheduleService = ScheduleService();

      // Fetch all schedules for this date
      List<Schedule> schedules = await scheduleService.getSchedule(formattedDate);

      // Find the schedule with the matching ID
      Schedule? schedule = schedules.firstWhere(
            (s) => s.scheduleId == widget.scheduleId,

        orElse: () => throw Exception('Schedule not found'),
      );

      // Update the form fields with the schedule details
      setState(() {
        titleController.text = schedule.title;
        alerts = schedule.alert;
        location = schedule.location;

        // Parse the start time
        List<String> startParts = schedule.startTime.split(':');
        if (startParts.length == 2) {
          startTime = TimeOfDay(
              hour: int.parse(startParts[0]),
              minute: int.parse(startParts[1])
          );
        }

        // Parse the end time
        List<String> endParts = schedule.endTime.split(':');
        if (endParts.length == 2) {
          endTime = TimeOfDay(
              hour: int.parse(endParts[0]),
              minute: int.parse(endParts[1])
          );
        }

        // Determine if it's an all-day event (you might want to set some logic here)
        // For example, if start time is 00:00 and end time is 23:59
        isAllDay = (startTime.hour == 0 && startTime.minute == 0 &&
            endTime.hour == 23 && endTime.minute == 59);

        // Note: You would need to add controllers for note, alert, and location
        // if you want to populate those fields as well
      });
    } catch (e) {
      // Handle any errors that might occur during fetching
      debugPrint('Error fetching schedule details: $e');
      // You might want to show a snackbar or dialog to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load schedule details: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            Center(
              child: Text(
                widget.scheduleId == null ? "Add Schedule" : "Edit Schedule",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField('Title', Icons.circle, Colors.grey[800]!, titleController),
            const SizedBox(height: 20),
            _buildTimePickerCard(),
            const SizedBox(height: 20),
            _buildOptionNav('Note', Icons.sticky_note_2),
            _buildOptionTileAlert('Alert', Icons.notifications),
            _buildOptionTile('Location', Icons.location_on),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, Color color, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          icon: Icon(icon, color: Colors.blueAccent),
        ),
      ),
    );
  }
  Widget _buildOptionNav(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        // Navigate to the NoteScreen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoteScreen(
            scheduleId: widget.scheduleId.toString(),

          )),
        );
      },
      child: _buildOptionTile(title, icon),
    );
  }
  Widget _buildTimePickerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('All Day', style: TextStyle(color: Colors.white)),
              Switch(
                value: isAllDay,
                onChanged: (value) {
                  setState(() {
                    isAllDay = value;
                  });
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn('Start Time', startTime, (newTime) {
                setState(() {
                  startTime = newTime;
                });
              }),
              _buildTimeColumn('End Time', endTime, (newTime) {
                setState(() {
                  endTime = newTime;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, TimeOfDay time, Function(TimeOfDay) onTimeSelected) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () async {
            TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) {
              onTimeSelected(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time.format(context),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile(String title, IconData icon) {

    return
      GestureDetector(
        onTap: () {

          if (title == 'Location') {
            openGoogleMaps();
          }

    },child: Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        ],
      ),
      ),
    );
  }
  Widget _buildOptionTileAlert(String title, IconData icon) {
    return GestureDetector(
      onTap: () {

          _showAlertOverlay();

      },
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  void _showAlertOverlay() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Set Alert Time",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildRadioTile(setState, "10 minutes before", "10m"),
                  _buildRadioTile(setState, "1 hour before", "1h"),
                  _buildRadioTile(setState, "1 day before", "1d"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Done"),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Default alert selection


  Widget _buildRadioTile(StateSetter setState, String label, String value) {
    return RadioListTile<String>(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: value,
      groupValue: alerts,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            alerts = newValue;
          });
        }
      },
      activeColor: Colors.blue,
    );
  }

  void openGoogleMaps() async {
    if (location == null) return;
    final double lat = location!.latitude;
    final double lng = location!.longitude;
    final String googleMapsUrl = "geo:$lat,$lng?q=$lat,$lng";
    final String webUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    } else if (await canLaunchUrl(Uri.parse(webUrl))) {
      await launchUrl(Uri.parse(webUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Maps")),
      );
    }
  }
}