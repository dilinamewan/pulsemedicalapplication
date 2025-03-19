import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse/models/medication.dart';
import 'package:pulse/services/notification_service.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  
  // Get current user ID
  String get _userId => _auth.currentUser?.uid ?? '';
  
  // Get collection reference
  CollectionReference get _medicationsCollection => 
      _firestore.collection('medications');
  
  // Stream of medications for current user
  Stream<List<Medication>> getMedicationsStream() {
    return _medicationsCollection
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Medication.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }
  
  // Get medications for any user (returns Future instead of Stream)
  Future<List<Medication>> getUserMedications([String? userId]) async {
    try {
      final String targetUserId = userId ?? _userId;
      final querySnapshot = await _medicationsCollection
          .where('userId', isEqualTo: targetUserId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Medication.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load medications: $e');
    }
  }
  
  // Add new medication
  Future<void> addMedication(Medication medication) async {
    await _medicationsCollection.doc(medication.id).set(medication.toMap());
      
    // Schedule notifications for each reminder time
    for (int i = 0; i < medication.reminderTimes.length; i++) {
      await _notificationService.scheduleNotification(
        medication.id,
        i,
        medication.name,
        medication.category,
        medication.reminderTimes[i],
      );
    }
  }
  
  // Update medication
  Future<void> updateMedication(Medication medication) async {
    await _medicationsCollection.doc(medication.id).update(medication.toMap());
      
    // Cancel existing notifications and reschedule
    await _notificationService.cancelNotifications(medication.id);
      
    // Schedule new notifications
    for (int i = 0; i < medication.reminderTimes.length; i++) {
      await _notificationService.scheduleNotification(
        medication.id,
        i,
        medication.name,
        medication.category,
        medication.reminderTimes[i],
      );
    }
  }
  
  // Delete medication
  Future<void> deleteMedication(String medicationId) async {
    try {
      await _medicationsCollection.doc(medicationId).delete();
      
      // Cancel notifications
      await _notificationService.cancelNotifications(medicationId);
    } catch (e) {
      throw Exception('Failed to delete medication: $e');
    }
  }
  
  // Update taken status
  Future<void> updateTakenStatus(String medicationId, int reminderIndex, bool taken) async {
    DocumentSnapshot doc = await _medicationsCollection.doc(medicationId).get();
    Medication medication = Medication.fromMap(doc.data() as Map<String, dynamic>);
      
    List<bool> updatedStatus = List.from(medication.takenStatus);
    updatedStatus[reminderIndex] = taken;
      
    Medication updatedMedication = medication.copyWith(takenStatus: updatedStatus);
    await _medicationsCollection.doc(medicationId).update(updatedMedication.toMap());
  }
}