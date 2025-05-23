import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse/models/Medication.dart';
import 'package:pulse/services/notification_service.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  
  // Get current user ID
  String get _userId => _auth.currentUser?.uid ?? '';
  
  // Get collection reference
  CollectionReference get _medicationsCollection =>
      _firestore.collection('users').doc(_userId).collection('medications');

  // Stream of medications for current user
  Stream<List<Medication>> getMedicationsStream() {
    return _medicationsCollection
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Medication.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get medications for any user (returns Future instead of Stream)
  Future<List<Medication>> getUserMedications() async {
    try {
      final querySnapshot = await _medicationsCollection.get();
      return querySnapshot.docs
          .map((doc) => Medication.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load medications: $e');
    }
  }

// Modify the addMedication method in MedicationService
  Future<void> addMedication(Medication medication) async {
    await _medicationsCollection.doc(medication.id).set(medication.toMap());

    // Only schedule notifications if the medication is still active
    if (medication.isActive()) {
      // Schedule notifications for each reminder time
      for (int i = 0; i < medication.reminderTimes.length; i++) {
        await _notificationService.scheduleMedicationNotification(
          medication.id,
          i,
          medication.name,
          medication.category,
          medication.reminderTimes[i],
          medication.endDate,
        );
      }
    }
  }

// Modify the updateMedication method in MedicationService
  Future<void> updateMedication(Medication medication) async {
    await _medicationsCollection.doc(medication.id).update(medication.toMap());

    // Cancel existing notifications
    await _notificationService.cancelMedicationNotifications(medication.id);

    // Only schedule new notifications if the medication is still active
    if (medication.isActive()) {
      // Schedule new notifications
      for (int i = 0; i < medication.reminderTimes.length; i++) {
        await _notificationService.scheduleMedicationNotification(
          medication.id,
          i,
          medication.name,
          medication.category,
          medication.reminderTimes[i],
          medication.endDate,
        );
      }
    }
  }
  
  // Delete medication
  Future<void> deleteMedication(String medicationId) async {
    try {
      await _medicationsCollection.doc(medicationId).delete();
      
      // Cancel notifications
      await _notificationService.cancelMedicationNotifications(medicationId);
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