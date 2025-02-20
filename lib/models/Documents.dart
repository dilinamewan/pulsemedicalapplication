import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';

class Document {
  Document({
    required this.documentId,
    required this.name,
    required this.url,
  });

  final String documentId;
  final String name;
  final String url;
}

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Fetch all documents for a specific note
  Future<List<Document>> getDocuments(String userId, String scheduleId, String noteId) async {
    List<Document> documents = [];

    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId)
          .collection('notes')
          .doc(noteId)
          .collection('docs')
          .get();

      documents = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Document(
          documentId: doc.id,
          name: data['name'] ?? 'No name',
          url: data['url'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Error fetching documents: $e');
    }

    return documents;
  }

  /// Upload document to Firebase Storage and save URL in Firestore
  Future<void> uploadDocument(String userId, String scheduleId, String noteId, File file) async {
    try {
      String fileName = basename(file.path); // Extract file name
      String storagePath = 'users/$userId/schedules/$scheduleId/notes/$noteId/docs/$fileName';

      // Upload file to Firebase Storage
      UploadTask uploadTask = _storage.ref(storagePath).putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();

      // Save document details in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId)
          .collection('notes')
          .doc(noteId)
          .collection('docs')
          .add({
        'name': fileName,
        'url': downloadURL,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Document uploaded and saved successfully');
    } catch (e) {
      print('Error uploading document: $e');
    }
  }

  /// Update an existing document
  Future<void> updateDocument(String userId, String scheduleId, String noteId, String documentId, String newName) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId)
          .collection('notes')
          .doc(noteId)
          .collection('docs')
          .doc(documentId)
          .update({
        'name': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Document updated successfully');
    } catch (e) {
      print('Error updating document: $e');
    }
  }

  /// Delete document from Firebase Storage and Firestore
  Future<void> deleteDocument(String userId, String scheduleId, String noteId, String documentId, String fileUrl) async {
    try {
      // Delete from Firebase Storage
      Reference storageRef = _storage.refFromURL(fileUrl);
      await storageRef.delete();

      // Delete from Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId)
          .collection('notes')
          .doc(noteId)
          .collection('docs')
          .doc(documentId)
          .delete();

      print('Document deleted successfully');
    } catch (e) {
      print('Error deleting document: $e');
    }
  }
}
