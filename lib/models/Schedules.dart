import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Schedule {
  Schedule({
    required this.scheduleId,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.alert,
    required this.color,
    required this.notes,
    required this.documents,
  });

  final String scheduleId;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final GeoPoint location;
  final String alert;
  final String color;
  Map<String, dynamic> notes = {};
  List<String> documents = [];
}

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch schedules for a specific user and date
  Future<List<Schedule>> getSchedule(String date) async {
    List<Schedule> schedules = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? UserId = prefs.getString('user_id');

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(UserId)
          .collection('schedules')
          .where('date', isEqualTo: date)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data != null) {
          schedules.add(
            Schedule(
              scheduleId: doc.id,
              title: data['title'] ?? 'No Title',
              date: data['date'] ?? 'Unknown Date',
              startTime: data['start_time'] ?? '00:00',
              endTime: data['end_time'] ?? '00:00',
              location: data['location'] is GeoPoint
                  ? data['location'] as GeoPoint
                  : const GeoPoint(0.0, 0.0),
              alert: data['alert_frequency'] ?? 'No Alert',
              color: data['color'] ?? '#FF000000',
              notes: data['note'] ?? {},
              documents: data['docs'] != null
                  ? List<String>.from(data['docs'])
                  : [],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
    }

    return schedules;
  }

  Future<bool> checkForOverlap(
      String date,
      String startTime,
      String endTime,
      [String? excludeScheduleId]
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    try {
      // Get all schedules for the specified date
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .where('date', isEqualTo: date)
          .get();

      // Parse the new start and end times
      final newStartParts = startTime.split(':');
      final newEndParts = endTime.split(':');

      final newStartMinutes = int.parse(newStartParts[0]) * 60 + int.parse(newStartParts[1]);
      final newEndMinutes = int.parse(newEndParts[0]) * 60 + int.parse(newEndParts[1]);

      // Check for overlap with each existing schedule
      for (var doc in querySnapshot.docs) {
        // Skip the current schedule if we're updating
        if (excludeScheduleId != null && doc.id == excludeScheduleId) {
          continue;
        }

        final data = doc.data() as Map<String, dynamic>;

        // Parse existing schedule's start and end time
        final existingStartParts = (data['start_time'] as String).split(':');
        final existingEndParts = (data['end_time'] as String).split(':');

        final existingStartMinutes =
            int.parse(existingStartParts[0]) * 60 + int.parse(existingStartParts[1]);
        final existingEndMinutes =
            int.parse(existingEndParts[0]) * 60 + int.parse(existingEndParts[1]);

        // Check if schedules overlap
        // Overlap occurs when:
        // new start is before existing end AND new end is after existing start
        if (newStartMinutes < existingEndMinutes && newEndMinutes > existingStartMinutes) {
          return true; // Overlap detected
        }
      }

      return false; // No overlap
    } catch (e) {
      debugPrint('Error checking for schedule overlap: $e');
      throw e; // Rethrow to handle in the UI
    }
  }

  /// Add a new schedule
  Future<String?> addSchedule(
      String title,
      String date,
      String startTime,
      String endTime,
      GeoPoint location,
      String alert,
      String color,
      Map notes,
      List docs,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    // Generate your own UUID
    String customId = const Uuid().v4();

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(customId) // Use your own ID here
          .set({
        'id': customId, // Store the ID if you want to refer to it later
        'title': title,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'location': location,
        'alert_frequency': alert,
        'color': color,
        'note': notes,
        'docs': docs,
      });
      return customId;
      debugPrint('Schedule added successfully with custom ID: $customId');
    } catch (e) {
      debugPrint('Error adding schedule: $e');
    }
  }

  /// Update an existing schedule
  Future<void> updateSchedule(
       String scheduleId, String title, String date, String startTime, String endTime, GeoPoint location, String alert, String color, Map notes, List docs) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? UserId = prefs.getString('user_id');
    try {
      await _firestore.collection('users').doc(UserId).collection('schedules').doc(scheduleId).update({
        'title': title,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'location': location,
        'alert_frequency': alert,
        'color': color,
        'note': notes,
        'docs': docs,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Schedule updated successfully');
    } catch (e) {
      debugPrint('Error updating schedule: $e');
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId == null) {
      debugPrint('User ID not found in SharedPreferences');
      return;
    }

    try {
      final userDocRef = _firestore.collection('users').doc(userId);
      await userDocRef.collection('schedules').doc(scheduleId).delete();
      debugPrint('Schedule deleted successfully');
      final docsSnapshot = await userDocRef.collection('documents').get();
      for (var doc in docsSnapshot.docs) {
        if (doc.id.endsWith('_$scheduleId')) {
          await doc.reference.delete();
          debugPrint('Deleted document: ${doc.id}');
        }
      }
    } catch (e) {
      debugPrint('Error deleting schedule and related documents: $e');
    }
  }


  /// Fetch all schedules for the current user
  Future<List<Schedule>> getAllSchedules() async {
    List<Schedule> schedules = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId == null) {
      debugPrint('User ID is null. Make sure it is saved in SharedPreferences.');
      return schedules;
    }

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data != null) {
          schedules.add(
            Schedule(
              scheduleId: doc.id,
              title: data['title'] ?? 'No Title',
              date: data['date'] ?? 'Unknown Date',
              startTime: data['start_time'] ?? '00:00',
              endTime: data['end_time'] ?? '00:00',
              location: data['location'] is GeoPoint
                  ? data['location'] as GeoPoint
                  : const GeoPoint(0.0, 0.0),
              alert: data['alert_frequency'] ?? 'No Alert',
              color: data['color'] ?? '#FF000000',
              notes: data['note'] ?? {},
              documents: data['docs'] != null
                  ? List<String>.from(data['docs'])
                  : [],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching all schedules: $e');
    }

    return schedules;
  }

}
