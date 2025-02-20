import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
  });

  final String scheduleId;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final GeoPoint location;
  final String alert;
  final String color;
}

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch schedules for a specific user and date
  Future<List<Schedule>> getSchedule(String userId, String date) async {
    List<Schedule> schedules = [];

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
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
                  : const GeoPoint(0.0, 0.0), // Ensure valid GeoPoint
              alert: data['alert_frequency'] ?? 'No Alert',
              color: data['color'] ?? '#FF000000',
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
    }

    return schedules;
  }

  /// Add a new schedule
  Future<void> addSchedule(
      String userId, String title, String date, String startTime, String endTime, GeoPoint location, String alert, String color) async {
    try {
      await _firestore.collection('users').doc(userId).collection('schedules').add({
        'title': title,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'location': location,
        'alert_frequency': alert,
        'color': color,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Schedule added successfully');
    } catch (e) {
      debugPrint('Error adding schedule: $e');
    }
  }

  /// Update an existing schedule
  Future<void> updateSchedule(
      String userId, String scheduleId, String title, String date, String startTime, String endTime, GeoPoint location, String alert, String color) async {
    try {
      await _firestore.collection('users').doc(userId).collection('schedules').doc(scheduleId).update({
        'title': title,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'location': location,
        'alert_frequency': alert,
        'color': color,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Schedule updated successfully');
    } catch (e) {
      debugPrint('Error updating schedule: $e');
    }
  }

  /// Delete a schedule
  Future<void> deleteSchedule(String userId, String scheduleId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('schedules').doc(scheduleId).delete();

      debugPrint('Schedule deleted successfully');
    } catch (e) {
      debugPrint('Error deleting schedule: $e');
    }
  }
}
