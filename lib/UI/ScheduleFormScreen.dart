import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pulse/UI/NoteScreen.dart';
import 'package:pulse/ui/components/AppBarWidget.dart';
import 'package:pulse/models/Schedules.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulse/models/Hospitals.dart';


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
  List<dynamic> hospitalData = [];
  Map<String, dynamic> notes = {};
  List<String> docs = [];
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
  Future<void> fetchHospitals() async {
    try {
      // Create an instance of HospitalService
      HospitalService hospitalService = HospitalService();

      // Fetch all hospitals
      List<Hospital> hospitals = await hospitalService.getHospitals();

      setState(() {
        hospitalData = hospitals;
      });
    } catch (e) {
      debugPrint('Error fetching hospital details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load hospital details: $e'))
      );
    }
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
      TimeOfDay parseTimeOfDay(String timeString) {
        // Convert "12:01:PM" format to a standard "12:01 PM" format
        timeString = timeString.replaceAll(":", " ").replaceFirst(" ", ":");

        final format = RegExp(r'(\d+):(\d+)\s?(AM|PM)');

        final match = format.firstMatch(timeString);
        if (match != null) {
          int hour = int.parse(match.group(1)!);
          int minute = int.parse(match.group(2)!);
          String period = match.group(3)!;

          // Convert 12-hour format to 24-hour format
          if (period == "PM" && hour != 12) {
            hour += 12;
          } else if (period == "AM" && hour == 12) {
            hour = 0;
          }

          return TimeOfDay(hour: hour, minute: minute);
        } else {
          throw FormatException("Invalid time format");
        }
      }

// Parsing startTime and endTime
      try {
        startTime = parseTimeOfDay(schedule.startTime);
        endTime = parseTimeOfDay(schedule.endTime);

        // Determine if it's an all-day event (00:00 - 23:59)
        isAllDay = (startTime.hour == 0 && startTime.minute == 0 &&
            endTime.hour == 23 && endTime.minute == 59);
      } catch (e) {
        debugPrint('Error parsing time: $e');
      }

      // Update the form fields with the schedule details
      setState(() {
        titleController.text = schedule.title;
        alerts = schedule.alert;
        location = schedule.location;
        notes = schedule.notes;
        docs = schedule.documents;

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


        isAllDay = (startTime.hour == 0 && startTime.minute == 0 &&
            endTime.hour == 23 && endTime.minute == 59);

        // Note: You would need to add controllers for note, alert, and location
        // if you want to populate those fields as well
      });
    } catch (e) {
      // Handle any errors that might occur during fetching
      debugPrint('Error fetching schedule details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load schedule details: $e'))
      );
    }
  }
  Future<void> addSchedule() async {
    String title = titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    String formattedDate = "${widget.scheduleDate.year}-${widget.scheduleDate.month.toString().padLeft(2, '0')}-${widget.scheduleDate.day.toString().padLeft(2, '0')}";

    ScheduleService scheduleService = ScheduleService();

    await scheduleService.addSchedule(
      title,
      formattedDate,
      "${startTime.hour}:${startTime.minute}",
      "${endTime.hour}:${endTime.minute}",
      location!,
      alerts ?? 'No Alert',
      '0xFFFF0000',
      notes,
      docs,
    );

    // Show a snackbar to inform the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule added successfully')),
    );

    // Navigate back to the previous screen
    Navigator.pop(context);
  }

  Future<void> updateSchedule() async {
    // Get the title from the text field
    String title = titleController.text.trim();

    // Validate the title
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    // Format the date to match the format used in the database
    String formattedDate = "${widget.scheduleDate.year}-${widget.scheduleDate.month.toString().padLeft(2, '0')}-${widget.scheduleDate.day.toString().padLeft(2, '0')}";

    // Create an instance of ScheduleService
    ScheduleService scheduleService = ScheduleService();

    // Update the schedule in the database
    await scheduleService.updateSchedule(
      widget.scheduleId!,
      title,
      formattedDate,
      "${startTime.hour}:${startTime.minute}",
      "${endTime.hour}:${endTime.minute}",
      location!,
      alerts ?? 'No Alert',
      '0xFFFF0000',
      notes,
      docs,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule updated successfully')),
    );

    Navigator.pop(context);
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
            _buildOptionNote('Note', Icons.sticky_note_2),
            _buildOptionTileAlert('Alert', Icons.notifications),
            _buildOptionTileLocation('Location', Icons.location_on),
            const Spacer(), // Pushes buttons to the bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Closes the screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // Cancel button color
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (widget.scheduleId == null) {
                      addSchedule();
                    } else {
                      blockPastDates();
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // Save button color
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text("Save", style: TextStyle(color: Colors.white)),

                ),
              ],
            ),
            const SizedBox(height: 20), // Space at the bottom
          ],
        ),
      ),
    );
  }
  void blockPastDates() {
    if (widget.scheduleDate.microsecondsSinceEpoch < DateTime.now().microsecondsSinceEpoch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot add schedule for past dates"),
        ),
      );
    } else {
      updateSchedule();
    }
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
  Widget _buildOptionNote(String title, IconData icon) {
    return GestureDetector(
      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteScreen(
              title: notes['title'] ?? '',
              content: notes['content'] ?? '',
              docs: docs,
              scheduleId: widget.scheduleId.toString(),
              onSave: (newTitle, newContent, newDocs) {
                setState(() {
                  notes['title'] = newTitle;
                  notes['content'] = newContent;
                  docs = newDocs!;
                });
              },
            ),
          ),
        );

      },
      child: _buildOptionTile(title, icon),
    );
  }
  Widget _buildOptionTile(String title, IconData icon) {

    return
      GestureDetector(
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

  Widget _buildOptionTileLocation(String title, IconData icon) {

    return
      GestureDetector(
        onTap: () {


            if(widget.scheduleId == null) {
              fetchHospitals();
              _showHospitalOverlay();
            } else {

            _showViewUpdateOverlay();
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
  void _showViewUpdateOverlay() {
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
                    "View or Update",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // View Option (Opens Google Maps)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Close overlay
                      openGoogleMaps(); // Open Google Maps
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map, color: Colors.blueAccent),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text("View Location", style: TextStyle(color: Colors.white)),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),

                  // Update Option (Opens Hospital Selection)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Close overlay
                      fetchHospitals(); // Fetch hospitals before showing overlay
                      _showHospitalOverlay(); // Open hospital selection overlay
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: Row(
                        children: [
                          const Icon(Icons.local_hospital, color: Colors.redAccent),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text("Update Location", style: TextStyle(color: Colors.white)),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
  void _showHospitalOverlay() {
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
                    "Select Hospital",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: hospitalData.length,
                      itemBuilder: (context, index) {
                        var hospital = hospitalData[index];
                        return ListTile(
                          title: Text(hospital.name, style: const TextStyle(color: Colors.white)),
                          onTap: () {
                            setState(() {
                              location = hospital.location;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
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
