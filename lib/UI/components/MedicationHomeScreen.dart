import 'package:flutter/material.dart';
import 'package:pulse/UI/medication_details_screen.dart';
import 'package:pulse/models/Medication.dart';
import 'package:pulse/ui/components/medication_list_item.dart';
import 'package:pulse/services/medication_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicationHomeScreen extends StatefulWidget {
  final DateTime date;
  const MedicationHomeScreen({super.key, required this.date});

  void refreshMedications(BuildContext context) {
    final state = context.findAncestorStateOfType<MedicationHomeScreenState>();
    state?.loadMedications();
  }

  @override
  MedicationHomeScreenState createState() => MedicationHomeScreenState();
}

class MedicationHomeScreenState extends State<MedicationHomeScreen> {
  final MedicationService _medicationService = MedicationService();
  List<Medication> medications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadMedications();
  }

  @override
  void didUpdateWidget(MedicationHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(oldWidget.date, widget.date)) {
      loadMedications();
    }
  }


  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }


  void loadMedications() async {
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

      // Get all medications first
      final allMedicationsList = await _medicationService.getUserMedications();

      final filteredMedications = allMedicationsList.where((med) {
        final target = widget.date;

        final startsBeforeOrOn = med.startDate.isBefore(target) || isSameDay(med.startDate, target);
        final endsAfterOrOn = med.endDate == null || med.endDate!.isAfter(target) || isSameDay(med.endDate!, target);

        return startsBeforeOrOn && endsAfterOrOn;
      }).toList();


      setState(() {
        medications = filteredMedications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Error loading medications: ${e.toString()}";
      });
    }
  }

  void _navigateToMedicationDetails(Medication medication) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationDetailsScreen(medication: medication),
      ),
    );

    if (result == true) {
      // Refresh medications list if the result is true
      loadMedications();
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
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadMedications,
              child: const Text('Retry'),
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
            const SizedBox(height: 8),
            Text(
              'No medications reminders found',
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
      onRefresh: () async {
        loadMedications();
      },
      child: ListView.builder(
        itemCount: medications.length,
        itemBuilder: (context, index) {
          return MedicationListItem(
            medication: medications[index],
            onTakenStatusChanged: (timeIndex, value) =>
                _onTakenStatusChanged(medications[index], timeIndex, value),
            onDelete: () => _onDeleteMedication(medications[index]),
            onTap: () => _navigateToMedicationDetails(medications[index]),
          );
        },
      ),
    );
  }
}