import 'package:flutter/material.dart';
import 'package:pulse/models/Medication.dart';
import 'package:pulse/services/medication_service.dart';
import 'package:intl/intl.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: AppBarTheme(
    color: Colors.transparent,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.blue[300]!),
    ),
    labelStyle: TextStyle(color: Colors.grey[400]),
    iconColor: Colors.grey[400],
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
);


class MedicationDetailsScreen extends StatefulWidget {
  final Medication medication;

  const MedicationDetailsScreen({super.key, required this.medication});

  @override
  _MedicationDetailsScreenState createState() =>
      _MedicationDetailsScreenState();
}

class _MedicationDetailsScreenState extends State<MedicationDetailsScreen> {
  final MedicationService _medicationService = MedicationService();
  bool isUpdating = false; // Flag to show/hide spinner

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: darkTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.medication.name),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(context),
              const SizedBox(height: 16),
              _buildRemindersList(context),
              const SizedBox(height: 16),
              if (widget.medication.notes != null) _buildNotesSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.medication.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.category, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Category: ${widget.medication.category}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.date_range_sharp, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Start Date: ${DateFormat('yyyy-MM-dd').format(widget.medication.startDate)}",
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Frequency: ${widget.medication.frequency} times per day',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.date_range_sharp, size: 20),
                const SizedBox(width: 8),
                Text(
                  "End Date: ${widget.medication.endDate == null ? "N/A" : DateFormat('yyyy-MM-dd').format(widget.medication.endDate!)}",
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersList(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reminders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.medication.reminderTimes.length,
              itemBuilder: (context, index) {
                final time = widget.medication.reminderTimes[index];
                bool isTaken = widget.medication.takenStatus[index];

                return ListTile(
                  leading: Icon(
                    isTaken ? Icons.check_circle : Icons.schedule,
                    color: isTaken ? Colors.green : Colors.blue,
                  ),
                  title: Text(timeFormat.format(time)),
                  subtitle: Text(isTaken ? 'Taken' : 'Not taken'),
                  trailing: isUpdating
                      ? const CircularProgressIndicator() // Show loading spinner
                      : Switch(
                    value: isTaken,
                    onChanged: (value) async {
                      setState(() {
                        isUpdating = true; // Show the spinner
                        widget.medication.takenStatus[index] = value; // Update the local state immediately
                      });

                      await _medicationService.updateTakenStatus(
                        widget.medication.id,
                        index,
                        value,
                      );

                      setState(() {
                        isUpdating = false; // Hide the spinner
                      });
                      Navigator.pop(context, true);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.medication.notes ?? '',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
