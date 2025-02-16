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
  });

  final String scheduleId;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String location;
  final String alert;
}

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Schedule>> getSchedule(String userId, String date) async {
    List<Schedule> schedules = [];

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users') // Go to users collection
          .doc(userId) // Select the specific user document
          .collection('schedules') // Access their schedules subcollection
          .where('date', isEqualTo: date) // Filter by date
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
              location: data['location'] ?? 'No Location',
              alert: data['alert_frequency'] ?? 'No Alert',
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
    }

    return schedules;
  }
}
