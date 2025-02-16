import 'package:cloud_firestore/cloud_firestore.dart';

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

class NoteServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Note>> getNotes(String scheduleId, String userId) async {
    List<Note> notes = [];

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users') // Access users collection
          .doc(userId) // Select the user
          .collection('schedules') // Access schedules subcollection
          .doc(scheduleId) // Select the specific schedule
          .collection('notes') // Get notes from this schedule
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
      rethrow; // Allows the error to be handled by the calling function
    }

    return notes;
  }
}
