import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Note {
  Note({
    required this.noteId,
    required this.title,
    required this.content,
  });

  final String noteId;
  final String title;
  final String content;
}

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all notes for a specific schedule
  Future<List<Note>> getNotes(String scheduleId) async {
    List<Note> notes = [];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? UserId = prefs.getString('user_id');

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(UserId)
          .collection('schedules')
          .doc(scheduleId)
          .collection('notes')
          .get();

      notes = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;

        return Note(
          noteId: doc.id,
          title: data?['title'] ?? 'No Title',
          content: data?['content'] ?? 'No Content',
        );
      }).toList();
    } catch (e) {
      print('Error fetching notes: $e');
    }

    return notes;
  }

  /// Add a new note
  Future<void> addNote(String scheduleId, String userId, String title, String content) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId)
          .collection('notes')
          .add({
        'title': title,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(), // Track creation time
      });

      print('Note added successfully');
    } catch (e) {
      print('Error adding note: $e');
    }
  }

  /// Update an existing note
  Future<void> updateNote(String scheduleId, String userId, String noteId, String newTitle, String newContent) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId)
          .collection('notes')
          .doc(noteId)
          .update({
        'title': newTitle,
        'content': newContent,
        'updatedAt': FieldValue.serverTimestamp(), // Track update time
      });

      print('Note updated successfully');
    } catch (e) {
      print('Error updating note: $e');
    }
  }

  /// Delete a note
  Future<void> deleteNote(String scheduleId, String userId, String noteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .doc(scheduleId)
          .collection('notes')
          .doc(noteId)
          .delete();

      print('Note deleted successfully');
    } catch (e) {
      print('Error deleting note: $e');
    }
  }
}
